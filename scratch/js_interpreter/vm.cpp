#include "vm.h"
#include <iostream>
#include <stdexcept>

Evaluator::Evaluator(const std::vector<Node>& n, const std::map<std::string, Function>& f)
    : nodes(n), functions(f) {}

Value Evaluator::runFunction(std::string name, std::vector<Value> args) {
    if (!functions.count(name)) throw std::runtime_error("Function not found: " + name);
    const Function& func = functions.at(name);
    return executeRange(func.start_node, func.end_node, args);
}

Value Evaluator::executeRange(int start, int end, const std::vector<Value>& args) {
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
