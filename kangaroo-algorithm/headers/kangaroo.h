//
// Created by Nazarii Shcherbak on 28.09.2024.
//

#ifndef KANGAROO___KANGAROO_H
#define KANGAROO___KANGAROO_H

#include <gmpxx.h>
#include <unordered_map>

#include "../headers/table.h"

struct PreprocessingResult {
    long long numsteps;
    std::unordered_map<std::string, long long> distinguishedCounter;

    PreprocessingResult(long long numsteps, std::unordered_map<std::string, long long> distinguishedCounter) : numsteps(numsteps), distinguishedCounter(distinguishedCounter) {}};

struct MainResult {
    long long numsteps;
    mpz_class log;
    int iter_num;

    MainResult(long long numsteps, mpz_class log, int iter_num) : numsteps(numsteps), log(log), iter_num(iter_num) {}
};

class KangarooAlgorithm {
public:
    long W;
    long N;
    long T;
    int secret_size;
    double i;
    double m;
    long R;
    mpz_class* slog;
    mpz_class* s;
    mpz_class g;
    mpz_class p;
    mpz_class l;
    TableEntry* table;

    KangarooAlgorithm(
        long N,
        long T,
        int secret_size,
        double d,
        double alpha,
        double m,
        long R,
        mpz_class p
    );

    int distinguished(const mpz_class &w);

    int hash(const mpz_class &w);

    mpz_class power(const mpz_class &g, const mpz_class &e);

    void init_s();

    PreprocessingResult generate_table();

    MainResult solve_dlp(mpz_class h);
};

#endif //KANGAROO___KANGAROO_H
