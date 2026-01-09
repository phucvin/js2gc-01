#ifndef PARSER_H
#define PARSER_H

#include <string>
#include <vector>
#include <map>
#include "lexer.h"
#include "node.h"

class Parser {
    Lexer lexer;
    Token current;
    std::vector<Node> nodes;
    std::map<std::string, Function> functions;
    std::vector<std::map<std::string, int>> scope_stack;

    void advance();
    void eat(TokenType t);
    int emit(Node n);
    int resolve(std::string name);
    int parseExpression();
    int parseAssignment();
    int parseRelational();
    int parseAddSub();
    int parseMulDiv();
    int parsePrimary();
    int parseArrowFunction(); // New declaration
    int parseObjectLiteral();
    int parseCall(std::string name);
    int parseCallNode(int funcNodeIdx);
    void parseBlock();
    void parseStatement();
    void parseFunction();

public:
    Parser(std::string src);
    void parse();
    const std::vector<Node>& getNodes() const { return nodes; }
    const std::map<std::string, Function>& getFunctions() const { return functions; }
};

#endif // PARSER_H
