#include <gmpxx.h>
#include <unordered_map>
#include <iostream>

#include "../headers/kangaroo.h"

using std::lower_bound;

KangarooAlgorithm::KangarooAlgorithm(
        long n,
        long t,
        int secret_size,
        double i,
        double alpha,
        double m,
        long r,
        mpz_class p
): N(n), T(t), secret_size(secret_size), i(i), R(r), p(p), m(m){
    l = power(mpz_class(2), mpz_class(secret_size));
    g = p / l; g = (g * g) % p;
    W = static_cast<long>(alpha * std::sqrt(mpz_get_d(l.get_mpz_t()) / t));

    table = new TableEntry[N];
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
    mpz_class max_range((float_l * 2 * m) / W);

    gmp_randclass ra(gmp_randinit_default);
    slog = new mpz_class[R];
    for (int i = 0;i < R;++i) slog[i] = ra.get_z_range(max_range);

    s = new mpz_class[R];
    for (int i = 0;i < R;++i) s[i] = power(g,slog[i]);
}

// Performs preprocessing by generating a new table.
PreprocessingResult KangarooAlgorithm::generate_table() {
    std::unordered_map<std::string, long long> distinguishedCounter;
    long long numsteps = 0;

    gmp_randclass ra(gmp_randinit_default);
    auto genTable = new TableEntry[N]; // of which T will be used in main computation
    int tabledone = 0;

    while (tabledone < N) {
        mpz_class wlog = ra.get_z_bits(secret_size);
        mpz_class w = power(g,wlog);

        for (int loop = 0;loop < i*W;++loop) {
            if (distinguished(w)) {
                int j;
                for (j = 0;j < tabledone;++j) if (table[j].x == w) {
                    long long c = distinguishedCounter[w.get_str()];

                    distinguishedCounter[w.get_str()] = c + 1;
                    break;
                }

                if (j < tabledone) {
                    table[j].weight += i/2*W + numsteps;
                } else {
                    table[tabledone].x = w;
                    table[tabledone].log = wlog;
                    table[tabledone].weight = i/2*W + numsteps;
                    ++tabledone;
                }

                break;
            }

            int h = hash(w);

            wlog = wlog + slog[h];
            w = (w * s[h]) % p;

            ++numsteps;
        }
    }

    std::sort(table,table + N,tablesort);
    std::sort(table,table + T,tablesort2);

    table = genTable;

    return PreprocessingResult(numsteps, distinguishedCounter);
}

// Performs main computations (solves DLP for a provided input)
MainResult KangarooAlgorithm::solve_dlp(mpz_class h) {
    gmp_randclass ra(gmp_randinit_default);
    long long numsteps = 0;

    for (;;) {
        mpz_class wdist = ra.get_z_bits(secret_size-8);
        mpz_class w = (h * power(g,wdist)) % p;

        long steps_num = i * static_cast<long>(W);
        long loop = 0;
        for (;loop < steps_num;++loop) {
            if (distinguished(w)) {
                TableEntry desired;
                desired.x = w;

                TableEntry *position = lower_bound(table, table + T, desired, tablesort2);

                if (position < table + T)
                    if (position->x == w) {
                        wdist = position->log - wdist;
                    }
                break;
            }

            int h = hash(w);
            wdist = wdist + slog[h];
            w = (w * s[h]) % p;

            ++numsteps;
        }

        if (power(g,wdist) == h) {
            return MainResult(numsteps, wdist, loop);
        }
    }
}