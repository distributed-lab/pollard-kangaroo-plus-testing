#ifndef KANGAROO___TABLE_H
#define KANGAROO___TABLE_H

#include <gmpxx.h>
#include <fstream>
#include <string>
#include <vector>

struct TableEntry {
    mpz_class x;
    mpz_class log;
    long long weight;

    void writeToFile(std::ofstream& outFile) const;

    void readFromFile(std::ifstream& inFile);
};

struct TableData {
    TableEntry* table;
    size_t size;

    bool writeToFile(std::string path) const;

    bool readFromFile(std::string path);
};

bool tablesort(TableEntry i, TableEntry j);
bool tablesort2(TableEntry i, TableEntry j);

#endif //KANGAROO___TABLE_H
