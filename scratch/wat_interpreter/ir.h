#pragma once
#include <string>
#include <vector>
#include <map>

enum class Op {
    ConstI32, ConstF64, ConstString,
    AddI32, AddF64, EqI32, AndI32,
    LocalGet, LocalSet, GlobalGet,
    Call, CallRef,
    StructNew, StructGet, StructSet,
    RefI31, I31GetS, RefCast, RefTest, RefNull, RefIsNull, RefFunc, RefAsNonNull,
    BrFalse, Jmp, Return,
    Nop
};

struct Instr {
    Op op = Op::Nop;
    int int_imm = 0;
    double float_imm = 0;
    std::string str_imm;
    std::vector<int> children; // Operand indices (Indexed RPN)
    int target = -1; // Branch target
};

struct Function {
    std::string name;
    std::vector<std::string> params;
    std::vector<std::string> locals;
    int start_node = 0;
    int end_node = 0;
};

struct TypeDef {
    std::string name;
    std::string kind;
    std::vector<std::string> fields;
    std::map<std::string, int> field_map;
};

struct GlobalDef {
    std::string name;
    std::string type;
    std::vector<Instr> init_instrs;
};
