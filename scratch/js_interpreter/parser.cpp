#include "parser.h"
#include <stdexcept>
#include <iostream>

Parser::Parser(std::string src) : lexer(src) { advance(); }

void Parser::advance() { current = lexer.next(); }

void Parser::eat(TokenType t) {
    if (current.type == t) advance();
    else throw std::runtime_error("Expected token type " + std::to_string(t) + " got " + std::to_string(current.type) + " " + current.text + " at line " + std::to_string(current.line));
}

int Parser::emit(Node n) {
    nodes.push_back(n);
    return nodes.size() - 1;
}

int Parser::resolve(std::string name) {
    for (int i = scope_stack.size() - 1; i >= 0; i--) {
        if (scope_stack[i].count(name)) return scope_stack[i][name];
    }
    Node n;
    n.kind = NodeKind::GlobalRef;
    n.str_val = name;
    return emit(n);
}

int Parser::parseExpression() {
    int lhs = parsePrimary();
    while (current.type == TOK_PLUS) {
        advance();
        int rhs = parsePrimary();
        Node n; n.kind = NodeKind::Add; n.children = {lhs, rhs};
        lhs = emit(n);
    }
    return lhs;
}

int Parser::parsePrimary() {
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

int Parser::parseCall(std::string name) {
    int funcRef = resolve(name);
    return parseCallNode(funcRef);
}

int Parser::parseCallNode(int funcNodeIdx) {
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

void Parser::parseBlock() {
    eat(TOK_LBRACE);
    while (current.type != TOK_RBRACE && current.type != TOK_EOF) {
        parseStatement();
    }
    eat(TOK_RBRACE);
}

void Parser::parseStatement() {
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

void Parser::parseFunction() {
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

void Parser::parse() {
    while (current.type != TOK_EOF) {
        if (current.type == TOK_FUNCTION || current.type == TOK_EXPORT) {
            parseFunction();
        } else {
            advance();
        }
    }
}
