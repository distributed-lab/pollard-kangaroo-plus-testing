cmake_minimum_required(VERSION 3.28)
project(kangaroo_algorithm)

set(CMAKE_CXX_STANDARD 14)

include_directories(headers /opt/homebrew/include)

add_executable(kangaroo_algorithm
        headers/arguments.h
        headers/kangaroo.h
        headers/logger.h
        headers/secrets.h
        headers/table.h
        source/arguments.cpp
        source/kangaroo.cpp
        source/logger.cpp
        source/main.cpp
        source/secrets.cpp
        source/table.cpp)
