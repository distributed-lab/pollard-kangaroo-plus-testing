cmake_minimum_required(VERSION 3.28)
project(dl-dlp-kangaroo-testing)

set(CMAKE_CXX_STANDARD 17)
add_executable(new_target source/main.cpp
        source/secrets.cpp
        headers/secrets.h
        source/secrets.cpp
        source/arguments.cpp
        headers/arguments.h
        source/table.cpp
        headers/table.h
        source/logger.cpp
        headers/logger.h
        source/kangaroo.cpp
        headers/kangaroo.h
        source/kangaroo.cpp)
