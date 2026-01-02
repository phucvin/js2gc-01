#pragma once
#include <string>
#include "token.h"

class Lexer {
    std::string src;
    size_t pos = 0;
public:
    Lexer(std::string s);
    Token next();
};
