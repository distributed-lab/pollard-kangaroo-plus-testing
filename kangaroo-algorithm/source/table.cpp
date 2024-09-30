#include <algorithm>
#include <iostream>
#include <gmpxx.h>
#include <fstream>
#include <string>
#include <getopt.h>
#include <cstdlib>
#include <vector>

#include "../headers/table.h"

void TableEntry::writeToFile(std::ofstream& outFile) const {
    // Write the size of mpz_class x
    size_t x_size = mpz_sizeinbase(x.get_mpz_t(), 2);
    outFile.write(reinterpret_cast<const char*>(&x_size), sizeof(x_size));
    if (x_size > 0) {
        std::vector<unsigned char> x_data(x_size);
        mpz_export(x_data.data(), nullptr, 1, sizeof(unsigned char), 0, 0, x.get_mpz_t());
        outFile.write(reinterpret_cast<const char*>(x_data.data()), x_size);
    }

    // Write the size of mpz_class log
    size_t log_size = mpz_sizeinbase(log.get_mpz_t(), 2);
    outFile.write(reinterpret_cast<const char*>(&log_size), sizeof(log_size));
    if (log_size > 0) {
        std::vector<unsigned char> log_data(log_size);
        mpz_export(log_data.data(), nullptr, 1, sizeof(unsigned char), 0, 0, log.get_mpz_t());
        outFile.write(reinterpret_cast<const char*>(log_data.data()), log_size);
    }

    // Write the weight
    outFile.write(reinterpret_cast<const char*>(&weight), sizeof(weight));
}

void TableEntry::readFromFile(std::ifstream& inFile) {
    // Read the size of mpz_class x
    size_t x_size;
    inFile.read(reinterpret_cast<char*>(&x_size), sizeof(x_size));
    if (x_size > 0) {
        std::vector<unsigned char> x_data(x_size);
        inFile.read(reinterpret_cast<char*>(x_data.data()), x_size);
        mpz_import(x.get_mpz_t(), x_size, 1, sizeof(unsigned char), 0, 0, x_data.data());
    }

    // Read the size of mpz_class log
    size_t log_size;
    inFile.read(reinterpret_cast<char*>(&log_size), sizeof(log_size));
    if (log_size > 0) {
        std::vector<unsigned char> log_data(log_size);
        inFile.read(reinterpret_cast<char*>(log_data.data()), log_size);
        mpz_import(log.get_mpz_t(), log_size, 1, sizeof(unsigned char), 0, 0, log_data.data());
    }

    // Read the weight
    inFile.read(reinterpret_cast<char*>(&weight), sizeof(weight));
}

bool TableData::writeToFile(std::string path) const {
    std::ofstream outFile(path, std::ios::binary);
    if (outFile) {
        outFile.write(reinterpret_cast<const char*>(&size), sizeof(size));
        for (size_t i = 0; i < size; ++i) {
            table[i].writeToFile(outFile);
        }

        outFile.close();
        return true;
    }

    return false;
}

bool TableData::readFromFile(std::string path) {
    std::ifstream inFile(path, std::ios::binary);
    if (inFile) {
        inFile.read(reinterpret_cast<char*>(&size), sizeof(size));
        table = new TableEntry[size];
        for (size_t i = 0; i < size; ++i) {
            table[i].readFromFile(inFile);
        }

        return true;
    }

    return false;
}

bool tablesort(TableEntry i, TableEntry j)
{
    return i.weight > j.weight; // move higher weights earlier
}

bool tablesort2(TableEntry i, TableEntry j)
{
    return i.x < j.x; // move smaller points earlier
}