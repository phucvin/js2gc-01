#pragma once
#include <vector>
#include <map>
#include <string>
#include "ir.h"
#include "sexpr.h"

struct BlockScope {
    std::string label;
    int start_instr; // For loops, this is the jump target
    bool is_loop;
    std::vector<int> patches; // Instructions (br/br_if) needing patching to end of block
};

class Compiler {
    std::vector<Instr> instrs;
    std::map<std::string, Function> functions;
    std::map<std::string, TypeDef> types;
    std::map<std::string, GlobalDef> globals;

    std::vector<int> stack;
    std::map<std::string, int> local_map;
    std::vector<BlockScope> control_stack;

    std::string getTypeName(const SExpr& e);

public:
    const std::vector<Instr>& getInstrs() const { return instrs; }
    const std::map<std::string, Function>& getFunctions() const { return functions; }
    const std::map<std::string, TypeDef>& getTypes() const { return types; }
    const std::map<std::string, GlobalDef>& getGlobals() const { return globals; }

    int emit(Instr i);
    void compileModule(const SExpr& module);
    void parseType(const SExpr& t);
    void parseGlobal(const SExpr& g);
    void parseFuncSig(const SExpr& f);
    void compileFunc(const SExpr& f);
    void compileExpr(const SExpr& e);
    void handleIf(const SExpr& e);
    void handleBlock(const SExpr& e, bool is_loop);
};
