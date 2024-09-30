#include <algorithm>
#include <iostream>
#include <gmpxx.h>
#include <string>

#include "../headers/secrets.h"
#include "../headers/table.h"
#include "../headers/logger.h"
#include "../headers/arguments.h"
#include "../headers/kangaroo.h"

using std::cout;
using std::flush;
using std::sort;
using std::lower_bound;

mpz_class p("109058979322431746959182812013517394520037958891193115336877067190430268203759");

int main(int argc, char *argv[])
{
    ParsedArgs parsed = parse_args(argc, argv);

    auto algo = new KangarooAlgorithm(
            parsed.t * parsed.rat,
            parsed.t,
            parsed.secret_size,
            parsed.i,
            parsed.alpha,
            parsed.m,
            parsed.r,
            p
    );

    algo->init_s();

    std::string log_path = parsed.log_path;
    init_logger(log_path);

    SecretsData secrets = read_secrets(parsed.secret_path);

    log("Activating the test with next data:");
    log("R: " + std::to_string(algo -> R));
    log("W: " + std::to_string(algo -> W));
    log("T: " + std::to_string(algo -> T));
    log("C: " + std::to_string(parsed.rat));
    log("N: " + std::to_string(algo -> N));
    log("Alpha: " + std::to_string(parsed.alpha));
    log("M: " + std::to_string(algo -> m));
    log("i: " + std::to_string(algo -> i));
    log("Secret size: " + std::to_string(parsed.secret_size) + " bits");
    log("Logs will be stored into: " + parsed.log_path);

    gmp_randclass ra(gmp_randinit_default);

    if (parsed.allow_write_table) {
        // Do preprocessing and generate a new table
        log("Preprocessing started. The table will be stored into " + parsed.table_path);

        auto preprocessing_start = std::chrono::high_resolution_clock::now();

        PreprocessingResult res = algo->generate_table();

        auto preprocessing_end = std::chrono::high_resolution_clock::now();
        log("Preprocessing complete with time: " + std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(preprocessing_end - preprocessing_start).count()) + " millis");

        log("Distinguished repeating points counter:");
        if (!res.distinguishedCounter.empty()) {
            for (const auto& pair : res.distinguishedCounter) {
                log("point " + pair.first + " repeated " + std::to_string(pair.second) + " times;");
            }
        } else {
            log("no repeated distinguished points found");
        }

        // Write a generated table to a file
        TableData data = {algo -> table, static_cast<size_t>(algo -> N)};

        bool is_file_written = data.writeToFile(parsed.table_path);
        if (!is_file_written) {
            std::cout << "failed to write a table to file" << "\n";
        } else {
            std::cout << "table file is written" << "\n";
        }

        log(std::to_string(res.numsteps) + " precomputation steps; ");
    } else {
        // Read a generated table from a file
        TableData data = *new TableData();
        if (data.readFromFile(parsed.table_path)) {
            log("Table " + parsed.table_path + " is read, skip processing.");
        } else {
            log("Cant read a table :<");
            return 0;
        }

        algo -> table = data.table;
    }

    unsigned long long total_time = 0;
    unsigned long long worst_result = 0;
    unsigned long long best_result = 100000000000000000;

    unsigned long long total_steps_to_solve = 0;
    unsigned long long worst_steps_to_solve = 0;
    unsigned long long best_steps_to_solve = 100000000000000000;

    unsigned long long total_iter_num = 0;
    unsigned long long worst_iter_num = 0;
    unsigned long long best_iter_num = 100000000000000000;

    for (int i = 0; i < secrets.count; i++) {
        mpz_class hlog = secrets.secrets[i];
        mpz_class h = algo -> power(algo -> g, hlog);

        log("Solving problem # " + std::to_string(i));
        auto main_start = std::chrono::high_resolution_clock::now();

        auto res = algo->solve_dlp(h);

        auto main_end = std::chrono::high_resolution_clock::now();
        unsigned long long spent_time = std::chrono::duration_cast<std::chrono::milliseconds>(main_end - main_start).count();
        total_time += spent_time;

        // Count and output statistics
        double mean_time = static_cast<double>(total_time) / i;

        total_steps_to_solve += res.numsteps;
        total_iter_num += res.iter_num;

        double mean_steps_to_slove = static_cast<double>(total_steps_to_solve) / i;
        double mean_iter_num = static_cast<double>(total_iter_num) / i;

        if (spent_time < best_result) {
            best_result = spent_time;
        }

        if (spent_time > worst_result) {
            worst_result = spent_time;
        }

        if (res.numsteps < best_steps_to_solve) {
            best_steps_to_solve = res.numsteps;
        }

        if (res.numsteps > worst_steps_to_solve) {
            worst_steps_to_solve = res.numsteps;
        }

        if (res.iter_num < best_iter_num) {
            best_iter_num = res.iter_num;
        }

        if (res.iter_num > worst_iter_num) {
            worst_iter_num = res.iter_num;
        }

        log("Steps to solve: " + std::to_string(res.numsteps) + ". Mean steps to solve: " +
        std::to_string(mean_steps_to_slove) + ". Best steps to solve: " + std::to_string(best_steps_to_solve) + ". Worst time to solve " + std::to_string(worst_steps_to_solve) + "\n" +
        "Iterations number: " + std::to_string(res.iter_num) + ". Mean iter number: " + std::to_string(mean_iter_num) +
        ". Best iter number: " + std::to_string(best_iter_num) + ". Worst iter number: " + std::to_string(worst_iter_num));

        log("Spent time: " + std::to_string(spent_time) + " ms. " +
                           "Total time: " + std::to_string(total_time) + " ms. Mean time: " +
                    std::to_string(mean_time) + " ms. Best: " + std::to_string(best_result) + "ms. Worst:" +
                    std::to_string(worst_result) + "ms.\n\n");
    }

    return 0;
}

