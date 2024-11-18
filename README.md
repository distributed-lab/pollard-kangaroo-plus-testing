# 🦘 Testing the usage of enhanced Pollard's kangaroo algorithm for solving DLP faster

This repository provides tools for launching a series of tests and combining different 
constants for the enhanced Pollard's kangaroo algorithm. The algorithm is used from 
[this](https://cr.yp.to/dlog/cuberoot.html) article.

## Steps to launch an experiment

### 1. Generating secrets 

For launching an experiment it is required to generate some amount of secrets to launch 
tests on. These are simply random numbers of some length. This can be done be using
[secret-gen](secret-generator). Go to the config-gen folder and launch the following 
command to generate 200 64-bit secrets:

```shell
go run main.go --size 64 --amount 200 --path secrets.bin
```

This command will generate secrets.bin file with 200 64-bit secrets.

### 2. Generating experiment configurable file

For testing the algorithm on different constants mix [config-gen](config-gen) can be used.
It mixes all provided constants creating unique tuples and writes them into .json file.

To create own configurable file go to [constants.go](config-gen/generator/constants.go) 
file and change constants number and ranges. Constant number defines how many constants 
there should be in a specific range. For example, setting `MinTame` to 10, `MaxTame` to 20
and `NumberTames` to 5 will generate 5 different tames in range from 10 to 20.

Launch the next command to generate config.json file with provided constants for 64-bit 
size secrets.

```shell
go run main.go --secret-size 64 --config conf.json
```

The program also produces some kind of optimisation on preprocessing number which can be 
read [here](config-gen/README.md#optimisation).

### 3. Creating the test binary

For launching an experiment with constants above, use 
[kangaroo-algorithm](kangaroo-algorithm). The program requires the presence of installed
gmpxx package (you can read about the installation 
[here](kangaroo-algorithm/README.md#prerequisites)).

Launch the following command to generate a binary executable file called `test`:

```shell
g++ -std=c++2b -O3 -fomit-frame-pointer -o test source/* -lgmpxx -lgmp
```

### 4. Launching an experiment

Use [experiment-launcher](experiment-launcher) to launch the whole experiment.

Move `test` and `secrets.bin` into [binary](experiment-launcher/binary) folder and 
`config.json` file into the [root](experiment-launcher).

Run the following command to launch an experiment:

```shell
go run main.go --cpu 12 --secrets-size 64
```

This command will start an experiment using 12 threads and output logs into 
[logs](experiment-launcher/logs) folder. Tables will be generated into
[tables](experiment-launcher/tables) folder. Folders with logs, tables, binary test file 
and secrets are configurable and can be changed with flags that are stated in 
[README.md](experiment-launcher/README.md) file.

### 5. Analyzing results

Time result could be analyzed using [result-analyzer](result-analyzer). Run the following
command:

```shell
go run main.go --top 10 --log ./experiment-launcher/logs
```

This command will analyze logs, find time results and output top 10 log files with best 
results.

