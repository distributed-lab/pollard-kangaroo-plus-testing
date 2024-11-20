#include <algorithm>
#include <iostream>

#include "../headers/table.h"
#include "../headers/kangaroo.h"

using std::cout;
using std::flush;
using std::sort;
using std::lower_bound;

class Data {
public:
    int n;
    int w;
    int secret;

    Data(int n, int w, int secret) : n(n), w(w), secret(secret) {}
};

int main() {
    Data data[] = {
            Data(40000, 65536, 48),
            Data(40000, 65536*2, 48),
    };

    for (int i = 0; i < 2; i++) {
        auto algo = new KangarooAlgorithm(
                data[i].n,
                data[i].w,
                data[i].secret,
                8,
                0.5,
                128
        );

        algo->init_s();
        algo->generate_table_parallel_map();

        algo->write_table_json();
    }
}
