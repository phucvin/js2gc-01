#pragma once
#include <string>
#include "lexer.h"
#include "sexpr.h"

class SParser {
    Lexer lexer;
    Token current;
    void advance();
public:
    SParser(std::string src);
    SExpr parse();
};
