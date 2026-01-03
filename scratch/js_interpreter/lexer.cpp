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

        if (c == '/' && pos + 1 < src.size() && src[pos+1] == '/') {
            while(pos < src.size() && src[pos] != '\n') pos++;
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
            if (text == "var") return {TOK_VAR, text, line};
            if (text == "let") return {TOK_LET, text, line};
            if (text == "const") return {TOK_CONST, text, line};
            if (text == "while") return {TOK_WHILE, text, line};
            if (text == "for") return {TOK_FOR, text, line};
            if (text == "new") return {TOK_NEW, text, line};
            return {TOK_IDENTIFIER, text, line};
        }
        if (isdigit(c)) {
            size_t start = pos;
            while (pos < src.size() && (isdigit(src[pos]) || src[pos] == '.')) pos++;
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
            case '+':
                if (pos < src.size() && src[pos] == '+') { pos++; return {TOK_INC, "++", line}; }
                return {TOK_PLUS, "+", line};
            case '-':
                if (pos < src.size() && src[pos] == '-') { pos++; return {TOK_DEC, "--", line}; }
                return {TOK_MINUS, "-", line};
            case '*': return {TOK_STAR, "*", line};
            case '/': return {TOK_SLASH, "/", line};
            case '=':
                if (pos < src.size() && src[pos] == '>') {
                    pos++;
                    return {TOK_ARROW, "=>", line};
                }
                return {TOK_ASSIGN, "=", line};
            case '(': return {TOK_LPAREN, "(", line};
            case ')': return {TOK_RPAREN, ")", line};
            case '{': return {TOK_LBRACE, "{", line};
            case '}': return {TOK_RBRACE, "}", line};
            case '[': return {TOK_LBRACKET, "[", line};
            case ']': return {TOK_RBRACKET, "]", line};
            case ',': return {TOK_COMMA, ",", line};
            case '.': return {TOK_DOT, ".", line};
            case ':': return {TOK_COLON, ":", line};
            case ';': return {TOK_SEMICOLON, ";", line};
            case '<': return {TOK_LT, "<", line};
            case '>': return {TOK_GT, ">", line};
        }
        throw std::runtime_error("Unexpected char: " + std::string(1, c));
    }
    return {TOK_EOF, "", line};
}
