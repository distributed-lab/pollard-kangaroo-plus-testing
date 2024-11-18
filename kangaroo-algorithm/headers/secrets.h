#ifndef SECRETS_DATA_H
#define SECRETS_DATA_H

#include <string>
#include <gmpxx.h>

struct SecretsData {
    mpz_class* secrets;
    size_t count;
};

SecretsData read_secrets(const std::string& filename);

#endif // SECRETS_DATA_H