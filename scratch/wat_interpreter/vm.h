#pragma once
#include <vector>
#include <map>
#include <string>
#include "ir.h"
#include "runtime_value.h"

class VM {
    const std::vector<Instr>& instrs;
    const std::map<std::string, Function>& functions;
    std::vector<HeapObject> heap;
    std::map<std::string, RuntimeValue> globals;

public:
    VM(const std::vector<Instr>& i, const std::map<std::string, Function>& f, const std::map<std::string, GlobalDef>& g);
    RuntimeValue run(std::string entry, std::vector<RuntimeValue> args);
    RuntimeValue exec(int start, int end, std::vector<RuntimeValue> args);
    RuntimeValue execInstrs(const std::vector<Instr>& code);
};
