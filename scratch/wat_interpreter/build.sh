#!/bin/bash
g++ -std=c++17 main.cpp lexer.cpp sparser.cpp compiler.cpp vm.cpp -o wat_interpreter
