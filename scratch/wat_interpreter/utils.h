#pragma once
#include <string>
#include <fstream>
#include <sstream>
#include <stdexcept>

inline std::string read_file(const std::string& path) {
    std::ifstream t(path);
    if (!t.is_open()) throw std::runtime_error("Cannot open file: " + path);
    std::stringstream buffer;
    buffer << t.rdbuf();
    return buffer.str();
}
