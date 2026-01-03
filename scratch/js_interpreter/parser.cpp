#include "parser.h"
#include <stdexcept>
#include <iostream>

Parser::Parser(std::string src) : lexer(src) { advance(); }

void Parser::advance() { current = lexer.next(); }

void Parser::eat(TokenType t) {
    if (current.type == t) advance();
    else throw std::runtime_error("Expected token type " + std::to_string(t) + " got " + std::to_string(current.type) + " " + current.text + " at line " + std::to_string(current.line));
}

int Parser::emit(Node n) {
    nodes.push_back(n);
    return nodes.size() - 1;
}

int Parser::resolve(std::string name) {
    for (int i = scope_stack.size() - 1; i >= 0; i--) {
        if (scope_stack[i].count(name)) return scope_stack[i][name];
    }
    Node n;
    n.kind = NodeKind::GlobalRef;
    n.str_val = name;
    return emit(n);
}

// Precedence parsing
int Parser::parseExpression() {
    return parseAssignment();
}

int Parser::parseAssignment() {
    int lhs = parseRelational();
    if (current.type == TOK_ASSIGN) {
        advance();
        int rhs = parseAssignment();

        NodeKind lhsKind = nodes[lhs].kind;
        int lhsResolvedIndex = nodes[lhs].resolved_index;
        std::string lhsStrVal = nodes[lhs].str_val;
        int lhsChild0 = (!nodes[lhs].children.empty()) ? nodes[lhs].children[0] : -1;

        if (lhsKind == NodeKind::NameRef) {
             Node n; n.kind = NodeKind::Assign;
             n.resolved_index = lhsResolvedIndex;
             n.children = {rhs};
             return emit(n);
        } else if (lhsKind == NodeKind::MemberAccess) {
             Node n; n.kind = NodeKind::SetField;
             n.str_val = lhsStrVal;
             n.children = {lhsChild0, rhs};
             return emit(n);
        } else if (lhsKind == NodeKind::GetField) {
             Node n; n.kind = NodeKind::SetField;
             n.str_val = lhsStrVal;
             n.children = {lhsChild0, rhs};
             return emit(n);
        }
        throw std::runtime_error("Invalid assignment target");
    }
    return lhs;
}

int Parser::parseRelational() {
    int lhs = parseAddSub();
    while (current.type == TOK_LT || current.type == TOK_GT) {
        TokenType op = current.type;
        advance();
        int rhs = parseAddSub();
        Node n;
        n.kind = (op == TOK_LT) ? NodeKind::Lt : NodeKind::Gt;
        n.children = {lhs, rhs};
        lhs = emit(n);
    }
    return lhs;
}

int Parser::parseAddSub() {
    int lhs = parseMulDiv();
    while (current.type == TOK_PLUS || current.type == TOK_MINUS) {
        TokenType op = current.type;
        advance();
        int rhs = parseMulDiv();
        Node n;
        n.kind = (op == TOK_PLUS) ? NodeKind::Add : NodeKind::Sub;
        n.children = {lhs, rhs};
        lhs = emit(n);
    }
    return lhs;
}

int Parser::parseMulDiv() {
    int lhs = parsePrimary();
    while (current.type == TOK_STAR || current.type == TOK_SLASH) {
        TokenType op = current.type;
        advance();
        int rhs = parsePrimary();
        Node n;
        n.kind = (op == TOK_STAR) ? NodeKind::Mul : NodeKind::Div;
        n.children = {lhs, rhs};
        lhs = emit(n);
    }
    return lhs;
}

int Parser::parsePrimary() {
    int exprIdx = -1;

    if (current.type == TOK_NUMBER) {
        std::string txt = current.text;
        Node n;
        if (txt.find('.') != std::string::npos) {
            n.kind = NodeKind::FloatLiteral;
            n.float_val = std::stod(txt);
        } else {
            n.kind = NodeKind::IntLiteral;
            n.int_val = std::stoi(txt);
        }
        advance();
        exprIdx = emit(n);
    }
    else if (current.type == TOK_STRING) {
        Node n; n.kind = NodeKind::StringLiteral; n.str_val = current.text;
        advance();
        exprIdx = emit(n);
    }
    else if (current.type == TOK_LPAREN) {
        Token savedToken = current;
        auto state = lexer.save();
        bool isArrow = false;

        int parenDepth = 0;
        advance(); // Eat '('
        parenDepth = 1;
        while (parenDepth > 0) {
            if (current.type == TOK_EOF) break;
            if (current.type == TOK_LPAREN) parenDepth++;
            if (current.type == TOK_RPAREN) parenDepth--;
            if (parenDepth > 0) advance();
        }
        if (current.type == TOK_RPAREN) {
            advance(); // Eat ')'
            if (current.type == TOK_ARROW) isArrow = true;
        }

        lexer.restore(state);
        current = savedToken;

        if (isArrow) {
            exprIdx = parseArrowFunction();
        } else {
            advance(); // Eat '('
            exprIdx = parseExpression();
            eat(TOK_RPAREN);
        }
    }
    else if (current.type == TOK_LBRACE) {
        exprIdx = parseObjectLiteral();
    }
    else if (current.type == TOK_IDENTIFIER) {
        if (lexer.save().pos < 999999) {
             Token savedToken = current;
             auto state = lexer.save();
             advance(); // Eat IDENT
             bool isArrow = (current.type == TOK_ARROW);
             lexer.restore(state);
             current = savedToken;

             if (isArrow) {
                 exprIdx = parseArrowFunction();
             }
        }

        if (exprIdx == -1) {
            std::string name = current.text;
            advance();

            bool found = false;
            for (int i = scope_stack.size() - 1; i >= 0; i--) {
                if (scope_stack[i].count(name)) {
                     Node n; n.kind = NodeKind::NameRef; n.resolved_index = scope_stack[i][name];
                     exprIdx = emit(n);
                     found = true;
                     break;
                }
            }
            if (!found) {
                 Node n; n.kind = NodeKind::GlobalRef; n.str_val = name;
                 exprIdx = emit(n);
            }
        }
    }
    else {
        throw std::runtime_error("Unexpected token in expression: " + current.text);
    }

    // Suffix loop
    while (true) {
        if (current.type == TOK_LPAREN) {
            exprIdx = parseCallNode(exprIdx);
        } else if (current.type == TOK_DOT) {
            advance();
            std::string member = current.text;
            eat(TOK_IDENTIFIER);
            Node n; n.kind = NodeKind::MemberAccess;
            n.str_val = member;
            n.children = {exprIdx};
            exprIdx = emit(n);
        } else if (current.type == TOK_INC || current.type == TOK_DEC) {
            bool inc = (current.type == TOK_INC);
            advance();

            NodeKind targetKind = nodes[exprIdx].kind;
            int targetResolvedIndex = nodes[exprIdx].resolved_index;
            std::string targetStrVal = nodes[exprIdx].str_val;
            int targetChild0 = (!nodes[exprIdx].children.empty()) ? nodes[exprIdx].children[0] : -1;

            if (targetKind == NodeKind::NameRef) {
                 Node one; one.kind = NodeKind::IntLiteral; one.int_val = 1;
                 int oneIdx = emit(one);

                 Node op; op.kind = inc ? NodeKind::Add : NodeKind::Sub;
                 op.children = {exprIdx, oneIdx};
                 int opIdx = emit(op);

                 Node assign; assign.kind = NodeKind::Assign;
                 assign.resolved_index = targetResolvedIndex;
                 assign.children = {opIdx};
                 exprIdx = emit(assign);
            } else if (targetKind == NodeKind::MemberAccess) {
                 int objIdx = targetChild0;
                 std::string prop = targetStrVal;

                 Node one; one.kind = NodeKind::IntLiteral; one.int_val = 1;
                 int oneIdx = emit(one);

                 Node op; op.kind = inc ? NodeKind::Add : NodeKind::Sub;
                 op.children = {exprIdx, oneIdx};
                 int opIdx = emit(op);

                 Node set; set.kind = NodeKind::SetField;
                 set.str_val = prop;
                 set.children = {objIdx, opIdx};
                 exprIdx = emit(set);
            } else {
                throw std::runtime_error("Invalid operand for postfix operator");
            }
        } else {
            break;
        }
    }
    return exprIdx;
}

int Parser::parseArrowFunction() {
    std::vector<std::string> args;

    if (current.type == TOK_LPAREN) {
        eat(TOK_LPAREN);
        if (current.type != TOK_RPAREN) {
            do {
                args.push_back(current.text);
                eat(TOK_IDENTIFIER);
                if (current.type == TOK_COMMA) advance();
                else break;
            } while(true);
        }
        eat(TOK_RPAREN);
    } else {
        args.push_back(current.text);
        eat(TOK_IDENTIFIER);
    }

    eat(TOK_ARROW);

    static int lambdaCounter = 0;
    std::string name = "lambda_" + std::to_string(lambdaCounter++);

    Function func;
    func.name = name;
    func.args = args;
    func.start_node = nodes.size();

    scope_stack.push_back({});
    for (const auto& arg : args) {
         Node n; n.kind = NodeKind::Arg; n.str_val = arg;
         int idx = emit(n);
         scope_stack.back()[arg] = idx;
    }

    if (current.type == TOK_LBRACE) {
        parseBlock();
    } else {
        int expr = parseExpression();
        Node ret; ret.kind = NodeKind::Return; ret.children = {expr};
        emit(ret);
    }

    func.end_node = nodes.size();
    functions[name] = func;
    scope_stack.pop_back();

    Node closure; closure.kind = NodeKind::MakeClosure;
    closure.str_val = name;
    return emit(closure);
}

int Parser::parseObjectLiteral() {
    eat(TOK_LBRACE);
    Node n; n.kind = NodeKind::ObjectLiteral;

    while (current.type != TOK_RBRACE && current.type != TOK_EOF) {
        std::string key = current.text;
        eat(TOK_IDENTIFIER);
        eat(TOK_COLON);
        int valIdx = parseExpression();

        Node keyNode; keyNode.kind = NodeKind::StringLiteral; keyNode.str_val = key;
        int keyIdx = emit(keyNode);
        n.children.push_back(keyIdx);
        n.children.push_back(valIdx);

        if (current.type == TOK_COMMA) advance();
        else break;
    }
    eat(TOK_RBRACE);
    return emit(n);
}

int Parser::parseCall(std::string name) {
    int funcRef = resolve(name);
    return parseCallNode(funcRef);
}

int Parser::parseCallNode(int funcNodeIdx) {
    eat(TOK_LPAREN);
    std::vector<int> args;
    if (current.type != TOK_RPAREN) {
        args.push_back(parseExpression());
        while (current.type == TOK_COMMA) {
            advance();
            args.push_back(parseExpression());
        }
    }
    eat(TOK_RPAREN);
    Node n; n.kind = NodeKind::Call;
    n.children.push_back(funcNodeIdx);
    for(int a : args) n.children.push_back(a);
    return emit(n);
}

void Parser::parseBlock() {
    eat(TOK_LBRACE);
    while (current.type != TOK_RBRACE && current.type != TOK_EOF) {
        parseStatement();
    }
    eat(TOK_RBRACE);
}

void Parser::parseStatement() {
    if (current.type == TOK_RETURN) {
        advance();
        int expr = parseExpression();
        eat(TOK_SEMICOLON);
        Node n; n.kind = NodeKind::Return; n.children = {expr};
        emit(n);
    } else if (current.type == TOK_IF) {
        advance();
        eat(TOK_LPAREN);
        int cond = parseExpression();
        eat(TOK_RPAREN);

        Node br; br.kind = NodeKind::BrFalse; br.children = {cond};
        int brIdx = emit(br);

        if (current.type == TOK_LBRACE) parseBlock();
        else parseStatement();

        if (current.type == TOK_ELSE) {
            advance();
            Node jmp; jmp.kind = NodeKind::Jmp;
            int jmpIdx = emit(jmp);

            nodes[brIdx].target_index = nodes.size();

            if (current.type == TOK_LBRACE) parseBlock();
            else parseStatement();

            nodes[jmpIdx].target_index = nodes.size();
        } else {
            nodes[brIdx].target_index = nodes.size();
        }
    } else if (current.type == TOK_WHILE) {
        advance();
        int loopStart = nodes.size();
        eat(TOK_LPAREN);
        int cond = parseExpression();
        eat(TOK_RPAREN);

        Node br; br.kind = NodeKind::BrFalse; br.children = {cond};
        int brIdx = emit(br);

        parseBlock();

        Node jmp; jmp.kind = NodeKind::Jmp; jmp.target_index = loopStart;
        emit(jmp);

        nodes[brIdx].target_index = nodes.size();
    } else if (current.type == TOK_FOR) {
        advance();
        eat(TOK_LPAREN);

        if (current.type == TOK_VAR || current.type == TOK_LET || current.type == TOK_CONST) {
            advance();
            std::string name = current.text;
            eat(TOK_IDENTIFIER);
            int init = -1;
            if (current.type == TOK_ASSIGN) {
                advance();
                init = parseExpression();
            }
            eat(TOK_SEMICOLON);

            Node n; n.kind = NodeKind::Let;
            n.str_val = name;
            if (init != -1) n.children = {init};
            int idx = emit(n);
            scope_stack.back()[name] = idx;
        } else {
            if (current.type != TOK_SEMICOLON) parseExpression();
            eat(TOK_SEMICOLON);
        }

        int loopStart = nodes.size();

        int cond = -1;
        if (current.type != TOK_SEMICOLON) cond = parseExpression();
        eat(TOK_SEMICOLON);

        int brIdx = -1;
        if (cond != -1) {
             Node br; br.kind = NodeKind::BrFalse; br.children = {cond};
             brIdx = emit(br);
        }

        int updateStart = -1;
        int jumpBodyIdx = emit({NodeKind::Jmp});

        updateStart = nodes.size();
        if (current.type != TOK_RPAREN) {
            parseExpression();
        }
        eat(TOK_RPAREN);

        Node jmpLoop; jmpLoop.kind = NodeKind::Jmp; jmpLoop.target_index = loopStart;
        emit(jmpLoop);

        int bodyStart = nodes.size();
        nodes[jumpBodyIdx].target_index = bodyStart;

        if (current.type == TOK_LBRACE) parseBlock();
        else parseStatement();

        Node jmpUpdate; jmpUpdate.kind = NodeKind::Jmp; jmpUpdate.target_index = updateStart;
        emit(jmpUpdate);

        if (brIdx != -1) {
            nodes[brIdx].target_index = nodes.size();
        }

    } else if (current.type == TOK_VAR || current.type == TOK_LET || current.type == TOK_CONST) {
        advance();
        std::string name = current.text;
        eat(TOK_IDENTIFIER);

        int init = -1;
        if (current.type == TOK_ASSIGN) {
            advance();
            init = parseExpression();
        }
        eat(TOK_SEMICOLON);

        Node n; n.kind = NodeKind::Let;
        n.str_val = name;
        if (init != -1) n.children = {init};

        int idx = emit(n);
        scope_stack.back()[name] = idx;
    } else {
        parseExpression();
        if (current.type == TOK_SEMICOLON) advance();
    }
}

void Parser::parseFunction() {
    if (current.type == TOK_EXPORT) advance();
    eat(TOK_FUNCTION);
    std::string name = current.text;
    eat(TOK_IDENTIFIER);

    Function func;
    func.name = name;

    eat(TOK_LPAREN);
    while (current.type == TOK_IDENTIFIER) {
        func.args.push_back(current.text);
        eat(TOK_IDENTIFIER); // Added EAT here
        if (current.type == TOK_COMMA) advance();
        else break;
    }
    eat(TOK_RPAREN);

    func.start_node = nodes.size();

    scope_stack.push_back({});
    for (const auto& arg : func.args) {
         Node n; n.kind = NodeKind::Arg; n.str_val = arg;
         int idx = emit(n);
         scope_stack.back()[arg] = idx;
    }

    eat(TOK_LBRACE);
    while (current.type != TOK_RBRACE && current.type != TOK_EOF) {
        parseStatement();
    }
    eat(TOK_RBRACE);

    func.end_node = nodes.size();
    functions[name] = func;
    scope_stack.pop_back();
}

void Parser::parse() {
    while (current.type != TOK_EOF) {
        if (current.type == TOK_FUNCTION || current.type == TOK_EXPORT) {
            parseFunction();
        } else {
            advance();
        }
    }
}
