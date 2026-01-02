#ifndef LEXER_H
#define LEXER_H

#include <string>
#include "token.h"

class Lexer {
    std::string src;
    size_t pos = 0;
    int line = 1;
public:
    Lexer(std::string s);
    Token next();
};

#endif // LEXER_H
