#ifndef VM_H
#define VM_H

#include "node.h"
#include "value.h"
#include <vector>
#include <map>
#include <string>

class Evaluator {
    std::vector<Node> nodes;
    std::map<std::string, Function> functions;

public:
    Evaluator(const std::vector<Node>& n, const std::map<std::string, Function>& f);
    Value runFunction(std::string name, std::vector<Value> args);
    Value executeRange(int start, int end, const std::vector<Value>& args);
    Value executeRangeWithEnv(int start, int end, const std::vector<Value>& args, std::map<int, Value> frame_values);
    Value runClosure(std::shared_ptr<Closure> closure, std::vector<Value> args);
};

#endif // VM_H
