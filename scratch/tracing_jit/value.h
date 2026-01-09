#ifndef VALUE_H
#define VALUE_H

#include <string>
#include <map>
#include <memory>
#include <vector>

struct Value;

using Object = std::map<std::string, Value>;

struct Closure {
    std::string func_name;
    std::map<int, Value> env;
};

struct Value {
    bool is_int = false;
    bool is_float = false;
    int int_val = 0;
    double float_val = 0.0;
    std::string str_val;
    std::shared_ptr<Object> obj_val;
    std::shared_ptr<Closure> closure_val;

    bool is_obj() const { return obj_val != nullptr; }
    bool is_closure() const { return closure_val != nullptr; }

    static Value makeInt(int v) {
        Value val; val.is_int = true; val.int_val = v; return val;
    }
    static Value makeFloat(double v) {
        Value val; val.is_float = true; val.float_val = v; return val;
    }
    static Value makeString(std::string s) {
        Value val; val.str_val = s; return val;
    }
    static Value makeObject(std::shared_ptr<Object> o) {
        Value val; val.obj_val = o; return val;
    }
    static Value makeClosure(std::shared_ptr<Closure> c) {
        Value val; val.closure_val = c; return val;
    }
    static Value makeUndefined() {
        return Value{};
    }
};

#endif // VALUE_H
