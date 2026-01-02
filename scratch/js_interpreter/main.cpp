#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <map>
#include <cctype>
#include <stdexcept>
#include <algorithm>

// Utils
std::string read_file(const std::string& path) {
    std::ifstream t(path);
    if (!t.is_open()) throw std::runtime_error("Cannot open file: " + path);
    std::stringstream buffer;
    buffer << t.rdbuf();
    return buffer.str();
}

// Lexer
enum TokenType {
    TOK_FUNCTION, TOK_RETURN, TOK_EXPORT, TOK_VAR, TOK_LET, TOK_IF, TOK_ELSE,
    TOK_IDENTIFIER, TOK_NUMBER, TOK_STRING,
    TOK_PLUS, TOK_LPAREN, TOK_RPAREN, TOK_LBRACE, TOK_RBRACE,
    TOK_COMMA, TOK_DOT, TOK_SEMICOLON, TOK_EOF
};

struct Token {
    TokenType type;
    std::string text;
    int line;
};

class Lexer {
    std::string src;
    size_t pos = 0;
    int line = 1;
public:
    Lexer(std::string s) : src(s) {}
    Token next() {
        while (pos < src.size()) {
            char c = src[pos];
            if (isspace(c)) {
                if (c == '\n') line++;
                pos++;
                continue;
            }
            if (isalpha(c)) {
                size_t start = pos;
                while (pos < src.size() && (isalnum(src[pos]) || src[pos] == '_')) pos++;
                std::string text = src.substr(start, pos - start);
                if (text == "function") return {TOK_FUNCTION, text, line};
                if (text == "return") return {TOK_RETURN, text, line};
                if (text == "export") return {TOK_EXPORT, text, line};
                if (text == "if") return {TOK_IF, text, line};
                if (text == "else") return {TOK_ELSE, text, line};
                return {TOK_IDENTIFIER, text, line};
            }
            if (isdigit(c)) {
                size_t start = pos;
                while (pos < src.size() && isdigit(src[pos])) pos++;
                return {TOK_NUMBER, src.substr(start, pos - start), line};
            }
            if (c == '"') {
                pos++;
                size_t start = pos;
                while (pos < src.size() && src[pos] != '"') pos++;
                std::string text = src.substr(start, pos - start);
                pos++;
                return {TOK_STRING, text, line};
            }
            pos++;
            switch (c) {
                case '+': return {TOK_PLUS, "+", line};
                case '(': return {TOK_LPAREN, "(", line};
                case ')': return {TOK_RPAREN, ")", line};
                case '{': return {TOK_LBRACE, "{", line};
                case '}': return {TOK_RBRACE, "}", line};
                case ',': return {TOK_COMMA, ",", line};
                case '.': return {TOK_DOT, ".", line};
                case ';': return {TOK_SEMICOLON, ";", line};
            }
            throw std::runtime_error("Unexpected char: " + std::string(1, c));
        }
        return {TOK_EOF, "", line};
    }
};

// AST / IR
enum class NodeKind {
    IntLiteral,
    StringLiteral,
    Arg,
    NameRef,
    Add,
    Call,
    Return,
    GlobalRef,
    MemberAccess,
    BrFalse,
    Jmp,
    None
};

struct Node {
    NodeKind kind = NodeKind::None;
    int int_val = 0;
    std::string str_val;
    std::vector<int> children; // indices
    int resolved_index = -1; // For NameRef
    int target_index = -1; // For BrFalse/Jmp
};

struct Function {
    std::string name;
    std::vector<std::string> args;
    int start_node;
    int end_node;
};

// Parser
class Parser {
    Lexer lexer;
    Token current;
    std::vector<Node> nodes;
    std::map<std::string, Function> functions;
    std::vector<std::map<std::string, int>> scope_stack;

    void advance() { current = lexer.next(); }
    void eat(TokenType t) {
        if (current.type == t) advance();
        else throw std::runtime_error("Expected token type " + std::to_string(t) + " got " + std::to_string(current.type) + " " + current.text + " at line " + std::to_string(current.line));
    }

    int emit(Node n) {
        nodes.push_back(n);
        return nodes.size() - 1;
    }

    int resolve(std::string name) {
        for (int i = scope_stack.size() - 1; i >= 0; i--) {
            if (scope_stack[i].count(name)) return scope_stack[i][name];
        }
        Node n;
        n.kind = NodeKind::GlobalRef;
        n.str_val = name;
        return emit(n);
    }

    int parseExpression() {
        int lhs = parsePrimary();
        while (current.type == TOK_PLUS) {
            advance();
            int rhs = parsePrimary();
            Node n; n.kind = NodeKind::Add; n.children = {lhs, rhs};
            lhs = emit(n);
        }
        return lhs;
    }

    int parsePrimary() {
        if (current.type == TOK_NUMBER) {
            Node n; n.kind = NodeKind::IntLiteral; n.int_val = std::stoi(current.text);
            advance();
            return emit(n);
        }
        if (current.type == TOK_STRING) {
            Node n; n.kind = NodeKind::StringLiteral; n.str_val = current.text;
            advance();
            return emit(n);
        }
        if (current.type == TOK_IDENTIFIER) {
            std::string name = current.text;
            advance();
            if (current.type == TOK_LPAREN) {
                return parseCall(name);
            }
            if (current.type == TOK_DOT) {
                advance();
                std::string member = current.text;
                eat(TOK_IDENTIFIER);
                int obj = resolve(name);
                Node n; n.kind = NodeKind::MemberAccess; n.str_val = member; n.children = {obj};
                int memberIdx = emit(n);
                if (current.type == TOK_LPAREN) {
                   return parseCallNode(memberIdx);
                }
                return memberIdx;
            }

             for (int i = scope_stack.size() - 1; i >= 0; i--) {
                if (scope_stack[i].count(name)) {
                     Node n; n.kind = NodeKind::NameRef; n.resolved_index = scope_stack[i][name];
                     return emit(n);
                }
            }
             Node n; n.kind = NodeKind::GlobalRef; n.str_val = name;
             return emit(n);
        }
        throw std::runtime_error("Unexpected token in expression: " + current.text);
    }

    int parseCall(std::string name) {
        int funcRef = resolve(name);
        return parseCallNode(funcRef);
    }

    int parseCallNode(int funcNodeIdx) {
        eat(TOK_LPAREN);
        std::vector<int> args;
        if (current.type != TOK_RPAREN) {
            args.push_back(parseExpression());
            while (current.type == TOK_COMMA) {
                advance();
                args.push_back(parseExpression());
            }
        }
        eat(TOK_RPAREN);
        Node n; n.kind = NodeKind::Call;
        n.children.push_back(funcNodeIdx);
        for(int a : args) n.children.push_back(a);
        return emit(n);
    }

    void parseBlock() {
        eat(TOK_LBRACE);
        while (current.type != TOK_RBRACE && current.type != TOK_EOF) {
            parseStatement();
        }
        eat(TOK_RBRACE);
    }

    void parseStatement() {
        if (current.type == TOK_RETURN) {
            advance();
            int expr = parseExpression();
            eat(TOK_SEMICOLON);
            Node n; n.kind = NodeKind::Return; n.children = {expr};
            emit(n);
        } else if (current.type == TOK_IF) {
            advance();
            eat(TOK_LPAREN);
            int cond = parseExpression();
            eat(TOK_RPAREN);

            Node br; br.kind = NodeKind::BrFalse; br.children = {cond};
            int brIdx = emit(br);

            parseBlock(); // Then block

            if (current.type == TOK_ELSE) {
                advance();
                Node jmp; jmp.kind = NodeKind::Jmp;
                int jmpIdx = emit(jmp);

                // Patch BrFalse to jump here (start of else)
                nodes[brIdx].target_index = nodes.size();

                parseBlock(); // Else block

                // Patch Jmp to jump here (end of else)
                nodes[jmpIdx].target_index = nodes.size();
            } else {
                // Patch BrFalse to jump here (end of then)
                nodes[brIdx].target_index = nodes.size();
            }
        } else {
            parseExpression();
            if (current.type == TOK_SEMICOLON) advance();
        }
    }

    void parseFunction() {
        if (current.type == TOK_EXPORT) advance();
        eat(TOK_FUNCTION);
        std::string name = current.text;
        eat(TOK_IDENTIFIER);

        Function func;
        func.name = name;

        eat(TOK_LPAREN);
        while (current.type == TOK_IDENTIFIER) {
            func.args.push_back(current.text);
            if (current.type == TOK_COMMA) advance();
            else break;
        }
        eat(TOK_RPAREN);

        func.start_node = nodes.size();

        scope_stack.push_back({});
        for (const auto& arg : func.args) {
             Node n; n.kind = NodeKind::Arg; n.str_val = arg;
             int idx = emit(n);
             scope_stack.back()[arg] = idx;
        }

        // We reuse parseBlock logic but parseBlock eats braces.
        parseBlock();

        func.end_node = nodes.size();
        functions[name] = func;
        scope_stack.pop_back();
    }

public:
    Parser(std::string src) : lexer(src) { advance(); }
    void parse() {
        while (current.type != TOK_EOF) {
            if (current.type == TOK_FUNCTION || current.type == TOK_EXPORT) {
                parseFunction();
            } else {
                advance();
            }
        }
    }
    const std::vector<Node>& getNodes() const { return nodes; }
    const std::map<std::string, Function>& getFunctions() const { return functions; }
};

// Evaluator
struct Value {
    bool is_int = true;
    int int_val = 0;
    std::string str_val;
};

class Evaluator {
    const std::vector<Node>& nodes;
    const std::map<std::string, Function>& functions;

public:
    Evaluator(const std::vector<Node>& n, const std::map<std::string, Function>& f)
        : nodes(n), functions(f) {}

    Value runFunction(std::string name, std::vector<Value> args) {
        if (!functions.count(name)) throw std::runtime_error("Function not found: " + name);
        const Function& func = functions.at(name);
        return executeRange(func.start_node, func.end_node, args);
    }

    Value executeRange(int start, int end, const std::vector<Value>& args) {
        std::map<int, Value> frame_values;

        int arg_idx = 0;
        for (int i = start; i < end; ++i) {
            const Node& node = nodes[i];
            if (node.kind == NodeKind::Arg) {
                if (arg_idx < args.size()) frame_values[i] = args[arg_idx++];
                else frame_values[i] = {true, 0, ""};
            }
        }

        for (int ip = start; ip < end; ) {
            const Node& node = nodes[ip];
            Value result = {true, 0, ""};
            int next_ip = ip + 1;

            switch (node.kind) {
                case NodeKind::IntLiteral:
                    result = {true, node.int_val, ""};
                    break;
                case NodeKind::StringLiteral:
                    result = {false, 0, node.str_val};
                    break;
                case NodeKind::Arg:
                    // Handled at start
                    break;
                case NodeKind::NameRef:
                    result = frame_values[node.resolved_index];
                    break;
                case NodeKind::Add: {
                    Value lhs = frame_values[node.children[0]];
                    Value rhs = frame_values[node.children[1]];
                    if (lhs.is_int && rhs.is_int)
                        result = {true, lhs.int_val + rhs.int_val, ""};
                    else
                        result = {true, 0, ""};
                    break;
                }
                case NodeKind::Call: {
                    int funcRefIdx = node.children[0];
                    std::string funcName;
                    if (nodes[funcRefIdx].kind == NodeKind::GlobalRef) {
                        funcName = nodes[funcRefIdx].str_val;
                    } else if (nodes[funcRefIdx].kind == NodeKind::MemberAccess) {
                         int objIdx = nodes[funcRefIdx].children[0];
                         std::string objName = nodes[objIdx].str_val;
                         std::string member = nodes[funcRefIdx].str_val;
                         if (objName == "console" && member == "log") {
                             for (size_t k = 1; k < node.children.size(); ++k) {
                                 Value v = frame_values[node.children[k]];
                                 if (v.is_int) std::cout << v.int_val << std::endl;
                                 else std::cout << v.str_val << std::endl;
                             }
                             result = {true, 0, ""};
                             goto save_result;
                         }
                         funcName = "???";
                    }

                    if (functions.count(funcName)) {
                        std::vector<Value> callArgs;
                        for (size_t k = 1; k < node.children.size(); ++k) {
                            callArgs.push_back(frame_values[node.children[k]]);
                        }
                        result = runFunction(funcName, callArgs);
                    }
                    break;
                }
                case NodeKind::Return: {
                    Value v = frame_values[node.children[0]];
                    return v;
                }
                case NodeKind::BrFalse: {
                    Value cond = frame_values[node.children[0]];
                    if (cond.is_int && cond.int_val == 0) { // 0 is false
                        next_ip = node.target_index;
                    }
                    break;
                }
                case NodeKind::Jmp: {
                    next_ip = node.target_index;
                    break;
                }
                default: break;
            }

            save_result:
            frame_values[ip] = result;
            ip = next_ip;
        }
        return {true, 0, ""};
    }
};

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <file.js>" << std::endl;
        return 1;
    }
    try {
        std::string src = read_file(argv[1]);
        Parser parser(src);
        parser.parse();

        Evaluator vm(parser.getNodes(), parser.getFunctions());
        vm.runFunction("test", {});

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}
