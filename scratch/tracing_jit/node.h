#ifndef NODE_H
#define NODE_H

#include <string>
#include <vector>

enum class NodeKind {
    IntLiteral,
    FloatLiteral,
    StringLiteral,
    Arg,
    NameRef,
    Add,
    Sub,
    Mul,
    Div,
    Lt,
    Gt,
    Call,
    Return,
    GlobalRef,
    MemberAccess,
    Assign,
    Let,
    ObjectLiteral,
    GetField,
    SetField,
    BrFalse,
    Jmp,
    Loop,
    For,
    MakeClosure, // New
    None
};

struct Node {
    NodeKind kind = NodeKind::None;
    int int_val = 0;
    double float_val = 0.0;
    std::string str_val;
    std::vector<int> children;
    int resolved_index = -1;
    int target_index = -1;
};

struct Function {
    std::string name;
    std::vector<std::string> args;
    int start_node;
    int end_node;
};

#endif // NODE_H
