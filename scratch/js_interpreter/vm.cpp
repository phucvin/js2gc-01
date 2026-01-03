#include "vm.h"
#include <iostream>
#include <stdexcept>
#include <cmath>

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
            else frame_values[i] = Value::makeUndefined();
        }
    }

    int steps = 0;
    for (int ip = start; ip < end; ) {
        steps++;
        if (steps > 100000) {
            throw std::runtime_error("Infinite loop detected");
        }

        const Node& node = nodes[ip];
        Value result = Value::makeUndefined();
        int next_ip = ip + 1;

        switch (node.kind) {
            case NodeKind::IntLiteral:
                result = Value::makeInt(node.int_val);
                break;
            case NodeKind::FloatLiteral:
                result = Value::makeFloat(node.float_val);
                break;
            case NodeKind::StringLiteral:
                result = Value::makeString(node.str_val);
                break;
            case NodeKind::Arg:
                // Typically Arg nodes are processed at start, but if encountered, return value
                if (frame_values.count(ip)) result = frame_values[ip];
                break;
            case NodeKind::Let: {
                if (!node.children.empty()) {
                    int childIdx = node.children[0];
                    if (frame_values.count(childIdx)) {
                         result = frame_values[childIdx];
                    }
                }
                break;
            }
            case NodeKind::NameRef:
                if (frame_values.count(node.resolved_index)) {
                    result = frame_values[node.resolved_index];
                }
                break;
            case NodeKind::Assign: {
                Value val = frame_values[node.children[0]];
                frame_values[node.resolved_index] = val;
                result = val;
                break;
            }
            case NodeKind::ObjectLiteral: {
                auto obj = std::make_shared<Object>();
                for (size_t k = 0; k < node.children.size(); k += 2) {
                    Value keyV = frame_values[node.children[k]];
                    Value valV = frame_values[node.children[k+1]];
                    (*obj)[keyV.str_val] = valV;
                }
                result = Value::makeObject(obj);
                break;
            }
            case NodeKind::GetField: // Fallthrough
            case NodeKind::MemberAccess: {
                Value objV = frame_values[node.children[0]];
                if (objV.is_obj() && objV.obj_val->count(node.str_val)) {
                    result = (*objV.obj_val)[node.str_val];
                }
                break;
            }
            case NodeKind::SetField: {
                Value objV = frame_values[node.children[0]];
                Value valV = frame_values[node.children[1]];
                if (objV.is_obj()) {
                     (*objV.obj_val)[node.str_val] = valV;
                }
                result = valV;
                break;
            }
            case NodeKind::Lt: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : (lhs.is_float ? lhs.float_val : 0.0);
                double v2 = rhs.is_int ? rhs.int_val : (rhs.is_float ? rhs.float_val : 0.0);
                result = Value::makeInt((v1 < v2) ? 1 : 0);
                break;
            }
            case NodeKind::Gt: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : (lhs.is_float ? lhs.float_val : 0.0);
                double v2 = rhs.is_int ? rhs.int_val : (rhs.is_float ? rhs.float_val : 0.0);
                result = Value::makeInt((v1 > v2) ? 1 : 0);
                break;
            }
            case NodeKind::Add: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                if ((lhs.is_int || lhs.is_float) && (rhs.is_int || rhs.is_float)) {
                    if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 + v2);
                    } else {
                        result = Value::makeInt(lhs.int_val + rhs.int_val);
                    }
                } else {
                    std::string s1 = lhs.str_val;
                    if (lhs.is_int) s1 = std::to_string(lhs.int_val);
                    else if (lhs.is_float) {
                         s1 = std::to_string(lhs.float_val);
                         s1.erase ( s1.find_last_not_of('0') + 1, std::string::npos );
                         s1.erase ( s1.find_last_not_of('.') + 1, std::string::npos );
                    }
                    std::string s2 = rhs.str_val;
                    if (rhs.is_int) s2 = std::to_string(rhs.int_val);
                     else if (rhs.is_float) {
                         s2 = std::to_string(rhs.float_val);
                         s2.erase ( s2.find_last_not_of('0') + 1, std::string::npos );
                         s2.erase ( s2.find_last_not_of('.') + 1, std::string::npos );
                    }
                    result = Value::makeString(s1 + s2);
                }
                break;
            }
            case NodeKind::Sub: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                 if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 - v2);
                    } else {
                        result = Value::makeInt(lhs.int_val - rhs.int_val);
                    }
                break;
            }
            case NodeKind::Mul: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                 if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 * v2);
                    } else {
                        result = Value::makeInt(lhs.int_val * rhs.int_val);
                    }
                break;
            }
            case NodeKind::Div: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                if (v2 != 0) result = Value::makeFloat(v1 / v2);
                else result = Value::makeFloat(0.0);
                break;
            }
            case NodeKind::MakeClosure: {
                auto closure = std::make_shared<Closure>();
                closure->func_name = node.str_val;
                closure->env = frame_values; // Capture entire frame by value
                result = Value::makeClosure(closure);
                break;
            }
            case NodeKind::Call: {
                int funcRefIdx = node.children[0];
                bool isConsoleLog = false;
                if (nodes[funcRefIdx].kind == NodeKind::MemberAccess) {
                     int objIdx = nodes[funcRefIdx].children[0];
                     if (nodes[objIdx].kind == NodeKind::GlobalRef && nodes[objIdx].str_val == "console" && nodes[funcRefIdx].str_val == "log") {
                         isConsoleLog = true;
                     }
                }

                if (isConsoleLog) {
                     for (size_t k = 1; k < node.children.size(); ++k) {
                         Value v = frame_values[node.children[k]];
                         if (v.is_obj()) std::cout << "[object Object]" << std::endl;
                         else if (v.is_closure()) std::cout << "[function " << v.closure_val->func_name << "]" << std::endl;
                         else if (v.is_int) std::cout << v.int_val << std::endl;
                         else if (v.is_float) {
                             std::string s = std::to_string(v.float_val);
                             s.erase ( s.find_last_not_of('0') + 1, std::string::npos );
                             s.erase ( s.find_last_not_of('.') + 1, std::string::npos );
                             std::cout << s << std::endl;
                         }
                         else std::cout << v.str_val << std::endl;
                     }
                     result = Value::makeUndefined();
                     goto save_result;
                }

                std::string funcName;
                Value closureVal = Value::makeUndefined();

                // If it's a GlobalRef, check if it resolves to a function in 'functions' map
                // OR if it resolves to a variable holding a closure.

                // First evaluate funcRefIdx
                if (nodes[funcRefIdx].kind == NodeKind::GlobalRef) {
                    funcName = nodes[funcRefIdx].str_val;
                    // If functions has it, it's a top-level function.
                    // But wait, variable can shadow function.
                    // My parser treats GlobalRef as fallback.
                    // If 'functions' has it, run it.
                    if (functions.count(funcName)) {
                        // Regular function call
                        std::vector<Value> callArgs;
                        for (size_t k = 1; k < node.children.size(); ++k) {
                            callArgs.push_back(frame_values[node.children[k]]);
                        }
                        result = runFunction(funcName, callArgs);
                        goto save_result;
                    }
                }

                // Otherwise evaluate as expression
                closureVal = frame_values[funcRefIdx];
                // Wait, 'funcRefIdx' is an index into 'nodes'.
                // If it's a NameRef or expression, we should check 'frame_values'.
                // 'frame_values[funcRefIdx]' is the result of executing that node.
                // Has that node been executed?
                // Yes, if it's NameRef or something.
                // But Call node does NOT execute children except args.
                // Wait.
                // `parseCall` emits `Call(funcNodeIdx, args...)`.
                // `funcNodeIdx` is the expression for the function.
                // `VM` loop executes sequentially.
                // `Call` is encountered. Its children (funcNodeIdx) are previous nodes.
                // So `frame_values[funcRefIdx]` should contain the function value IF it was executed.
                // But if `funcNodeIdx` is GlobalRef, it might not be "executed" if it's just a reference.
                // My VM executes all nodes in order.
                // If `nodes[funcRefIdx]` is GlobalRef, it returns "undefined" (or nothing) if it's not a variable.
                // If it's a variable reference (NameRef), it returns the variable value.

                // If `closureVal` is undefined, check if we need to evaluate it?
                // No, VM loop already executed `funcRefIdx` node if it is before `Call` node.
                // Is it before?
                // `parseCallNode`: `args` parsed first. Then `emit(Call)`.
                // Where is `funcNodeIdx` emitted? Before `parseCallNode`.
                // So yes, it is before.
                // So `frame_values[funcRefIdx]` holds the function value.

                closureVal = frame_values[funcRefIdx];

                if (closureVal.is_closure()) {
                    auto closure = closureVal.closure_val;
                    std::vector<Value> callArgs;
                    for (size_t k = 1; k < node.children.size(); ++k) {
                        callArgs.push_back(frame_values[node.children[k]]);
                    }

                    if (!functions.count(closure->func_name)) throw std::runtime_error("Closure function not found: " + closure->func_name);
                    const Function& func = functions.at(closure->func_name);

                    // Execute closure
                    // Need to create new evaluator or call executeRange with environment merging
                    // We can reuse executeRange but we need to pass initial env.
                    // executeRange creates fresh frame_values.
                    // We need to support initializing it.

                    // Hack: Modify executeRange to accept initial env?
                    // Or create a method runClosure.
                    // runFunction calls executeRange.

                    // I will add a new method runClosure.
                    // But executeRange is part of Evaluator.

                    // Let's modify executeRange to take initial map.
                    // But it's complicated.
                    // Simplest: Create a new Evaluator instance?
                    // Evaluator holds `nodes`. `nodes` are shared.
                    // Evaluator has no state except recursion stack.

                    // I'll add `runClosure` to Evaluator.
                    result = runClosure(closure, callArgs);
                }
                break;
            }
            case NodeKind::Return: {
                return frame_values[node.children[0]];
            }
            case NodeKind::BrFalse: {
                Value cond = frame_values[node.children[0]];
                bool isTrue = false;
                if (cond.is_int) isTrue = (cond.int_val != 0);
                else if (cond.is_float) isTrue = (cond.float_val != 0.0);
                else isTrue = (!cond.str_val.empty());

                if (!isTrue) {
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
    return Value::makeUndefined();
}

Value Evaluator::runClosure(std::shared_ptr<Closure> closure, std::vector<Value> args) {
    if (!functions.count(closure->func_name)) throw std::runtime_error("Function not found: " + closure->func_name);
    const Function& func = functions.at(closure->func_name);

    // We need to execute range, but with initial env.
    // Copy env from closure
    std::map<int, Value> env = closure->env;

    // Assign args (override env if needed)
    // We need to know arg indices.
    // The function node range starts with Arg nodes.
    // So we can just run the loop over Arg nodes like in executeRange.
    // But executeRange uses local map.
    // So we should duplicate executeRange logic or make it accept env.

    // I'll make a private version of executeRange that takes env.
    return executeRangeWithEnv(func.start_node, func.end_node, args, env);
}

Value Evaluator::executeRangeWithEnv(int start, int end, const std::vector<Value>& args, std::map<int, Value> frame_values) {
    // This is same as executeRange but frame_values is passed in (by value to copy it).

    int arg_idx = 0;
    for (int i = start; i < end; ++i) {
        const Node& node = nodes[i];
        if (node.kind == NodeKind::Arg) {
            if (arg_idx < args.size()) frame_values[i] = args[arg_idx++];
            else frame_values[i] = Value::makeUndefined();
        }
    }

    // ... Copy loop body from executeRange ...
    // To avoid duplication, I will implement executeRange in terms of executeRangeWithEnv.

    int steps = 0;
    for (int ip = start; ip < end; ) {
        // ... same loop ...
        steps++;
        if (steps > 100000) throw std::runtime_error("Infinite loop detected");

        const Node& node = nodes[ip];
        Value result = Value::makeUndefined();
        int next_ip = ip + 1;

        switch (node.kind) {
            // ... all cases ...
            // Just copy paste the switch from above
            // This is ugly but fast.
            case NodeKind::IntLiteral: result = Value::makeInt(node.int_val); break;
            case NodeKind::FloatLiteral: result = Value::makeFloat(node.float_val); break;
            case NodeKind::StringLiteral: result = Value::makeString(node.str_val); break;
            case NodeKind::Arg: if (frame_values.count(ip)) result = frame_values[ip]; break;
            case NodeKind::Let: {
                if (!node.children.empty()) {
                    int childIdx = node.children[0];
                    if (frame_values.count(childIdx)) result = frame_values[childIdx];
                }
                break;
            }
            case NodeKind::NameRef: if (frame_values.count(node.resolved_index)) result = frame_values[node.resolved_index]; break;
            case NodeKind::Assign: {
                Value val = frame_values[node.children[0]];
                frame_values[node.resolved_index] = val;
                result = val;
                break;
            }
            case NodeKind::ObjectLiteral: {
                auto obj = std::make_shared<Object>();
                for (size_t k = 0; k < node.children.size(); k += 2) {
                    Value keyV = frame_values[node.children[k]];
                    Value valV = frame_values[node.children[k+1]];
                    (*obj)[keyV.str_val] = valV;
                }
                result = Value::makeObject(obj);
                break;
            }
            case NodeKind::GetField: case NodeKind::MemberAccess: {
                Value objV = frame_values[node.children[0]];
                if (objV.is_obj() && objV.obj_val->count(node.str_val)) result = (*objV.obj_val)[node.str_val];
                break;
            }
            case NodeKind::SetField: {
                Value objV = frame_values[node.children[0]];
                Value valV = frame_values[node.children[1]];
                if (objV.is_obj()) (*objV.obj_val)[node.str_val] = valV;
                result = valV;
                break;
            }
            case NodeKind::Lt: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : (lhs.is_float ? lhs.float_val : 0.0);
                double v2 = rhs.is_int ? rhs.int_val : (rhs.is_float ? rhs.float_val : 0.0);
                result = Value::makeInt((v1 < v2) ? 1 : 0);
                break;
            }
            case NodeKind::Gt: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : (lhs.is_float ? lhs.float_val : 0.0);
                double v2 = rhs.is_int ? rhs.int_val : (rhs.is_float ? rhs.float_val : 0.0);
                result = Value::makeInt((v1 > v2) ? 1 : 0);
                break;
            }
            case NodeKind::Add: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                if ((lhs.is_int || lhs.is_float) && (rhs.is_int || rhs.is_float)) {
                    if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 + v2);
                    } else {
                        result = Value::makeInt(lhs.int_val + rhs.int_val);
                    }
                } else {
                    std::string s1 = lhs.str_val;
                    if (lhs.is_int) s1 = std::to_string(lhs.int_val);
                    else if (lhs.is_float) {
                         s1 = std::to_string(lhs.float_val);
                         s1.erase ( s1.find_last_not_of('0') + 1, std::string::npos );
                         s1.erase ( s1.find_last_not_of('.') + 1, std::string::npos );
                    }
                    std::string s2 = rhs.str_val;
                    if (rhs.is_int) s2 = std::to_string(rhs.int_val);
                     else if (rhs.is_float) {
                         s2 = std::to_string(rhs.float_val);
                         s2.erase ( s2.find_last_not_of('0') + 1, std::string::npos );
                         s2.erase ( s2.find_last_not_of('.') + 1, std::string::npos );
                    }
                    result = Value::makeString(s1 + s2);
                }
                break;
            }
            case NodeKind::Sub: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                 if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 - v2);
                    } else {
                        result = Value::makeInt(lhs.int_val - rhs.int_val);
                    }
                break;
            }
            case NodeKind::Mul: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                 if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         result = Value::makeFloat(v1 * v2);
                    } else {
                        result = Value::makeInt(lhs.int_val * rhs.int_val);
                    }
                break;
            }
            case NodeKind::Div: {
                Value lhs = frame_values[node.children[0]];
                Value rhs = frame_values[node.children[1]];
                double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                if (v2 != 0) result = Value::makeFloat(v1 / v2);
                else result = Value::makeFloat(0.0);
                break;
            }
            case NodeKind::MakeClosure: {
                auto closure = std::make_shared<Closure>();
                closure->func_name = node.str_val;
                closure->env = frame_values; // Capture entire frame by value
                result = Value::makeClosure(closure);
                break;
            }
            case NodeKind::Call: {
                int funcRefIdx = node.children[0];
                bool isConsoleLog = false;
                if (nodes[funcRefIdx].kind == NodeKind::MemberAccess) {
                     int objIdx = nodes[funcRefIdx].children[0];
                     if (nodes[objIdx].kind == NodeKind::GlobalRef && nodes[objIdx].str_val == "console" && nodes[funcRefIdx].str_val == "log") {
                         isConsoleLog = true;
                     }
                }

                if (isConsoleLog) {
                     for (size_t k = 1; k < node.children.size(); ++k) {
                         Value v = frame_values[node.children[k]];
                         if (v.is_obj()) std::cout << "[object Object]" << std::endl;
                         else if (v.is_closure()) std::cout << "[function " << v.closure_val->func_name << "]" << std::endl;
                         else if (v.is_int) std::cout << v.int_val << std::endl;
                         else if (v.is_float) {
                             std::string s = std::to_string(v.float_val);
                             s.erase ( s.find_last_not_of('0') + 1, std::string::npos );
                             s.erase ( s.find_last_not_of('.') + 1, std::string::npos );
                             std::cout << s << std::endl;
                         }
                         else std::cout << v.str_val << std::endl;
                     }
                     result = Value::makeUndefined();
                     goto save_result;
                }

                std::string funcName;
                Value closureVal = Value::makeUndefined();

                if (nodes[funcRefIdx].kind == NodeKind::GlobalRef) {
                    funcName = nodes[funcRefIdx].str_val;
                    if (functions.count(funcName)) {
                        std::vector<Value> callArgs;
                        for (size_t k = 1; k < node.children.size(); ++k) {
                            callArgs.push_back(frame_values[node.children[k]]);
                        }
                        result = runFunction(funcName, callArgs);
                        goto save_result;
                    }
                }

                closureVal = frame_values[funcRefIdx];
                if (closureVal.is_closure()) {
                    auto closure = closureVal.closure_val;
                    std::vector<Value> callArgs;
                    for (size_t k = 1; k < node.children.size(); ++k) {
                        callArgs.push_back(frame_values[node.children[k]]);
                    }
                    result = runClosure(closure, callArgs);
                }
                break;
            }
            case NodeKind::Return: {
                return frame_values[node.children[0]];
            }
            case NodeKind::BrFalse: {
                Value cond = frame_values[node.children[0]];
                bool isTrue = false;
                if (cond.is_int) isTrue = (cond.int_val != 0);
                else if (cond.is_float) isTrue = (cond.float_val != 0.0);
                else isTrue = (!cond.str_val.empty());
                if (!isTrue) next_ip = node.target_index;
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
    return Value::makeUndefined();
}
