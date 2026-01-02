#pragma once
#include <string>

enum TokenType { T_LPAREN, T_RPAREN, T_STRING, T_NUMBER, T_KEYWORD, T_EOF };

struct Token {
    TokenType type;
    std::string text;
};
