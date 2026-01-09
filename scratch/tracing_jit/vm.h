#ifndef VM_H
#define VM_H

#include "node.h"
#include "value.h"
#include <vector>
#include <map>
#include <string>
#include <memory>

enum class TraceOpKind {
    ConstInt,
    ConstFloat,
    GetLocal,
    SetLocal,
    Add,
    Sub,
    Mul,
    Div,
    Lt,
    Gt,
    GuardTrue,
    GuardFalse,
    Finish // Exit trace
};

struct TraceOp {
    TraceOpKind kind;
    int operand1; // Can be local index, or index into constants
    int operand2;
    int result_index; // Where to store result (local index)
    // For constants
    int int_val;
    double float_val;
};

struct Trace {
    std::vector<TraceOp> ops;
    int start_node_index;
};

class Evaluator {
    std::vector<Node> nodes;
    std::map<std::string, Function> functions;

    // Tracing state
    std::map<int, int> loop_counters;
    std::map<int, Trace> traces;
    bool recording = false;
    Trace current_trace;
    int recording_start_ip = -1;

public:
    Evaluator(const std::vector<Node>& n, const std::map<std::string, Function>& f);
    Value runFunction(std::string name, std::vector<Value> args);
    Value executeRange(int start, int end, const std::vector<Value>& args);
    Value executeRangeWithEnv(int start, int end, const std::vector<Value>& args, std::map<int, Value> frame_values);
    Value runClosure(std::shared_ptr<Closure> closure, std::vector<Value> args);

    Value executeTrace(const Trace& trace, std::map<int, Value>& frame_values, int& ip);
    void optimizeTrace(Trace& trace);
};

#endif // VM_H
