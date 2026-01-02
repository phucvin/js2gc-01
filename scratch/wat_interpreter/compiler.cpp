#include "compiler.h"
#include <string>

using namespace std;

string Compiler::getTypeName(const SExpr& e) {
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

int Compiler::emit(Instr i) {
    instrs.push_back(i);
    return instrs.size() - 1;
}

void Compiler::compileModule(const SExpr& module) {
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

void Compiler::parseType(const SExpr& t) {
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

void Compiler::parseFuncSig(const SExpr& f) {
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

void Compiler::compileFunc(const SExpr& f) {
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

void Compiler::compileExpr(const SExpr& e) {
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

void Compiler::handleIf(const SExpr& e) {
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
