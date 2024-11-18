//
// Created by Nazarii Shcherbak on 28.09.2024.
//

#ifndef KANGAROO___KANGAROO_H
#define KANGAROO___KANGAROO_H

#include <gmpxx.h>
#include <unordered_map>
#include <map>
#include <atomic>
#include "../headers/table.h"

struct PreprocessingResult {
    long long numsteps;
    std::unordered_map<std::string, long long> distinguishedCounter;

    PreprocessingResult(long long numsteps, std::unordered_map<std::string, long long> distinguishedCounter) : numsteps(numsteps), distinguishedCounter(distinguishedCounter) {}
};

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
    mpz_class g;
    mpz_class l;

    // Parallelization with map
    TableDataMap tableMap;

    KangarooAlgorithm(
            long n,
            long w,
            int secret_size,
            double i,
            double m,
            long r
    );

    int distinguished(const mpz_class &w);

    int hash(const mpz_class &w);

    void init_s();

    PreprocessingResult generate_table_parallel_map();

    void parallel_loop_map(std::unordered_map<std::string, long long>& distinguishedCounter,
                       int& tabledone, gmp_randclass& ra, int i, int W,
                       unsigned char** slog, unsigned char** s, int thread_num);

    void write_table_json();
    void solve_dlp_map_parallel_function( mpz_class h, MainResult& final_result, std::atomic<bool>& stopFlag, gmp_randclass& ra, int j) ;

    MainResult solve_dlp_map_parallel(mpz_class h);

};

#endif //KANGAROO___KANGAROO_H
