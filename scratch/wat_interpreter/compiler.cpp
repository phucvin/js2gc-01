#include "compiler.h"
#include <string>

using namespace std;

string Compiler::getTypeName(const SExpr& e) {
    if (!e.is_list) return e.value;
    if (e.children.empty()) return "";
    // Handle (ref $Type) or (ref null $Type)
    if (e.children[0].value == "ref") {
         if (e.children.size() > 1) {
             if (e.children[1].value == "null" && e.children.size() > 2) return e.children[2].value;
             return e.children[1].value;
         }
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
        if (item.is_list && !item.children.empty() && item.children[0].value == "global") {
            parseGlobal(item);
        }
    }

    for (const auto& item : module.children) {
        if (item.is_list && !item.children.empty() && item.children[0].value == "func") {
            compileFunc(item);
        }
    }
}

void Compiler::parseGlobal(const SExpr& g) {
    if (g.children.size() < 4) return;
    GlobalDef gd;
    gd.name = g.children[1].value;

    const SExpr& initExpr = g.children.back();

    std::vector<Instr> old_instrs = instrs;
    instrs.clear();
    stack.clear();

    compileExpr(initExpr);

    gd.init_instrs = instrs;
    instrs = old_instrs;

    globals[gd.name] = gd;
}

void Compiler::parseType(const SExpr& t) {
    if (t.children.size() < 3) return;
    string name = t.children[1].value;
    const SExpr& def = t.children[2];
    TypeDef td;
    td.name = name;
    td.kind = def.children[0].value;
    for (size_t i = 1; i < def.children.size(); ++i) {
        const SExpr& f = def.children[i];
        if (f.is_list && f.children[0].value == "field") {
            if (f.children.size() > 1 && f.children[1].value[0] == '$') {
                string fname = f.children[1].value;
                td.field_map[fname] = td.fields.size();
                td.fields.push_back(fname);
            } else {
                td.fields.push_back("");
            }
        } else {
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
                    if (p.length() > 0 && p[0] == '$') {
                         func.params.push_back(p);
                         if (k + 1 < e.children.size()) {
                             k++;
                         }
                    } else {
                        func.params.push_back("");
                    }
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
    control_stack.clear();

    int local_idx = 0;
    for (const string& p : func.params) {
        if (!p.empty()) local_map[p] = local_idx;
        local_idx++;
    }

    for (; idx < f.children.size(); ++idx) {
        const SExpr& e = f.children[idx];
        if (!e.is_list) {
            break;
        }
        if (e.children.empty()) continue;

        string op = e.children[0].value;
        if (op == "local") {
            for (size_t k = 1; k < e.children.size(); ++k) {
                string l = e.children[k].value;
                if (l.length() > 0 && l[0] == '$') {
                    local_map[l] = local_idx;
                    if (k + 1 < e.children.size()) {
                        k++;
                    }
                }
                local_idx++;
            }
        } else if (op == "param" || op == "result" || op == "type") {
            continue;
        } else if (op == "elem") {
            continue;
        } else {
            break;
        }
    }
    func.locals.resize(local_idx);

    for (; idx < f.children.size(); ++idx) {
        compileExpr(f.children[idx]);
    }

    // Implicit return: do not emit Op::Return at the end.

    func.end_node = instrs.size();
}

void Compiler::handleBlock(const SExpr& e, bool is_loop) {
    string label;
    int start_idx = 1;
    if (e.children.size() > 1 && e.children[1].value.length() > 0 && e.children[1].value[0] == '$') {
        label = e.children[1].value;
        start_idx = 2;
    }
    bool has_result = false;
    if (start_idx < e.children.size() && e.children[start_idx].is_list && !e.children[start_idx].children.empty() && e.children[start_idx].children[0].value == "result") {
        has_result = true;
        start_idx++;
    }

    int block_start_instr = instrs.size();

    BlockScope scope;
    scope.label = label;
    scope.is_loop = is_loop;
    scope.start_instr = block_start_instr;
    control_stack.push_back(scope);

    for (size_t i=start_idx; i<e.children.size(); ++i) {
        compileExpr(e.children[i]);
    }

    BlockScope finished_scope = control_stack.back();
    control_stack.pop_back();

    int block_end_instr = instrs.size();
    for (int patch_idx : finished_scope.patches) {
        instrs[patch_idx].target = block_end_instr;
    }
}

void Compiler::compileExpr(const SExpr& e) {
    if (e.is_list) {
        if (e.children.empty()) return;
        string op = e.children[0].value;

        if (op == "if") {
            handleIf(e);
            return;
        }
        if (op == "block") {
            handleBlock(e, false);
            return;
        }
        if (op == "loop") {
            handleBlock(e, true);
            return;
        }

        if (op == "br" || op == "br_if") {
            string label;
            int child_idx = 1;
            if (e.children.size() > 1 && e.children[1].value.length() > 0 && e.children[1].value[0] == '$') {
                label = e.children[1].value;
                child_idx = 2;
            } else if (e.children.size() > 1 && isdigit(e.children[1].value[0])) {
                int depth = stoi(e.children[1].value);
                if (depth < control_stack.size()) {
                    const BlockScope& scope = control_stack[control_stack.size() - 1 - depth];
                    label = scope.label;
                }
            }

            int cond = -1;
            if (op == "br_if") {
                 if (e.children.size() > child_idx) {
                     compileExpr(e.children[child_idx]);
                     if (!stack.empty()) {
                         cond = stack.back(); stack.pop_back();
                     }
                 }
            }

            Instr br;
            br.op = (op == "br_if") ? Op::BrTrue : Op::Jmp;
            if (op == "br_if") br.children = {cond};

            bool found = false;
            int depth = -1;
            if (label.empty() && e.children.size() > 1 && isdigit(e.children[1].value[0])) {
                 depth = stoi(e.children[1].value);
            }

            for (int i = control_stack.size() - 1; i >= 0; --i) {
                bool match = false;
                if (depth != -1) {
                    if ((int)control_stack.size() - 1 - i == depth) match = true;
                } else if (!label.empty()) {
                    if (control_stack[i].label == label) match = true;
                } else {
                    if (i == control_stack.size() - 1) match = true;
                }

                if (match) {
                    if (control_stack[i].is_loop) {
                        br.target = control_stack[i].start_instr;
                    } else {
                        control_stack[i].patches.push_back(instrs.size());
                    }
                    found = true;
                    break;
                }
            }

            emit(br);
            return;
        }

        if (op == "drop") {
            compileExpr(e.children[1]);
            if (!stack.empty()) stack.pop_back();
            return;
        }

        if (op == "nop") return;

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
        if (op == "local.tee") {
            compileExpr(e.children[2]);
            int val = stack.back();
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
        if (op == "i32.add" || op == "i32.sub" || op == "f64.add" || op == "f64.sub" || op == "f64.mul" || op == "f64.div") {
            if (op == "i32.add") opcode = Op::AddI32;
            else if (op == "i32.sub") opcode = Op::SubI32;
            else if (op == "f64.add") opcode = Op::AddF64;
            else if (op == "f64.sub") opcode = Op::SubF64;
            else if (op == "f64.mul") opcode = Op::MulF64;
            else if (op == "f64.div") opcode = Op::DivF64;
        }
        else if (op == "ref.i31") opcode = Op::RefI31;
        else if (op == "i31.get_s") opcode = Op::I31GetS;
        else if (op == "struct.new") { opcode = Op::StructNew; imm_skip=1; }
        else if (op == "struct.get") { opcode = Op::StructGet; imm_skip=2; }
        else if (op == "struct.set") { opcode = Op::StructSet; imm_skip=2; }
        else if (op == "array.new_default") { opcode = Op::ArrayNewDefault; imm_skip=1; }
        else if (op == "array.new") { opcode = Op::ArrayNew; imm_skip=1; }
        else if (op == "array.get") { opcode = Op::ArrayGet; imm_skip=1; }
        else if (op == "array.set") { opcode = Op::ArraySet; imm_skip=1; }
        else if (op == "array.len") { opcode = Op::ArrayLen; imm_skip=0; }
        else if (op == "array.copy") { opcode = Op::ArrayCopy; imm_skip=2; } // skip 2 types
        else if (op == "ref.cast") { opcode = Op::RefCast; imm_skip=1; }
        else if (op == "ref.test") { opcode = Op::RefTest; imm_skip=1; }
        else if (op == "ref.null") { opcode = Op::RefNull; imm_skip=1; }
        else if (op == "ref.is_null") opcode = Op::RefIsNull;
        else if (op == "ref.func") { opcode = Op::RefFunc; imm_skip=1; }
        else if (op == "ref.as_non_null") opcode = Op::RefAsNonNull;
        else if (op == "global.get") {
             Instr i; i.op = Op::GlobalGet; i.str_imm = e.children[1].value;
             stack.push_back(emit(i));
             return;
        }
        else if (op == "i32.eq") opcode = Op::EqI32;
        else if (op == "i32.ne") opcode = Op::NeI32;
        else if (op == "i32.and") opcode = Op::AndI32;
        else if (op == "i32.lt_s") opcode = Op::LtI32;
        else if (op == "i32.ge_s") opcode = Op::GeI32;
        else if (op == "i32.eqz") opcode = Op::EqzI32;
        else if (op == "f64.convert_i32_s") opcode = Op::ConvertI32ToF64;
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
                    string typeName = i.str_imm;
                    if (types.count(typeName) && types[typeName].field_map.count(fieldId)) {
                        i.int_imm = types[typeName].field_map[fieldId];
                    } else {
                        i.int_imm = 0;
                    }
                }
        }

        int pop_count = 0;
        if (opcode == Op::AddI32 || opcode == Op::SubI32 || opcode == Op::EqI32 || opcode == Op::AndI32 || opcode == Op::AddF64 || opcode == Op::SubF64 || opcode == Op::MulF64 || opcode == Op::DivF64 || opcode == Op::LtI32 || opcode == Op::GeI32) pop_count = 2;
        else if (opcode == Op::RefI31 || opcode == Op::I31GetS || opcode == Op::RefCast || opcode == Op::RefTest || opcode == Op::RefIsNull || opcode == Op::RefAsNonNull || opcode == Op::Return || opcode == Op::StructGet || opcode == Op::EqzI32 || opcode == Op::ConvertI32ToF64 || opcode == Op::ArrayNewDefault || opcode == Op::ArrayLen) pop_count = 1;
            else if (opcode == Op::StructSet || opcode == Op::ArrayGet) pop_count = 2;
            else if (opcode == Op::ArraySet) pop_count = 3;
            else if (opcode == Op::ArrayCopy) pop_count = 5;
        else if (opcode == Op::StructNew) {
            if (types.count(i.str_imm)) pop_count = types[i.str_imm].fields.size();
        }
        else if (opcode == Op::ArrayNew) {
             // ArrayNew takes size + 'size' elements? No, usually array.new $Type (val) (size).
             // Binaryen: (array.new $Type (val) (size))
             // children: [type, val, size]
             // pop_count = 2.
             pop_count = 2;
        }

        for(int k=0; k<pop_count; ++k) {
            if(stack.empty()) break;
            i.children.insert(i.children.begin(), stack.back());
            stack.pop_back();
        }

        if (opcode != Op::Return && opcode != Op::Nop && opcode != Op::StructSet && opcode != Op::ArraySet && opcode != Op::ArrayCopy) {
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
    bool has_result = false;
    if (idx < e.children.size() && e.children[idx].is_list && !e.children[idx].children.empty() && e.children[idx].children[0].value == "result") {
        has_result = true;
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
