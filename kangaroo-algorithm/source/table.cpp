#include <algorithm>
#include <iostream>
#include <gmpxx.h>
#include <fstream>
#include <string>
#include <getopt.h>
#include <vector>
#include <sstream>

#include "../headers/table.h"

std::vector<uint8_t> hexStringToBytes(const std::string& hex) {
    std::vector<uint8_t> bytes;
    for (size_t i = 0; i < hex.length(); i += 2) {
        std::string byteString = hex.substr(i, 2);
        uint8_t byte = static_cast<uint8_t>(strtol(byteString.c_str(), nullptr, 16));
        bytes.push_back(byte);
    }
    return bytes;
}

// Helper function to convert a byte array to a hex string
std::string bytesToHexString(const std::vector<uint8_t>& bytes) {
    std::ostringstream oss;
    for (uint8_t byte : bytes) {
        oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(byte);
    }
    return oss.str();
}

// Function to write data to a file
bool TableDataMap::writeToFile(std::string path) {
    std::ofstream outFile(path, std::ios::binary);
    if (!outFile) {
        std::cerr << "Error: Unable to open file for writing: " << path << std::endl;
        return false;
    }

    // Write the size of the map
    size_t mapSize = tableMap.size();
    outFile.write(reinterpret_cast<const char*>(&mapSize), sizeof(mapSize));

    // Write each entry in the map
    for (const auto& [key, entry] : tableMap) {
        // Convert the hex string key to bytes
        std::vector<uint8_t> keyBytes = hexStringToBytes(key);
        size_t keySize = keyBytes.size();
//        outFile.write(reinterpret_cast<const char*>(&keySize), sizeof(keySize));
        outFile.write(reinterpret_cast<const char*>(keyBytes.data()), keySize);

        // Serialize mpz_class log
        std::string logStr = entry.log.get_str(); // Serialize mpz_class as a string
        size_t logSize = logStr.size();

//        outFile.write(reinterpret_cast<const char*>(&logSize), sizeof(logSize));
        outFile.write(logStr.c_str(), logSize);
    }

    for (int i = 0; i < 64; i++) {
        outFile.write(reinterpret_cast<const char*>(this->s[i]), 32);
        outFile.write(reinterpret_cast<const char*>(this->slog[i]), 4);
    }

    outFile.close();
    return true;
}

// Function to read data from a file
bool TableDataMap::readFromFile(const std::string path) {
    std::ifstream inFile(path, std::ios::binary);
    if (!inFile) {
        std::cerr << "Error: Unable to open file for reading: " << path << std::endl;
        return false;
    }

    // Clear the current map
    tableMap.clear();

    // Read the size of the map
    size_t mapSize;
    inFile.read(reinterpret_cast<char*>(&mapSize), sizeof(mapSize));

    // Read each entry in the map
    for (size_t i = 0; i < mapSize; ++i) {
        size_t keySize;
        inFile.read(reinterpret_cast<char*>(&keySize), sizeof(keySize));
        std::vector<uint8_t> keyBytes(keySize);
        inFile.read(reinterpret_cast<char*>(keyBytes.data()), keySize);

        // Convert the byte array back to a hex string
        std::string key = bytesToHexString(keyBytes);

        // Deserialize mpz_class log
        size_t logSize;
        inFile.read(reinterpret_cast<char*>(&logSize), sizeof(logSize));
        std::string logStr(logSize, '\0');
        inFile.read(&logStr[0], logSize);
        mpz_class log(logStr);

        // Insert the read values into the map
        tableMap[key] = TableEntryMap{log};
    }

    inFile.close();
    return true;
}
