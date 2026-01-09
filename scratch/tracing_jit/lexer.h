#ifndef LEXER_H
#define LEXER_H

#include "token.h"
#include <string>

class Lexer {
    std::string src;
    size_t pos = 0;
    int line = 1;

public:
    Lexer(std::string s);
    Token next();

    struct State {
        size_t pos;
        int line;
    };
    State save() { return {pos, line}; }
    void restore(State s) { pos = s.pos; line = s.line; }
};

#endif // LEXER_H
