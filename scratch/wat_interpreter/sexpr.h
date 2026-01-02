#pragma once
#include <string>
#include <vector>

struct SExpr {
    bool is_list = false;
    std::string value;
    std::vector<SExpr> children;
};
