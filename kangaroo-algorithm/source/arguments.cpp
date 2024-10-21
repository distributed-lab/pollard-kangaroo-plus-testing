#include <iostream>
#include <getopt.h>
#include <cstdlib>

#include "../headers/arguments.h"

ParsedArgs parse_args(int argc, char *argv[]) {
    ParsedArgs args = {};

    static struct option long_options[] = {
            {"r", required_argument, nullptr, 'r'},
            {"m", required_argument, nullptr, 'm'},
            {"i", required_argument, nullptr, 'i'},
            {"n", required_argument, nullptr, 'n'},
            {"w", required_argument, nullptr, 'w'},
            {"log-path", required_argument, nullptr, 'l'},
            {"table-path", required_argument, nullptr, 'p'},
            {"allow-write-table", required_argument, nullptr, 't'},
            {"secret-size", required_argument, nullptr, 's'},
            {"secrets-bin", required_argument, nullptr, 'b'},
    };

    int opt;
    int long_index = 0;
    while ((opt = getopt_long(argc, argv, "r:m:i:n:w:l:p:t:s:b:", long_options, &long_index)) != -1) {
        switch (opt) {
            case 'r':
                args.r = std::strtol(optarg, nullptr, 10);
                break;
            case 'm':
                args.m = std::strtod(optarg, nullptr);
                break;
            case 'i':
                args.i = std::strtod(optarg, nullptr);
                break;
            case 'n':
                args.n = std::strtol(optarg, nullptr, 10);
                break;
            case 'w':
                args.w = std::strtol(optarg, nullptr, 10);
                break;
            case 'l':
                args.log_path = optarg;
                break;
            case 'p':
                args.table_path = optarg;
                break;
            case 't': {
                long allow_write_num = std::strtol(optarg, nullptr, 10);
                args.allow_write_table = allow_write_num != 0;
                break;
            }
            case 's':
                args.secret_size = std::strtol(optarg, nullptr, 10);
                break;
            case 'b':
                args.secret_path = optarg;
                std::cout << args.secret_path << std::endl;
                break;
            default:
                exit(EXIT_FAILURE);
        }
    }

    return args;
}
