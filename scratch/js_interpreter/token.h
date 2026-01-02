#ifndef TOKEN_H
#define TOKEN_H

#include <string>

enum TokenType {
    TOK_FUNCTION, TOK_RETURN, TOK_EXPORT, TOK_VAR, TOK_LET, TOK_IF, TOK_ELSE,
    TOK_IDENTIFIER, TOK_NUMBER, TOK_STRING,
    TOK_PLUS, TOK_LPAREN, TOK_RPAREN, TOK_LBRACE, TOK_RBRACE,
    TOK_COMMA, TOK_DOT, TOK_SEMICOLON, TOK_EOF
};

struct Token {
    TokenType type;
    std::string text;
    int line;
};

#endif // TOKEN_H
