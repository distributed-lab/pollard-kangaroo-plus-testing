# Experiment launcher

This program is used to launch an experiment that consists of multiple tests defined in
`.json` config file.

To launch the experiment type 

```shell
go run main.go --cpu 12 --secrets-size 64
```

This command will read `config.json` file in the root folder, provide read values as flags
to a binary file by `binary/test` path and distribute test executions among provided 
threads. For instance, if number of tests in `config.json` is 1000, it is possible to 
launch 1 test for 1 CPU at a time and if you have 16 available CPUs, you can run 16 tests
in a time.

It is possible to provide flags to change some variables like:
- `--cpu` - number of threads for tests to be executed (it is set to maximum number of 
CPUs divided by 2 by default);
- `--config` - path to config file with test parameters (`config.json` by default);
- `--bin` - path to an executable test file (`binary/test` by default);
- `--log` - path to directory of tests logs (`logs` by default);
- `--table` - path to directory of generated tables (`table` by default).
- `--secrets-size` - size of generated secrets (48 by default).
- `--secrets-path` - path to directory of generated tables (`binary/secrets.bin` by default).

Note that to launch a test, you need a generated file with secrets that must be placed 
within test executable file (in `binary` directory by default).

## Boundaries

Since for every test a pre generated table is needed, there should be enough free space
on disk as well as RAM. Assume that a single test parameter N (which states for a number 
of entries in the table) is set to 100000. Then, it is required 100000 * 40 = 4000000 
bytes of space or 400 kilobytes. Even though this is not too much for a modern computer, 
for bigger secrets the size of the table will grow.
