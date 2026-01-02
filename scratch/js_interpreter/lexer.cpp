#include "lexer.h"
#include <cctype>
#include <stdexcept>

Lexer::Lexer(std::string s) : src(s) {}

Token Lexer::next() {
    while (pos < src.size()) {
        char c = src[pos];
        if (isspace(c)) {
            if (c == '\n') line++;
            pos++;
            continue;
        }
        if (isalpha(c)) {
            size_t start = pos;
            while (pos < src.size() && (isalnum(src[pos]) || src[pos] == '_')) pos++;
            std::string text = src.substr(start, pos - start);
            if (text == "function") return {TOK_FUNCTION, text, line};
            if (text == "return") return {TOK_RETURN, text, line};
            if (text == "export") return {TOK_EXPORT, text, line};
            if (text == "if") return {TOK_IF, text, line};
            if (text == "else") return {TOK_ELSE, text, line};
            return {TOK_IDENTIFIER, text, line};
        }
        if (isdigit(c)) {
            size_t start = pos;
            while (pos < src.size() && isdigit(src[pos])) pos++;
            return {TOK_NUMBER, src.substr(start, pos - start), line};
        }
        if (c == '"') {
            pos++;
            size_t start = pos;
            while (pos < src.size() && src[pos] != '"') pos++;
            std::string text = src.substr(start, pos - start);
            pos++;
            return {TOK_STRING, text, line};
        }
        pos++;
        switch (c) {
            case '+': return {TOK_PLUS, "+", line};
            case '(': return {TOK_LPAREN, "(", line};
            case ')': return {TOK_RPAREN, ")", line};
            case '{': return {TOK_LBRACE, "{", line};
            case '}': return {TOK_RBRACE, "}", line};
            case ',': return {TOK_COMMA, ",", line};
            case '.': return {TOK_DOT, ".", line};
            case ';': return {TOK_SEMICOLON, ";", line};
        }
        throw std::runtime_error("Unexpected char: " + std::string(1, c));
    }
    return {TOK_EOF, "", line};
}
