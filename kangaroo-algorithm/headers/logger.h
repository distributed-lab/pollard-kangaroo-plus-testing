#ifndef KANGAROO___LOGGER_H
#define KANGAROO___LOGGER_H

#include <string>

void init_logger(std::string path);
bool log(const std::string& message);

#endif //KANGAROO___LOGGER_H
