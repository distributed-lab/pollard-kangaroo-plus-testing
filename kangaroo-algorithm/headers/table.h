#ifndef KANGAROO___TABLE_H
#define KANGAROO___TABLE_H

#include <gmpxx.h>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_map>

struct TableEntryMap {
    mpz_class log;

    void writeToFile(std::ofstream& outFile) const;

    void readFromFile(std::ifstream& inFile);
};

struct TableDataMap {
    std::unordered_map<std::string, TableEntryMap> tableMap;

    bool writeToFile(std::string path);

    bool readFromFile(std::string path);
};


#endif //KANGAROO___TABLE_H
