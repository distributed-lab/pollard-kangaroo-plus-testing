#include <iostream>
#include <fstream>
#include <string>

#include "../headers/logger.h"

std::string log_path = "logs";

// Initializes a path to a file for logs. Note, that this function needs to be run before log() functions.
void init_logger(std::string path) {
    log_path = path;
}

// Logs a message into stdout and to a file.
bool log(const std::string& message) {
    std::cout << message << std::endl;

    std::ofstream file(log_path, std::ios::app);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << log_path << " for writing." << std::endl;
        return false;
    }

    file << message << std::endl;

    file.flush();
    file.close();

    return true;
}