#include <gmpxx.h>
#include <fstream>

#include "../headers/secrets.h"

// Function to read SecretsData from a file
SecretsData read_secrets(const std::string& filename) {
    SecretsData secretsData;
    secretsData.count = 0;
    std::ifstream ifs(filename, std::ios::binary);
    if (!ifs) {
        throw std::runtime_error("Could not open file for reading.");
    }

    ifs.read(reinterpret_cast<char*>(&secretsData.count), sizeof(secretsData.count));

    secretsData.secrets = new mpz_class[secretsData.count];
    for (size_t i = 0; i < secretsData.count; ++i) {
        size_t str_size;
        ifs.read(reinterpret_cast<char*>(&str_size), sizeof(str_size));
        std::string str(str_size, '\0');
        ifs.read(&str[0], str_size);
        secretsData.secrets[i] = mpz_class(str);
    }
    ifs.close();
    return secretsData;
}