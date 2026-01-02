#include "lexer.h"
#include <cctype>

Lexer::Lexer(std::string s) : src(s) {}

Token Lexer::next() {
    while (pos < src.size()) {
        char c = src[pos];
        if (isspace(c)) { pos++; continue; }
        if (c == ';') { // Comment
            while (pos < src.size() && src[pos] != '\n') pos++;
            continue;
        }
        if (c == '(') { pos++; return {T_LPAREN, "("}; }
        if (c == ')') { pos++; return {T_RPAREN, ")"}; }
        if (c == '"') {
            pos++;
            size_t start = pos;
            while (pos < src.size() && src[pos] != '"') {
                if (src[pos] == '\\') pos++; // skip escape
                pos++;
            }
            std::string s = src.substr(start, pos - start);
            pos++;
            return {T_STRING, s};
        }
        // Atom
        size_t start = pos;
        while (pos < src.size() && !isspace(src[pos]) && src[pos] != '(' && src[pos] != ')' && src[pos] != ';') {
            pos++;
        }
        std::string text = src.substr(start, pos - start);

        // Heuristic for number vs keyword
        bool isNum = true;
        if (text.empty()) isNum = false;
        else {
            size_t i = 0;
            if (text[i] == '-' || text[i] == '+') i++;
            if (i >= text.size()) isNum = false;
            else {
                 // Check for hex or float
                 // minimal check
                if (!isdigit(text[i]) && text[i] != '.') isNum = false;
            }
        }
        // Also explicitly handle hex 0x...
        if (text.size() > 2 && text[0] == '0' && text[1] == 'x') isNum = true;

        if (isNum) return {T_NUMBER, text};
        return {T_KEYWORD, text};
    }
    return {T_EOF, ""};
}
