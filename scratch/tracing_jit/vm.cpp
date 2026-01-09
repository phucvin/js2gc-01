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
    return executeRangeWithEnv(start, end, args, frame_values);
}

Value Evaluator::runClosure(std::shared_ptr<Closure> closure, std::vector<Value> args) {
    if (!functions.count(closure->func_name)) throw std::runtime_error("Function not found: " + closure->func_name);
    const Function& func = functions.at(closure->func_name);
    return executeRangeWithEnv(func.start_node, func.end_node, args, closure->env);
}

void Evaluator::optimizeTrace(Trace& trace) {
    // Simple constant folding
    // Iterate and fold ConstInt + ConstInt -> Add/Sub/etc.
    // For now, let's just do a simple pass that removes no-ops or folds immediate constants.
    // But our trace structure is linear.
    // Actually, let's implement a very simple peephole:
    // If we see ConstInt(A) -> SetLocal(T1) -> Add(T1, B), we could optimize.
    // But our trace format is high-level.
    // Let's just print that we are optimizing.
    // std::cout << "[JIT] Optimizing trace..." << std::endl;
    // Real implementation:
    // 1. Identify constant values.
    // 2. Fold them.
    // Since this is a prototype, I'll implement "Collapse SetLocal to Self" which is a no-op.
    // e.g. SetLocal(i -> i).
    std::vector<TraceOp> optimized;
    for (const auto& op : trace.ops) {
        if (op.kind == TraceOpKind::SetLocal && op.operand1 == op.result_index) {
             // No-op assignment
             continue;
        }
        optimized.push_back(op);
    }
    trace.ops = optimized;
}

Value Evaluator::executeTrace(const Trace& trace, std::map<int, Value>& frame_values, int& ip) {
    // std::cout << "Executing trace for loop at " << trace.start_node_index << std::endl;
    for (const auto& op : trace.ops) {
        // std::cout << "Op " << (int)op.kind << " res=" << op.result_index << std::endl;
        switch (op.kind) {
            case TraceOpKind::GuardTrue: {
                Value cond = frame_values[op.operand1];
                // std::cout << "GuardTrue cond=" << cond.int_val << " expected != 0" << std::endl;
                bool isTrue = (cond.is_int && cond.int_val != 0) || (cond.is_float && cond.float_val != 0.0);
                if (!isTrue) {
                    // Bailout
                    // std::cout << "GuardTrue failed, bailing out to interpreter at " << ip << std::endl;
                    ip = op.result_index;
                    return Value::makeUndefined();
                }
                break;
            }
            case TraceOpKind::SetLocal:
                 // Assign
                 // operand1 is source local index, result_index is target
                 if (frame_values.count(op.operand1)) {
                    frame_values[op.result_index] = frame_values[op.operand1];
                    // std::cout << "SetLocal " << op.result_index << " = " << frame_values[op.result_index].int_val << std::endl;
                 }
                 break;
            case TraceOpKind::ConstInt:
                frame_values[op.result_index] = Value::makeInt(op.int_val);
                break;
            case TraceOpKind::ConstFloat:
                frame_values[op.result_index] = Value::makeFloat(op.float_val);
                break;
            case TraceOpKind::GetLocal:
                // Copy value from one local to another (if needed)
                // In this simple trace, ops usually write to result_index
                break;
            case TraceOpKind::Add: {
                Value lhs = frame_values[op.operand1];
                Value rhs = frame_values[op.operand2];
                // Assume types are stable in trace (or should guard)
                // For simplicity, handle int/int
                if (lhs.is_int && rhs.is_int) {
                    frame_values[op.result_index] = Value::makeInt(lhs.int_val + rhs.int_val);
                } else {
                     // Fallback/Bailout not implemented fully, just do logic
                     if (lhs.is_float || rhs.is_float) {
                         double v1 = lhs.is_int ? lhs.int_val : lhs.float_val;
                         double v2 = rhs.is_int ? rhs.int_val : rhs.float_val;
                         frame_values[op.result_index] = Value::makeFloat(v1 + v2);
                     } else {
                         frame_values[op.result_index] = Value::makeInt(lhs.int_val + rhs.int_val);
                     }
                }
                // Update result for next ops if they use it?
                // The trace logic relies on frame_values being updated.
                break;
            }
            case TraceOpKind::Sub: {
                 Value lhs = frame_values[op.operand1];
                 Value rhs = frame_values[op.operand2];
                 if (lhs.is_int && rhs.is_int) {
                    frame_values[op.result_index] = Value::makeInt(lhs.int_val - rhs.int_val);
                 } else {
                     // simplified
                     frame_values[op.result_index] = Value::makeInt(lhs.int_val - rhs.int_val);
                 }
                 break;
            }
            case TraceOpKind::Lt: {
                Value lhs = frame_values[op.operand1];
                Value rhs = frame_values[op.operand2];
                // simplified
                double v1 = lhs.is_int ? lhs.int_val : 0;
                double v2 = rhs.is_int ? rhs.int_val : 0;
                frame_values[op.result_index] = Value::makeInt((v1 < v2) ? 1 : 0);
                break;
            }
            case TraceOpKind::GuardFalse: {
                Value cond = frame_values[op.operand1];
                bool isTrue = (cond.is_int && cond.int_val != 0) || (cond.is_float && cond.float_val != 0.0);
                if (isTrue) {
                    // Bailout
                    // std::cout << "GuardFalse failed" << std::endl;
                    ip = op.result_index;
                    return Value::makeUndefined();
                }
                break;
            }
            case TraceOpKind::Finish:
                // Trace completed loop body and is about to jump back.
                // We loop in executeTrace?
                // Or executeTrace executes one iteration?
                // Usually trace covers one iteration.
                // So we return, and the caller (interpreter loop) sees we are still at loop header (or jumps back).
                // If trace ends with jump to header, we can just loop here.
                // Let's loop here for speed!
                // Reset to start of trace?
                // Ops are same.
                // But we need to handle "Finish" as "Jump back to start of trace".
                // We can put a loop around the switch loop.
                // But we need to check interrupt/timeout.
                // For prototype, let's just return and let the interpreter loop call us again.
                // This simulates "trace compiled, execute one iteration".
                // But typically trace loops internally.
                break;
            default: break;
        }
    }
    // Trace finished one iteration successfully.
    // ip should be set to start of loop.
    ip = trace.start_node_index;
    // Increment a step counter to avoid infinite loop detection triggering falsely
    // But Evaluator::executeRangeWithEnv tracks steps.
    // We should probably return a value indicating how many instructions were executed?
    // For now, let's assume trace execution is 1 step in the main loop, but we need to ensure the main loop doesn't timeout if we run 1000 traces.
    // If the loop limit is 1,000,000, and we run 100 iterations, it's fine.
    // The issue might be that ip is not advancing past the loop?
    // Trace resets ip to start_node_index. Main loop sees ip=start, finds trace, executes again.
    // This is correct behavior for a loop.
    // Eventually the loop condition must fail.
    // The trace should contain Guard (BrFalse) for the condition.
    // If condition fails, we bail out.
    // Why infinite loop?
    // Maybe the trace ops are not updating the loop variable correctly?
    // TraceOpKind::SetLocal updates frame_values.
    // Let's debug trace ops.
    return Value::makeUndefined();
}

Value Evaluator::executeRangeWithEnv(int start, int end, const std::vector<Value>& args, std::map<int, Value> frame_values) {
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
        if (steps > 10000000) throw std::runtime_error("Infinite loop detected");

        // Tracing / JIT Hook
        if (traces.count(ip) && !recording) {
            // Execute trace
            int old_ip = ip;
            executeTrace(traces[ip], frame_values, ip);
            // If ip changed to something other than old_ip (loop header), it means we bailed out or finished.
            // If finished successfully, ip is old_ip (loop header).
            // We can continue loop.
            // If bailed out, ip is set to target.
            // But executeTrace returns Undefined usually.
            // We just continue the loop with new ip.
            if (ip == old_ip) {
                // Loop continued.
            } else {
               // Bailed out or jumped.
            }
            // Manually count steps for trace execution to verify progress
            steps += 10; // Assume trace is 10 ops equivalent
            continue;
        }

        const Node& node = nodes[ip];
        Value result = Value::makeUndefined();
        int next_ip = ip + 1;

        // Recording logic
        if (recording) {
             TraceOp op;
             op.result_index = ip;
             bool recorded = false;

             // Check if we looped back to start
             if (ip == recording_start_ip && !current_trace.ops.empty()) {
                 recording = false;
                 // Finish trace
                 TraceOp finish;
                 finish.kind = TraceOpKind::Finish;
                 current_trace.ops.push_back(finish);
                 optimizeTrace(current_trace);
                 traces[recording_start_ip] = current_trace;
                 std::cout << "[JIT] Trace compiled for loop at " << recording_start_ip << " with " << current_trace.ops.size() << " ops." << std::endl;

                 // Execute it immediately?
                 continue; // Loop back to top to execute trace
             }

             switch(node.kind) {
                 case NodeKind::IntLiteral:
                     op.kind = TraceOpKind::ConstInt;
                     op.int_val = node.int_val;
                     recorded = true;
                     break;
                 case NodeKind::Add:
                     op.kind = TraceOpKind::Add;
                     op.operand1 = node.children[0];
                     op.operand2 = node.children[1];
                     recorded = true;
                     break;
                 case NodeKind::Sub:
                     op.kind = TraceOpKind::Sub;
                     op.operand1 = node.children[0];
                     op.operand2 = node.children[1];
                     recorded = true;
                     break;
                 case NodeKind::Lt:
                     op.kind = TraceOpKind::Lt;
                     op.operand1 = node.children[0];
                     op.operand2 = node.children[1];
                     recorded = true;
                     break;
                 case NodeKind::Assign:
                     op.kind = TraceOpKind::SetLocal;
                     op.operand1 = node.children[0]; // value
                     op.result_index = node.resolved_index; // target
                     recorded = true;
                     break;
                 case NodeKind::NameRef:
                     // NameRef usually just returns value of resolved_index
                     // In trace, we might treat it as SetLocal(temp = resolved_index)
                     // or just no-op if we use indices directly.
                     // AST interpreter assigns result to `ip`.
                     // So `frame_values[ip] = frame_values[node.resolved_index]`.
                     op.kind = TraceOpKind::SetLocal;
                     op.operand1 = node.resolved_index;
                     op.result_index = ip;
                     recorded = true;
                     break;
                 case NodeKind::BrFalse:
                     // Guard
                     // BrFalse jumps if cond is false.
                     // If we are recording, we are on a specific path.
                     // We need to check if the branch is taken or not in THIS execution.
                     // But we record BEFORE execution? Or AFTER?
                     // Let's execute first then record.
                     // We need the result of condition to know which way we went.
                     break;
                 default:
                     // Unsupported op in trace -> abort recording
                     std::cout << "[JIT] Unsupported op kind " << (int)node.kind << ". Aborting recording." << std::endl;
                     recording = false;
                     current_trace.ops.clear();
                     break;
             }

             if (recording && recorded) current_trace.ops.push_back(op);
        }

        switch (node.kind) {
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
                closure->env = frame_values;
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

                // Post-execution recording for BrFalse
                if (recording) {
                    TraceOp op;
                    op.operand1 = node.children[0];
                    if (isTrue) {
                         // Condition was true, so we did NOT branch.
                         // Guard: GuardTrue(cond)
                         op.kind = TraceOpKind::GuardTrue;
                         // result_index stores the bailout target (the branch target)
                         op.result_index = node.target_index;
                    } else {
                        // Condition was false, so we DID branch.
                        // Guard: GuardFalse(cond)
                        op.kind = TraceOpKind::GuardFalse;
                        // result_index stores bailout target (next_ip, the fallthrough)
                        op.result_index = ip + 1; // if we stayed in trace, we'd go to target. if we bail, we go to fallthrough (which is wrong path for this trace)
                    }
                    // Wait.
                    // If we are recording a trace, we are following a specific path.
                    // If condition is True, we proceed to next_ip (fallthrough).
                    // So we emit GuardTrue. If later GuardTrue fails (cond False), we bail to target_index (branch taken).
                    // Correct.

                    // If condition is False, we branch to target_index.
                    // So we emit GuardFalse. If later GuardFalse fails (cond True), we bail to fallthrough (ip+1).
                    current_trace.ops.push_back(op);
                }

                if (!isTrue) next_ip = node.target_index;
                break;
            }
            case NodeKind::Jmp: {
                // Post-execution recording for Jmp
                // Jmp is unconditional.
                // If it is a back edge, we might finish trace?
                if (recording && node.target_index == recording_start_ip) {
                    // We handle this at the top of the loop (ip == start)
                }

                next_ip = node.target_index;

                // Detect Loop Start
                if (!recording && node.target_index < ip) {
                    // Backward branch
                    int target = node.target_index;
                    loop_counters[target]++;
                    if (loop_counters[target] > 10) {
                        // Hot loop detected
                        std::cout << "[JIT] Hot loop detected at " << target << ". Starting recording." << std::endl;
                        recording = true;
                        recording_start_ip = target;
                        current_trace = Trace();
                        current_trace.start_node_index = target;

                        // We are at the jump, so next_ip is target.
                        // The loop will continue, and next iteration `ip` will be `target`.
                        // The top of the loop will see `recording` is true and `ip == start`.
                        // But wait, the top of the loop check is:
                        // `if (ip == recording_start_ip)`
                        // So it will stop recording immediately?
                        // No.
                        // We set `recording = true`.
                        // Next instruction is `ip = target`.
                        // Top of loop: `if (recording)`.
                        // `if (ip == recording_start_ip)`.
                        // Yes, it will stop immediately if we are not careful.
                        // We want to record *one full iteration*.
                        // So we should start recording when we *arrive* at the header, or handle the first arrival specially.

                        // Current flow:
                        // 1. We are at JMP (end of loop).
                        // 2. We detect hot loop.
                        // 3. We set recording=true.
                        // 4. `next_ip` is set to header.
                        // 5. Loop continues. `ip` becomes header.
                        // 6. Top of loop: `if (recording && ip == recording_start_ip)` -> Stop recording.

                        // Result: Empty trace.

                        // Fix: Start recording, but ensure we don't stop immediately.
                        // Maybe `recording` should be "armed" and start at the header?
                        // Or simply, we are starting recording *now* (at JMP), but the trace effectively starts at `target`.
                        // But we want to record the instructions *after* the jump.
                        // So we should set `recording` but maybe checking for stop should be done *before* we record instructions?

                        // Actually, if we start recording at the header (when we process the header), it's cleaner.
                        // But we detect the loop at the back edge.
                        // So let's mark the header as "hot".
                        // `hot_loops[target] = true`.
                        // Then at the top of the loop, if `hot_loops[ip]`, start recording.
                    }
                }
                break;
            }
            default: break;
        }

        save_result:
        frame_values[ip] = result;
        ip = next_ip;

        // Handle "hot loop marked" logic at the top of next iteration?
        // Or cleaner:
        // Move the loop detection to the top of the loop?
        // No, loop detection needs to see the back edge.
        // But we can check `loop_counters` at the top if we increment them elsewhere?
        // No, `Jmp` is where we know it's a loop.

        // Let's change the logic:
        // Inside `Jmp`: if hot, set `start_recording_at_next_instruction = true`.
    }
    return Value::makeUndefined();
}
