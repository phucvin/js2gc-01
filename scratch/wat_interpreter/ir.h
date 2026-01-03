#pragma once
#include <string>
#include <vector>
#include <map>

enum class Op {
    ConstI32, ConstF64, ConstString,
    AddI32, SubI32, MulI32, DivI32,
    AddF64, SubF64, MulF64, DivF64,
    EqI32, NeI32, LtI32, GtI32, LeI32, GeI32,
    EqF64, NeF64, LtF64, GtF64, LeF64, GeF64,
    AndI32, OrI32, XorI32,
    EqzI32,
    ConvertI32ToF64,
    LocalGet, LocalSet, GlobalGet,
    Call, CallRef,
    StructNew, StructGet, StructSet,
    ArrayNew, ArrayNewDefault, ArrayGet, ArraySet, ArrayLen, ArrayCopy,
    RefI31, I31GetS, RefCast, RefTest, RefNull, RefIsNull, RefFunc, RefAsNonNull,
    BrFalse, BrTrue, Jmp, Return,
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
