#ifndef KANGAROO___ARGUMENTS_H
#define KANGAROO___ARGUMENTS_H

#include <string>

struct ParsedArgs {
    long r;
//    double alpha;
    double m;
    double i;
//    long t;
    long n;
    long w;
//    long rat;
    std::string log_path;
    std::string table_path;
    bool allow_write_table;
    int secret_size;
    std::string secret_path;
};

ParsedArgs parse_args(int argc, char *argv[]);
#endif //KANGAROO___ARGUMENTS_H
