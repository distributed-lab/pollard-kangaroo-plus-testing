# Experiment data generator

This program will help generate test cases based on the provided constants.

Running the following command

```sh 
go run main.go --secret-size 64 --config config.json
```

will generate `config.json` file for 64 bits size secrets. 

It is possible to provide additional flags:
- `--secret-size` - secret size in bytes (48 bytes by default);
- `--config` - path to a config file to be generated (config.json by default).

This file contains all combinations of the algorithm's configurable constants based on 
provided ranges and number of elements in the range.

## Changing parameters

### Secret size
Secret size is set up to 48 bits and can be changed whatever is needed by changing 
`secretSize` constant in [main.go](main.go) file.

### Algorithm constants

Algorithm constants that are **alpha**, **M**, **tame**, **r**, **i** and **d** can be 
configured in [constants.go](generator/constants.go) file.

Also, constant for ranges can be changed. Those are `NumberAlphas`, `NumberMs`, 
`NumberTames` etc. Note that setting not really high ranges will produce really vast 
amount of test cases. Assuming, that every range is set to 0, there will be produced
6^10 test cases that is equal to 60466176.

Config file also contains `tableNum` and `allowWriteTable`

## Optimisation
Since for most of the test cases some constants are repeated, generated tables on 
preprocessing step (most time-consuming) could be reused. For that purpose, some test 
cases has `allowWriteTable` flag set to `true`, which allows to create a table to be 
reused on tests with similar `tableNum` field and `allowWriteTable` flag set to `false`.

It helps to reduce number of preprocessing really well. For instance, for that ranges that 
are currently set instead of 221184 preprocessing it is needed 9216. Still, it is a huge 
number, however, it might help to save your time. Also note, that not for all variants it 
is possible to optimise number of preprocessing.

Note, that tests that require table generation and can't use pre generated tables (since 
they don't exist) will be put first in the config file and eventually launched first.
