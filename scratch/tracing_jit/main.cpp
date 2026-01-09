#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include "lexer.h"
#include "parser.h"
#include "vm.h"

// Utils
std::string read_file(const std::string& path) {
    std::ifstream t(path);
    if (!t.is_open()) throw std::runtime_error("Cannot open file: " + path);
    std::stringstream buffer;
    buffer << t.rdbuf();
    return buffer.str();
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <file.js>" << std::endl;
        return 1;
    }
    try {
        std::string src = read_file(argv[1]);
        Parser parser(src);
        parser.parse();

        Evaluator vm(parser.getNodes(), parser.getFunctions());
        Value result = vm.runFunction("main", {});
        if (result.is_int) std::cout << result.int_val << std::endl;
        else if (result.is_float) std::cout << result.float_val << std::endl;
        else std::cout << result.str_val << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}
