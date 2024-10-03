#include <gmpxx.h>
#include <fstream>
#include <iostream>
#include <vector>

#include "../headers/secrets.h"

// Function to read SecretsData from a file
SecretsData read_secrets(const std::string& filename) {
    SecretsData secretsData;
    secretsData.count = 0;
    std::ifstream ifs(filename, std::ios::binary);
    if (!ifs) {
        throw std::runtime_error("Could not open file for reading.");
    }

    ifs.read(reinterpret_cast<char*>(&secretsData.count), 8);
    secretsData.secrets = new mpz_class[secretsData.count];
    for (size_t i = 0; i < secretsData.count; ++i) {
        size_t secret_size;
        ifs.read(reinterpret_cast<char*>(&secret_size), sizeof(secret_size));

        std::vector<unsigned char> secret_buff(secret_size);
        ifs.read(reinterpret_cast<char*>(secret_buff.data()), secret_size);

        mpz_class secret;
        mpz_import(secret.get_mpz_t(), secret_buff.size(), 1, 1, 0, 0, secret_buff.data());

        secretsData.secrets[i] = mpz_class(secret);
    }
    ifs.close();
    return secretsData;
}