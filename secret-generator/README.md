# Secret generator
The program is used for generating some number of N bit secrets.

Use the following command to generate 200 64-bit secrets:

```shell
go run main.go --size 64 --amount 200 --path secrets.bin
```

This command will generate secrets.bin file with 200 64-bit secrets.