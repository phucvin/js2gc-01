#pragma once
#include <string>
#include <vector>

struct RuntimeValue {
    int type = 0; // 0=i32/f64/null, 1=i31, 2=BoxedF64...
    long long i_val = 0;
    double f_val = 0;
    std::string s_val;
};

struct HeapObject {
    std::string type_name;
    std::vector<RuntimeValue> fields;
};
