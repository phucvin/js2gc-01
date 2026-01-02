#include "vm.h"
#include <iostream>

using namespace std;

VM::VM(const vector<Instr>& i, const map<string, Function>& f, const map<string, GlobalDef>& g) : instrs(i), functions(f) {
    for (const auto& [name, def] : g) {
        globals[name] = execInstrs(def.init_instrs);
    }
}

RuntimeValue VM::run(string entry, vector<RuntimeValue> args) {
        if (!functions.count(entry)) return {};
        const Function& f = functions.at(entry);
        return exec(f.start_node, f.end_node, args);
}

RuntimeValue VM::execInstrs(const std::vector<Instr>& code) {
    // Execute a sequence of instructions independently
    // Used for global initialization
    // Simplified exec loop that doesn't use main instrs
    map<int, RuntimeValue> node_values;
    RuntimeValue last_val;

    for (size_t ip = 0; ip < code.size(); ++ip) {
        const Instr& i = code[ip];
        RuntimeValue res;

        // Duplicate switch case logic... ideally refactor.
        // For simplicity, we assume init exprs are simple (consts, struct.new)
        // struct.new is needed.

        switch (i.op) {
            case Op::ConstI32: res.i_val = i.int_imm; res.type = 0; break;
            case Op::RefI31: res.i_val = node_values[i.children[0]].i_val; res.type = 1; break;
            case Op::RefNull: res.type = 0; res.i_val = 0; break;
             case Op::StructNew: {
                HeapObject obj;
                obj.type_name = i.str_imm;
                for (int c : i.children) obj.fields.push_back(node_values[c]);
                heap.push_back(obj);
                res.type = 2; // Struct
                res.i_val = heap.size() - 1;
                break;
            }
             default: break; // Handle other ops if needed
        }
        node_values[ip] = res;
        last_val = res;
    }
    return last_val;
}

RuntimeValue VM::exec(int start, int end, vector<RuntimeValue> args) {
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
            case Op::EqI32:
                res.i_val = (node_values[i.children[0]].i_val == node_values[i.children[1]].i_val);
                break;
            case Op::AndI32: res.i_val = (node_values[i.children[0]].i_val & node_values[i.children[1]].i_val); break;
            case Op::LocalGet: res = locals[i.int_imm]; break;
            case Op::LocalSet: locals[i.int_imm] = node_values[i.children[0]]; break;
            case Op::GlobalGet: {
                 if (globals.count(i.str_imm)) {
                     res = globals[i.str_imm];
                 }
                 break;
            }
            case Op::Call: {
                    vector<RuntimeValue> callArgs;
                    for(int c : i.children) callArgs.push_back(node_values[c]);
                    if (i.str_imm == "$print_i32") { cout << callArgs[0].i_val << endl; }
                    else if (i.str_imm == "$print_f64") { cout << callArgs[0].f_val << endl; }
                    else if (i.str_imm == "$print_string") { cout << callArgs[0].s_val << endl; }
                    else if (i.str_imm == "$console_log") {
                        res = run(i.str_imm, callArgs);
                    } else {
                        res = run(i.str_imm, callArgs);
                    }
                    break;
            }
            case Op::CallRef: {
                vector<RuntimeValue> callArgs;
                // children: arg1, arg2, ..., funcRef
                // Last child is function ref
                for(size_t k=0; k<i.children.size()-1; ++k) {
                    callArgs.push_back(node_values[i.children[k]]);
                }
                RuntimeValue funcRef = node_values[i.children.back()];
                if (funcRef.type == 4) { // FuncRef
                    res = run(funcRef.s_val, callArgs);
                }
                break;
            }
            case Op::RefFunc: {
                res.type = 4;
                res.s_val = i.str_imm;
                break;
            }
            case Op::RefI31: res.i_val = node_values[i.children[0]].i_val; res.type = 1; break;
            case Op::I31GetS: res.i_val = node_values[i.children[0]].i_val; res.type = 0; break;
            case Op::RefNull: res.type = 0; res.i_val = 0; break;
            case Op::RefIsNull: res.i_val = (node_values[i.children[0]].type == 0 && node_values[i.children[0]].i_val == 0); break;
            case Op::RefAsNonNull: res = node_values[i.children[0]]; break;
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
