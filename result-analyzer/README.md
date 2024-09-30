# Result analyzer

Analyzes test logs and outputs top N file with logs by the best spent main time.

Run the next line to execute the program:
```shell
go run main.go
```

It is possible to provide additional flags:
- `top` - how many files should be outputted (10 by default);
- `log` - path to file with logs to analyze (`../experiment-launcher/logs` by default).

Under the hood, this program reads all .txt files in the provided folder, gets the last 
line and reads Total time.