# Kangaroo algorithm

## Prerequisites

Since gmpxx is used for arithmetic on large numbers, you need to install it locally. Follow the steps that are written 
in [this](http://rstudio-pubs-static.s3.amazonaws.com/493124_a46782f9253a4b8193595b6b2a037d58.html) article for 
installing gmpxx for the desired OS.

## Launching a test

To compile the program run the following line:

```shell
g++ -std=c++2b -O3 -fomit-frame-pointer -o test source/* -lgmpxx -lgmp
```

This command will compile the code that is located in `source` directory and create `test` binary. Move this binary to 
the desired folder which will be used for launching an experiment with series of tests (see 
[experiment-launcher](../experiment-launcher)). 

It is possible to launch a binary without experiment-launcher program. All you need is to provide the next flags:
- `-r` - number of slog-s to generate (R value);
- `-a` - multiplier for defining the number of so-called `wild kangaroos` (W value);
- `-m` - multiplier of an upper secret bound on a preprocessing stage;
- `-i` - number of iterations for one loop;
- `-t` - number of so-called 'tame kangaroos' (T value);
- `-d` - N/T ratio;
- `-l` - a path to locate test logs;
- `-p` - a path to locate a generated table;
- `-w` - allow to generate and write a table (0 - do not allow, 1 - allow);
- `-s` - size of a secret;
- `-b` - a path to a binary with secrets.

An example of such a command with all above arguments is listed below.

```shell
./test -r 128 -a 1.000000 -m 0.500000 -d 4.000000 -t 8192 -c 8 -l logs/test-0.txt -p tables/table_0.bin -w 1 -s 48 
-b binary/secrets.bin
```

## Functionality

The program runs a test with a provided arguments. It launches a preprocessing (if it is indicated by the flag) or reads
an existing table by a provided path. Then, it launches main computations and outputs time and iterations results. 
Main computations are run on secrets provided in .bin file. All logs that the program produces are outputted into 
stdout and .txt file and could be viewed later.