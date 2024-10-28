#include <gmpxx.h>
#include <unordered_map>
#include <iostream>
#include <thread>
#include <mutex>
#include <vector>
#include <algorithm>
#include <atomic>

#include "../headers/kangaroo.h"
#include "../headers/logger.h"

using std::lower_bound;
std::timed_mutex mut;

KangarooAlgorithm::KangarooAlgorithm(
        long n,
        long w,
        int secret_size,
        double i,
        double m,
        long r,
        mpz_class p
): N(n), secret_size(secret_size), W(w), i(i), R(r), p(p), m(m){
    l = power(mpz_class(2), mpz_class(secret_size));

    g = p / l; g = (g * g) % p;
}

int KangarooAlgorithm::distinguished(const mpz_class &w)
{
    return !(w.get_si() & (W-1));
}

int KangarooAlgorithm::hash(const mpz_class &w)
{
    return w.get_si() & (R-1);
}

mpz_class KangarooAlgorithm::power(const mpz_class &g, const mpz_class &e)
{
    mpz_class result;

    mpz_powm(result.get_mpz_t(),g.get_mpz_t(),e.get_mpz_t(),p.get_mpz_t());
    return result;
}

// Init s and slog arrays. Note, that this method needs to be run before solve_dlp() method.
void KangarooAlgorithm::init_s() {
    mpf_class float_l(l);

    gmp_randclass ra(gmp_randinit_default);
    slog = new mpz_class[R];
    for (int i = 0;i < R;++i) slog[i] = ra.get_z_range(ra.get_z_bits(secret_size-2) / W);

    s = new mpz_class[R];
    for (int i = 0;i < R;++i) s[i] = power(g,slog[i]);
}

void KangarooAlgorithm::parallel_loop_map(std::unordered_map<std::string, long long>& distinguishedCounter,
                                      int& tabledone, gmp_randclass& ra, int i, int W, mpz_class g,
                                      mpz_class* slog, mpz_class* s, mpz_class p, int thread_num) {
    std::cout << "running #" << thread_num << "\n";
    long long numsteps = 0;
    while (tabledone < N) {
        mpz_class wlog = ra.get_z_bits(secret_size);
        mpz_class w = power(g, wlog);

        for (int loop = 0;loop < 8*W;++loop) {
            if (distinguished(w)) {
                mut.lock();
                auto distEntry = tableMap.tableMap[w.get_str(16)];
                mut.unlock();

                if (distEntry.log == 0) {
                    tableMap.tableMap[w.get_str(16)] = TableEntryMap{wlog};

                    std::cout << "tabledone: " << tabledone << "/" << N << std::endl;
                    ++tabledone;
                }

                numsteps = 0;
                break;
            }

            int h = hash(w);
            wlog = wlog + slog[h];
            w = (w * s[h]) % p;
            ++numsteps;
        }
    }

}

PreprocessingResult KangarooAlgorithm::generate_table_parallel_map() {
    std::unordered_map<std::string, long long> distinguishedCounter;
    long long numsteps = 0;

    gmp_randclass ra(gmp_randinit_default);
    int tabledone = 0;

    // Number of threads to use
    int num_threads = std::thread::hardware_concurrency();
    std::vector<std::thread> threads;

    for (int t = 0; t < num_threads; ++t) {
        threads.emplace_back(&KangarooAlgorithm::parallel_loop_map, this, std::ref(distinguishedCounter),
                             std::ref(tabledone), std::ref(ra), i, W, g, slog, s, p, t);
    }

    // Wait for all threads to finish
    for (auto& thread : threads) {
        thread.join();
    }

    return PreprocessingResult(numsteps, distinguishedCounter);
}

// Example function that does some work and checks the stop condition
void KangarooAlgorithm::solve_dlp_map_parallel_function(mpz_class h, MainResult& final_result, std::atomic<bool>& stopFlag, gmp_randclass& ra, int j) {
    long numsteps = 0;

    while (true) {
        auto is_sol_found = stopFlag.load();

        if (is_sol_found) {
            return;
        }

        mpz_class wdist = ra.get_z_bits(secret_size-16);
        mpz_class w = (h * power(g, wdist)) % p;

        long steps_num = i * static_cast<long>(W);
        long loop = 0;
        for (; loop < steps_num; ++loop) {
            if (distinguished(w)) {

                mut.lock();
                auto mapEntry = tableMap.tableMap[w.get_str(16)];
                mut.unlock();

                if (mapEntry.log != 0) {
                    wdist = mapEntry.log - wdist;
                }

                break;
            }

            int h_idx = hash(w);

            wdist = wdist + slog[h_idx];
            w = (w * s[h_idx]) % p;

            ++numsteps;
        }

        // Check if the solution is found
        if (power(g, wdist) == h) {
            auto is_loaded = stopFlag.load();

            if (!is_loaded) {
                mut.lock();
                final_result = MainResult(numsteps, wdist, loop);
                stopFlag.store(true);
                mut.unlock();
            }
            return;
        }
    }
}

// Function to launch multiple threads running the worker function
MainResult KangarooAlgorithm::solve_dlp_map_parallel(mpz_class h) {
    std::vector<std::thread> threads;

    gmp_randclass ra(gmp_randinit_default);
    std::atomic<bool> stopFlag{false};  // Flag to signal threads to stop
    int num_threads = std::thread::hardware_concurrency();

    MainResult final_result = MainResult(0, 0, 0);

    // Launch threads
    for (int j = 0; j < num_threads; ++j) {
        threads.emplace_back(&KangarooAlgorithm::solve_dlp_map_parallel_function, this, h, std::ref(final_result), std::ref(stopFlag), std::ref(ra), j);
    }

    // Wait for all threads to finish
    for (auto& thread : threads) {
        thread.join();
    }

    std::cout << final_result.log.get_str(16) << "\n";

    return final_result;
}
