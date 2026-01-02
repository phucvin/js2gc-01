#include "sparser.h"

void SParser::advance() { current = lexer.next(); }

SParser::SParser(std::string src) : lexer(src) { advance(); }

SExpr SParser::parse() {
    if (current.type == T_LPAREN) {
        advance();
        SExpr list;
        list.is_list = true;
        while (current.type != T_RPAREN && current.type != T_EOF) {
            list.children.push_back(parse());
        }
        if (current.type == T_RPAREN) advance();
        return list;
    } else if (current.type == T_EOF) {
            return {false, "", {}};
    } else {
        std::string val = current.text;
        advance();
        return {false, val, {}};
    }
}
