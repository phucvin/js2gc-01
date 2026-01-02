#ifndef VM_H
#define VM_H

#include <vector>
#include <map>
#include <string>
#include "node.h"
#include "value.h"

class Evaluator {
    const std::vector<Node>& nodes;
    const std::map<std::string, Function>& functions;

public:
    Evaluator(const std::vector<Node>& n, const std::map<std::string, Function>& f);

    Value runFunction(std::string name, std::vector<Value> args);
    Value executeRange(int start, int end, const std::vector<Value>& args);
};

#endif // VM_H
