#include <gmpxx.h>
#include <unordered_map>
#include <iostream>
#include <thread>
#include <mutex>
#include <vector>
#include <algorithm>
#include <atomic>
#include <sodium.h>
#include "../nlohmann/json.hpp"

#include "../headers/kangaroo.h"
#include "../headers/logger.h"

using std::lower_bound;
using nlohmann::json;

std::timed_mutex mut;

KangarooAlgorithm::KangarooAlgorithm(
        long n,
        long w,
        int secret_size,
        double i,
        double m,
        long r
): N(n), secret_size(secret_size), W(w), i(i), R(r), m(m){
    sodium_init();

    mpz_ui_pow_ui(l.get_mpz_t(), 2, secret_size);
}

int KangarooAlgorithm::distinguished(const mpz_class &w)
{
    return !(w.get_si() & (W-1));
}

int KangarooAlgorithm::hash(const mpz_class &w)
{
    return w.get_si() & (R-1);
}

mpz_class convertToMpzClass(const unsigned char byteArray[32]) {
    mpz_t temp;
    mpz_init(temp);

    mpz_import(temp, 32, 1, sizeof(unsigned char), 0, 0, byteArray);

    mpz_class result(temp);
    mpz_clear(temp);

    return result;
}

unsigned char* convertToByteArray(const mpz_class& num) {
    mpz_t temp;
    mpz_init(temp);
    mpz_set(temp, num.get_mpz_t());

    // Initialize a 32-byte buffer with all zeros
    unsigned char* buffer = new unsigned char[32]();

    size_t count;
    // Export the bytes of the number
    unsigned char tempBuffer[32];
    mpz_export(tempBuffer, &count, 1, sizeof(unsigned char), 0, 0, temp);

    // Copy the exported bytes to the end of the 32-byte buffer
    std::memcpy(buffer + (32 - count), tempBuffer, count);

    mpz_clear(temp);
    return buffer;
}

std::string toHexString(const unsigned char s_point[32]) {
    std::stringstream ss;
    ss << std::hex << std::setfill('0');
    for (int i = 0; i < 32; ++i) {
        ss << std::setw(2) << static_cast<int>(s_point[i]);
    }
    return ss.str();
}

void random_bits(unsigned char* output, size_t num_bits) {
    // Calculate the number of bytes needed (round up)
    size_t num_bytes = (num_bits + 7) / 8;

    randombytes_buf(output, num_bytes);

    // Mask the unused bits in the last byte, if necessary
    size_t unused_bits = (num_bytes * 8) - num_bits;
    if (unused_bits > 0) {
        output[num_bytes - 1] &= (0xFF >> unused_bits);
    }
}

// Init s and slog arrays. Note, that this method needs to be run before solve_dlp() method.
void KangarooAlgorithm::init_s() {
    mpf_class float_l(l);
    int slog_secret_size = int(std::log2(std::pow(2, secret_size - 2) / W));
    std::cout << slog_secret_size << "\n";
    gmp_randclass ra(gmp_randinit_default);

    tableMap.slog = new unsigned char*[R];
    tableMap.s = new unsigned char*[R];
    for (int i = 0;i < R;++i) {
        tableMap.slog[i] = new unsigned char [32];
        tableMap.s[i] = new unsigned char [32];

        random_bits(tableMap.slog[i], slog_secret_size);
        crypto_scalarmult_ed25519_base_noclamp(tableMap.s[i], tableMap.slog[i]);

        std::reverse(tableMap.slog[i], tableMap.slog[i]+32);

    }
}

void KangarooAlgorithm::parallel_loop_map(std::unordered_map<std::string, long long>& distinguishedCounter,
                                      int& tabledone, gmp_randclass& ra, int i, int W,
                                      unsigned char** slog, unsigned char** s, int thread_num) {
    int return_counter = 0;
    int target_count = 10;

    std::cout << "running #" << thread_num << "\n";
    long long numsteps = 0;
    while (tabledone < N) {
        auto wlog = new unsigned char [32];
        auto w = new unsigned char [32];

        mpz_class wlog_mpz = ra.get_z_bits(this->secret_size);
        wlog = convertToByteArray(wlog_mpz);
        std::reverse(wlog, wlog+32);

        crypto_scalarmult_ed25519_base_noclamp(w, wlog);
        mpz_class w_mpz = convertToMpzClass(w);

        for (int loop = 0;loop < 8*W;++loop) {
            if (distinguished(w_mpz)) {
                mut.lock();
                auto distEntry = tableMap.tableMap[w_mpz.get_str(16)];
                mut.unlock();

                if (distEntry.log == 0) {

                    auto wtest = new unsigned char [32];
                    crypto_scalarmult_ed25519_base_noclamp(wtest, wlog);

                    tableMap.tableMap[w_mpz.get_str(16)] = TableEntryMap{wlog_mpz};

                    std::cout << "tabledone: " << tabledone << "/" << N << std::endl;
                    ++tabledone;
                }

                numsteps = 0;
                break;
            }

            unsigned char* w_base = new unsigned char[32];
            crypto_scalarmult_ed25519_base_noclamp(w_base, convertToByteArray(wlog_mpz));

            int h = hash(w_mpz);
//            std::cout << w_mpz.get_str(16) << "\n";
//            std::cout << h << "\n";

//            std::cout << toHexString(slog[h]) << "\n";
//            std::cout << convertToMpzClass(slog[h]).get_str(16) << "\n";

            wlog_mpz = wlog_mpz + convertToMpzClass(slog[h]);

            auto w_add = new unsigned char [32];
            crypto_core_ed25519_add(w_add, w, s[h]);

            w = w_add;
            w_mpz = convertToMpzClass(w);

            unsigned char* w_test = new unsigned char [32];

            wlog = convertToByteArray(wlog_mpz);
            std::reverse(wlog, wlog + 32);

            crypto_scalarmult_ed25519_base_noclamp(w_test, wlog);
//            std::cout << toHexString(w_test) << "\n";
//            std::cout << toHexString(w) << "\n";
            ++numsteps;

            ++return_counter;

//            std::cout << convertToMpzClass(w).get_str(16) << "\n";

//            if (return_counter == target_count) {
//                return;
//            }
        }
    }
}

void KangarooAlgorithm::write_table_json(){
    auto output_name = "output_"+std::to_string(W)+"_"+std::to_string(N)+"_"+std::to_string(secret_size)+"_"+std::to_string(R)+".json";

    std::vector<std::string> s_strings;
    for (int i = 0; i < R; i++) {
        s_strings.push_back(toHexString(tableMap.s[i]));
    }

    std::vector<std::string> slog_strings;
    for (int i = 0; i < R; i++) {
        slog_strings.push_back(convertToMpzClass(tableMap.slog[i]).get_str(16));
    }

    json table;
    for (const auto& pair : tableMap.tableMap) {
        table.push_back({
            {"point", pair.first},
            {"value", pair.second.log.get_str(16)}
        });
    }

    json j = {
            {"file_name", output_name},
            {"s", s_strings},
            {"slog", slog_strings},
            {"table", table},
    };

    std::ofstream file(output_name);
    if (file.is_open()) {
        file << j.dump(4);
        file.close();
    }
}

void to_json(nlohmann::json& j, unsigned char* m) {
    j = toHexString(m);  // Convert to hex string (without '0x' prefix)
}

PreprocessingResult KangarooAlgorithm::generate_table_parallel_map() {
    std::unordered_map<std::string, long long> distinguishedCounter;
    long long numsteps = 0;

    gmp_randclass ra(gmp_randinit_default);
    ra.seed(time(NULL));

    int tabledone = 0;

    // Number of threads to use
    int num_threads = std::thread::hardware_concurrency();
    std::vector<std::thread> threads;

    for (int t = 0; t < num_threads; ++t) {
        threads.emplace_back(&KangarooAlgorithm::parallel_loop_map, this, std::ref(distinguishedCounter),
                             std::ref(tabledone), std::ref(ra), i, W, tableMap.slog, tableMap.s, t);
    }

    // Wait for all threads to finish
    for (auto& thread : threads) {
        thread.join();
    }

    return PreprocessingResult(numsteps, distinguishedCounter);
}

// Example function that does some work and checks the stop condition
void KangarooAlgorithm::solve_dlp_map_parallel_function(mpz_class h, MainResult& final_result, std::atomic<bool>& stopFlag, gmp_randclass& ra, int j) {
    long long numsteps = 0;
    mpz_class wlog_mpz;
    auto wlog = new unsigned char [32];

    long long found_counter = 0;

    while (true) {
        auto w = new unsigned char [32];

        wlog_mpz = ra.get_z_bits(this->secret_size); // TODO: choose some other function because this one is deterministic
        wlog = convertToByteArray(wlog_mpz);
        std::reverse(wlog, wlog+32);

        crypto_scalarmult_ed25519_base_noclamp(w, wlog);
        mpz_class w_mpz = convertToMpzClass(w);

        for (int loop = 0;loop < 8*W;++loop) {
            if (distinguished(w_mpz)) {
//                std::cout << w_mpz.get_str(16) + "\n";


                mut.lock();
                auto mapEntry = tableMap.tableMap[w_mpz.get_str(16)];
                mut.unlock();

                if (mapEntry.log != 0) {
                    std::cout << "found here " + std::to_string(found_counter) + "\n";
                    found_counter++;
//                    std::cout << mapEntry.log.get_str(16) << "\n";
//                    std::cout << wlog_mpz.get_str(16) << "\n";
                    wlog_mpz = mapEntry.log - wlog_mpz;
                    break;

                }

            }

            unsigned char* w_base = new unsigned char[32];
            crypto_scalarmult_ed25519_base_noclamp(w_base, convertToByteArray(wlog_mpz));

            int h = hash(wlog_mpz);
            wlog_mpz = wlog_mpz + convertToMpzClass(tableMap.slog[h]);

            auto w_add = new unsigned char [32];
            crypto_core_ed25519_add(w_add, w, tableMap.s[h]);

            w = w_add;
            w_mpz = convertToMpzClass(w);

            unsigned char* w_test = new unsigned char [32];

            wlog = convertToByteArray(wlog_mpz);
            std::reverse(wlog, wlog + 32);

            crypto_scalarmult_ed25519_base_noclamp(w_test, wlog);
//            std::cout << toHexString(w_test) << "\n";
//            std::cout << toHexString(w) << "\n";
            ++numsteps;
        }

        std::cout << "checking\n";
//        std::cout << wlog_mpz.get_str();

        unsigned char* res = new unsigned char [32];
        crypto_scalarmult_ed25519_base_noclamp(res, convertToByteArray(wlog_mpz));

        // Check if the solution is found
        if (toHexString(res) == h.get_str(16)) {
            auto is_loaded = stopFlag.load();

            std::cout<<"found\n" ;
//        if (!is_loaded) {
//            mut.lock();
//            final_result = MainResult(numsteps, wdist, loop);
//            stopFlag.store(true);
//            mut.unlock();
//        }
            return;
        }
    }

}

// Function to launch multiple threads running the worker function
MainResult KangarooAlgorithm::solve_dlp_map_parallel(mpz_class h) {
    std::vector<std::thread> threads;

    gmp_randclass ra(gmp_randinit_default);
    std::atomic<bool> stopFlag{false};  // Flag to signal threads to stop
    int num_threads = 1;//std::thread::hardware_concurrency();

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
