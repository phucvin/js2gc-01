#include <iostream>
#include <vector>
#include <string>

#include "utils.h"
#include "sparser.h"
#include "compiler.h"
#include "vm.h"

using namespace std;

int main(int argc, char** argv) {
    if (argc < 2) return 1;
    string src = read_file(argv[1]);
    SParser p(src);
    SExpr mod = p.parse();

    Compiler c;
    c.compileModule(mod);

    VM vm(c.getInstrs(), c.getFunctions());
    vm.run("$test", {});

    return 0;
}
