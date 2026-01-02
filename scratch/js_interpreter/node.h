#ifndef NODE_H
#define NODE_H

#include <string>
#include <vector>

enum class NodeKind {
    IntLiteral,
    StringLiteral,
    Arg,
    NameRef,
    Add,
    Call,
    Return,
    GlobalRef,
    MemberAccess,
    BrFalse,
    Jmp,
    None
};

struct Node {
    NodeKind kind = NodeKind::None;
    int int_val = 0;
    std::string str_val;
    std::vector<int> children; // indices
    int resolved_index = -1; // For NameRef
    int target_index = -1; // For BrFalse/Jmp
};

struct Function {
    std::string name;
    std::vector<std::string> args;
    int start_node;
    int end_node;
};

#endif // NODE_H
