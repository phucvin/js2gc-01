#ifndef VALUE_H
#define VALUE_H

#include <string>

struct Value {
    bool is_int = true;
    int int_val = 0;
    std::string str_val;
};

#endif // VALUE_H
