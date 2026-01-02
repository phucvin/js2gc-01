#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <map>
#include <variant>
#include <algorithm>
#include <memory>
#include <iomanip>

using namespace std;

// Utils
std::string read_file(const std::string& path) {
    std::ifstream t(path);
    if (!t.is_open()) throw std::runtime_error("Cannot open file: " + path);
    std::stringstream buffer;
    buffer << t.rdbuf();
    return buffer.str();
}

// --- Lexer & S-Expression Parser ---

enum TokenType { T_LPAREN, T_RPAREN, T_STRING, T_NUMBER, T_KEYWORD, T_EOF };

struct Token {
    TokenType type;
    string text;
};

class Lexer {
    string src;
    size_t pos = 0;
public:
    Lexer(string s) : src(s) {}
    Token next() {
        while (pos < src.size()) {
            char c = src[pos];
            if (isspace(c)) { pos++; continue; }
            if (c == ';') { // Comment
                while (pos < src.size() && src[pos] != '\n') pos++;
                continue;
            }
            if (c == '(') { pos++; return {T_LPAREN, "("}; }
            if (c == ')') { pos++; return {T_RPAREN, ")"}; }
            if (c == '"') {
                pos++;
                size_t start = pos;
                while (pos < src.size() && src[pos] != '"') {
                    if (src[pos] == '\\') pos++; // skip escape
                    pos++;
                }
                string s = src.substr(start, pos - start);
                pos++;
                return {T_STRING, s};
            }
            // Atom
            size_t start = pos;
            while (pos < src.size() && !isspace(src[pos]) && src[pos] != '(' && src[pos] != ')' && src[pos] != ';') {
                pos++;
            }
            string text = src.substr(start, pos - start);

            // Heuristic for number vs keyword
            bool isNum = true;
            if (text.empty()) isNum = false;
            else {
                size_t i = 0;
                if (text[i] == '-' || text[i] == '+') i++;
                if (i >= text.size()) isNum = false;
                else {
                     // Check for hex or float
                     // minimal check
                    if (!isdigit(text[i]) && text[i] != '.') isNum = false;
                }
            }
            // Also explicitly handle hex 0x...
            if (text.size() > 2 && text[0] == '0' && text[1] == 'x') isNum = true;

            if (isNum) return {T_NUMBER, text};
            return {T_KEYWORD, text};
        }
        return {T_EOF, ""};
    }
};

struct SExpr {
    bool is_list = false;
    string value;
    vector<SExpr> children;
};

class SParser {
    Lexer lexer;
    Token current;
    void advance() { current = lexer.next(); }
public:
    SParser(string src) : lexer(src) { advance(); }

    SExpr parse() {
        if (current.type == T_LPAREN) {
            advance();
            SExpr list;
            list.is_list = true;
            while (current.type != T_RPAREN && current.type != T_EOF) {
                list.children.push_back(parse());
            }
            if (current.type == T_RPAREN) advance();
            return list;
        } else if (current.type == T_EOF) {
             return {false, "", {}};
        } else {
            string val = current.text;
            advance();
            return {false, val, {}};
        }
    }
};

// --- IR / AST ---

enum class Op {
    ConstI32, ConstF64, ConstString,
    AddI32, AddF64, EqI32, AndI32,
    LocalGet, LocalSet, GlobalGet,
    Call, CallRef,
    StructNew, StructGet, StructSet,
    RefI31, I31GetS, RefCast, RefTest, RefNull, RefIsNull, RefFunc, RefAsNonNull,
    BrFalse, Jmp, Return,
    Nop
};

struct Instr {
    Op op = Op::Nop;
    int int_imm = 0;
    double float_imm = 0;
    string str_imm;
    vector<int> children; // Operand indices (Indexed RPN)
    int target = -1; // Branch target
};

struct Function {
    string name;
    vector<string> params;
    vector<string> locals;
    int start_node = 0;
    int end_node = 0;
};

struct TypeDef {
    string name;
    string kind;
    vector<string> fields;
    map<string, int> field_map;
};

// --- Compiler (SExpr -> Indexed RPN) ---

class Compiler {
    vector<Instr> instrs;
    map<string, Function> functions;
    map<string, TypeDef> types;

    vector<int> stack;
    map<string, int> local_map;

    string getTypeName(const SExpr& e) {
        if (!e.is_list) return e.value;
        if (e.children.empty()) return "";
        if (e.children.size() >= 2) {
             if (e.children[1].value == "null") {
                 return (e.children.size() >= 3) ? e.children[2].value : "";
             }
             return e.children[1].value;
        }
        return "";
    }

public:
    const vector<Instr>& getInstrs() const { return instrs; }
    const map<string, Function>& getFunctions() const { return functions; }
    const map<string, TypeDef>& getTypes() const { return types; }

    int emit(Instr i) {
        instrs.push_back(i);
        return instrs.size() - 1;
    }

    void compileModule(const SExpr& module) {
        for (const auto& item : module.children) {
            if (item.is_list && !item.children.empty() && item.children[0].value == "rec") {
                for (size_t i = 1; i < item.children.size(); ++i) parseType(item.children[i]);
            }
            if (item.is_list && !item.children.empty() && item.children[0].value == "type") {
                 parseType(item);
            }
            if (item.is_list && !item.children.empty() && item.children[0].value == "func") {
                parseFuncSig(item);
            }
        }

        for (const auto& item : module.children) {
            if (item.is_list && !item.children.empty() && item.children[0].value == "func") {
                compileFunc(item);
            }
        }
    }

    void parseType(const SExpr& t) {
        if (t.children.size() < 3) return;
        string name = t.children[1].value;
        const SExpr& def = t.children[2];
        TypeDef td;
        td.name = name;
        td.kind = def.children[0].value;
        // Parse fields properly
        // (struct (field $x i32) ...) or (struct (field i32) ...)
        for (size_t i = 1; i < def.children.size(); ++i) {
            const SExpr& f = def.children[i];
            if (f.is_list && f.children[0].value == "field") {
                // Check if named
                if (f.children.size() > 1 && f.children[1].value[0] == '$') {
                    string fname = f.children[1].value;
                    td.field_map[fname] = td.fields.size();
                    td.fields.push_back(fname);
                } else {
                    td.fields.push_back("");
                }
            } else {
                // Maybe implicit field? WAT is flexible.
                // Assuming well-formed (field ...) for now as per `add.wat`
                td.fields.push_back("");
            }
        }
        types[name] = td;
    }

    void parseFuncSig(const SExpr& f) {
        Function func;
        size_t idx = 1;
        if (idx < f.children.size() && !f.children[idx].is_list) {
            func.name = f.children[idx].value;
            idx++;
        }
        for (; idx < f.children.size(); ++idx) {
            const SExpr& e = f.children[idx];
            if (e.is_list) {
                if (e.children[0].value == "param") {
                    for (size_t k = 1; k < e.children.size(); ++k) {
                        string p = e.children[k].value;
                        if (p[0] == '$') func.params.push_back(p);
                        else func.params.push_back("");
                    }
                }
            }
        }
        if (!func.name.empty()) functions[func.name] = func;
    }

    void compileFunc(const SExpr& f) {
        string name;
        size_t idx = 1;
        if (idx < f.children.size() && !f.children[idx].is_list) {
            name = f.children[idx].value;
            idx++;
        } else {
            return;
        }

        Function& func = functions[name];
        func.start_node = instrs.size();

        stack.clear();
        local_map.clear();

        int local_idx = 0;
        for (const string& p : func.params) {
            if (!p.empty()) local_map[p] = local_idx;
            local_idx++;
        }

        for (; idx < f.children.size(); ++idx) {
            const SExpr& e = f.children[idx];
            if (e.is_list && e.children[0].value == "local") {
                for (size_t k = 1; k < e.children.size(); ++k) {
                    string l = e.children[k].value;
                    if (l[0] == '$') local_map[l] = local_idx;
                    local_idx++;
                }
            } else {
                break;
            }
        }
        func.locals.resize(local_idx);

        for (; idx < f.children.size(); ++idx) {
            compileExpr(f.children[idx]);
        }

        if (!stack.empty()) {
            Instr ret; ret.op = Op::Return; ret.children = {stack.back()};
            emit(ret);
        }

        func.end_node = instrs.size();
    }

    void compileExpr(const SExpr& e) {
        if (e.is_list) {
            string op = e.children[0].value;

            if (op == "if") {
                handleIf(e);
                return;
            }
            if (op == "block") {
                 for (size_t i=1; i<e.children.size(); ++i) compileExpr(e.children[i]);
                 return;
            }

            if (op == "i32.const") {
                Instr i; i.op = Op::ConstI32; i.int_imm = stoi(e.children[1].value);
                stack.push_back(emit(i));
                return;
            }
             if (op == "f64.const") {
                Instr i; i.op = Op::ConstF64; i.float_imm = stod(e.children[1].value);
                stack.push_back(emit(i));
                return;
            }
            if (op == "string.const") {
                Instr i; i.op = Op::ConstString; i.str_imm = e.children[1].value;
                stack.push_back(emit(i));
                return;
            }
            if (op == "local.get") {
                Instr i; i.op = Op::LocalGet;
                string l = e.children[1].value;
                i.int_imm = local_map.count(l) ? local_map[l] : -1;
                stack.push_back(emit(i));
                return;
            }
             if (op == "local.set") {
                compileExpr(e.children[2]);
                int val = stack.back(); stack.pop_back();
                Instr i; i.op = Op::LocalSet;
                string l = e.children[1].value;
                i.int_imm = local_map.count(l) ? local_map[l] : -1;
                i.children = {val};
                emit(i);
                return;
            }
            if (op == "call") {
                for (size_t i=2; i<e.children.size(); ++i) compileExpr(e.children[i]);
                Instr i; i.op = Op::Call; i.str_imm = e.children[1].value;
                size_t numArgs = e.children.size() - 2;
                for(size_t k=0; k<numArgs; ++k) {
                    i.children.insert(i.children.begin(), stack.back());
                    stack.pop_back();
                }
                stack.push_back(emit(i));
                return;
            }
             if (op == "call_ref") {
                 for (size_t i=2; i<e.children.size(); ++i) compileExpr(e.children[i]);
                 Instr i; i.op = Op::CallRef; i.str_imm = e.children[1].value;
                 size_t numArgs = e.children.size() - 2;
                 for(size_t k=0; k<numArgs; ++k) {
                     i.children.insert(i.children.begin(), stack.back());
                     stack.pop_back();
                 }
                 stack.push_back(emit(i));
                 return;
             }

            Op opcode = Op::Nop;
            int imm_skip = 0;
            if (op == "i32.add") opcode = Op::AddI32;
            else if (op == "ref.i31") opcode = Op::RefI31;
            else if (op == "i31.get_s") opcode = Op::I31GetS;
            else if (op == "struct.new") { opcode = Op::StructNew; imm_skip=1; }
            else if (op == "struct.get") { opcode = Op::StructGet; imm_skip=2; }
            else if (op == "struct.set") { opcode = Op::StructSet; imm_skip=2; }
            else if (op == "ref.cast") { opcode = Op::RefCast; imm_skip=1; }
            else if (op == "ref.test") { opcode = Op::RefTest; imm_skip=1; }
            else if (op == "ref.null") { opcode = Op::RefNull; imm_skip=1; }
            else if (op == "ref.is_null") opcode = Op::RefIsNull;
            else if (op == "ref.func") { opcode = Op::RefFunc; imm_skip=1; }
            else if (op == "ref.as_non_null") opcode = Op::RefAsNonNull;
            else if (op == "global.get") { opcode = Op::GlobalGet; imm_skip=1; }
            else if (op == "i32.eq") opcode = Op::EqI32;
            else if (op == "i32.and") opcode = Op::AndI32;
            else if (op == "return") opcode = Op::Return;

            for (size_t i = 1 + imm_skip; i < e.children.size(); ++i) {
                compileExpr(e.children[i]);
            }

            Instr i; i.op = opcode;
            if (imm_skip > 0) i.str_imm = getTypeName(e.children[1]);

            if (opcode == Op::StructGet || opcode == Op::StructSet) {
                 string fieldId = e.children[2].value;
                 if (isdigit(fieldId[0])) {
                     i.int_imm = stoi(fieldId);
                 } else {
                     // Named field lookup
                     string typeName = i.str_imm;
                     if (types.count(typeName) && types[typeName].field_map.count(fieldId)) {
                         i.int_imm = types[typeName].field_map[fieldId];
                     } else {
                         // Fallback or error
                         i.int_imm = 0;
                     }
                 }
            }

            int pop_count = 0;
            if (opcode == Op::AddI32 || opcode == Op::EqI32 || opcode == Op::AndI32) pop_count = 2;
            else if (opcode == Op::RefI31 || opcode == Op::I31GetS || opcode == Op::RefCast || opcode == Op::RefTest || opcode == Op::RefIsNull || opcode == Op::RefAsNonNull || opcode == Op::Return || opcode == Op::StructGet) pop_count = 1;
             else if (opcode == Op::StructSet) pop_count = 2; // ref, val
            else if (opcode == Op::StructNew) {
                if (types.count(i.str_imm)) pop_count = types[i.str_imm].fields.size();
            }

            for(int k=0; k<pop_count; ++k) {
                if(stack.empty()) break;
                i.children.insert(i.children.begin(), stack.back());
                stack.pop_back();
            }

            if (opcode != Op::Return && opcode != Op::Nop && opcode != Op::StructSet) {
                stack.push_back(emit(i));
            } else {
                emit(i);
            }

        } else {
             // Linear mode omitted
        }
    }

    void handleIf(const SExpr& e) {
        size_t idx = 1;
        if (e.children[idx].is_list && e.children[idx].children[0].value == "result") {
            idx++;
        }

        compileExpr(e.children[idx]);
        int cond = stack.back(); stack.pop_back();
        idx++;

        Instr br; br.op = Op::BrFalse; br.children = {cond};
        int brIdx = emit(br);

        SExpr thenBlock = e.children[idx];
        idx++;
        if (thenBlock.is_list && thenBlock.children[0].value == "then") {
            for (size_t i=1; i<thenBlock.children.size(); ++i) compileExpr(thenBlock.children[i]);
        }

        Instr jmp; jmp.op = Op::Jmp;
        int jmpIdx = emit(jmp);

        instrs[brIdx].target = instrs.size();

        if (idx < e.children.size()) {
            SExpr elseBlock = e.children[idx];
             if (elseBlock.is_list && elseBlock.children[0].value == "else") {
                for (size_t i=1; i<elseBlock.children.size(); ++i) compileExpr(elseBlock.children[i]);
            }
        }

        instrs[jmpIdx].target = instrs.size();
    }
};

// --- Evaluator ---

struct RuntimeValue {
    int type = 0; // 0=i32/f64/null, 1=i31, 2=BoxedF64...
    long long i_val = 0;
    double f_val = 0;
    string s_val;
};

struct HeapObject {
    string type_name;
    vector<RuntimeValue> fields;
};

class VM {
    const vector<Instr>& instrs;
    const map<string, Function>& functions;
    vector<HeapObject> heap;

public:
    VM(const vector<Instr>& i, const map<string, Function>& f) : instrs(i), functions(f) {}

    RuntimeValue run(string entry, vector<RuntimeValue> args) {
         if (!functions.count(entry)) return {};
         const Function& f = functions.at(entry);
         return exec(f.start_node, f.end_node, args);
    }

    RuntimeValue exec(int start, int end, vector<RuntimeValue> args) {
        map<int, RuntimeValue> locals;
        for(size_t i=0; i<args.size(); ++i) locals[i] = args[i];

        map<int, RuntimeValue> node_values;
        RuntimeValue last_val;

        for (int ip = start; ip < end; ) {
            const Instr& i = instrs[ip];
            RuntimeValue res;
            int next_ip = ip + 1;

            switch (i.op) {
                case Op::ConstI32: res.i_val = i.int_imm; res.type = 0; break;
                case Op::ConstF64: res.f_val = i.float_imm; res.type = 0; break;
                case Op::ConstString: res.s_val = i.str_imm; res.type = 3; break;
                case Op::AddI32: res.i_val = node_values[i.children[0]].i_val + node_values[i.children[1]].i_val; break;
                case Op::LocalGet: res = locals[i.int_imm]; break;
                case Op::LocalSet: locals[i.int_imm] = node_values[i.children[0]]; break;
                case Op::Call: {
                     vector<RuntimeValue> callArgs;
                     for(int c : i.children) callArgs.push_back(node_values[c]);
                     if (i.str_imm == "$print_i32") { cout << callArgs[0].i_val << endl; }
                     else if (i.str_imm == "$print_string") { cout << callArgs[0].s_val << endl; }
                     else if (i.str_imm == "$console_log") {
                         res = run(i.str_imm, callArgs);
                     } else {
                         res = run(i.str_imm, callArgs);
                     }
                     break;
                }
                case Op::RefI31: res.i_val = node_values[i.children[0]].i_val; res.type = 1; break;
                case Op::I31GetS: res.i_val = node_values[i.children[0]].i_val; res.type = 0; break;
                case Op::RefNull: res.type = 0; res.i_val = 0; break;
                case Op::RefIsNull: res.i_val = (node_values[i.children[0]].i_val == 0); break;
                case Op::BrFalse: {
                    if (node_values[i.children[0]].i_val == 0) next_ip = i.target;
                    break;
                }
                case Op::Jmp: next_ip = i.target; break;
                case Op::Return: return node_values[i.children[0]];

                case Op::RefTest: {
                    RuntimeValue val = node_values[i.children[0]];
                    bool match = false;
                    if (i.str_imm == "i31") match = (val.type == 1);
                    else if (i.str_imm == "string") match = (val.type == 3);
                    else {
                         if (val.type == 2 && heap[val.i_val].type_name == i.str_imm) match = true;
                    }
                    res.i_val = match;
                    break;
                }
                case Op::RefCast: {
                     res = node_values[i.children[0]];
                     break;
                }
                case Op::StructNew: {
                    HeapObject obj;
                    obj.type_name = i.str_imm;
                    for (int c : i.children) obj.fields.push_back(node_values[c]);
                    heap.push_back(obj);
                    res.type = 2; // Struct
                    res.i_val = heap.size() - 1;
                    break;
                }
                case Op::StructGet: {
                    RuntimeValue ref = node_values[i.children[0]];
                    if (ref.type == 2) {
                        HeapObject& obj = heap[ref.i_val];
                        if (i.int_imm >= 0 && i.int_imm < (int)obj.fields.size()) res = obj.fields[i.int_imm];
                    }
                    break;
                }
                case Op::StructSet: {
                    RuntimeValue ref = node_values[i.children[0]];
                    RuntimeValue val = node_values[i.children[1]];
                    if (ref.type == 2) {
                        HeapObject& obj = heap[ref.i_val];
                        if (i.int_imm >= 0 && i.int_imm < (int)obj.fields.size()) obj.fields[i.int_imm] = val;
                    }
                    break;
                }
                default: break;
            }

            node_values[ip] = res;
            if (i.op != Op::Jmp && i.op != Op::BrFalse && i.op != Op::LocalSet && i.op != Op::StructSet) last_val = res;
            ip = next_ip;
        }
        return last_val;
    }
};

int main(int argc, char** argv) {
    if (argc < 2) return 1;
    string src = read_file(argv[1]);
    SParser p(src);
    SExpr mod = p.parse();

    Compiler c;
    c.compileModule(mod);

    VM vm(c.getInstrs(), c.getFunctions());
    vm.run("$test", {});

    return 0;
}
