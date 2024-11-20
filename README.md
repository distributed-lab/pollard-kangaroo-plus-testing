# Vite + TS implementation of Pollar's kangaroo algorithm using web workers.

## Starting the backend server
Backend server is used for fetching and storing a generated table. Table are stored in .json files for simplicity. Logs are stored in `logs` folder.

Tables and logs file names have the next structure: `name_w_n_secret.ext`.
- name - file name (**output** for tables and log for **logs**);
- w - W constant;
- n - N constant;
- n - N constant;
- secret - secret size;
- ext - file extension (**.json** for tables and **txt** for logs) ;

To run the server go to the `table-server` and run the next command:

```shell
go run main.go
```

This command will launch the backend server on :3001 port.



## Starting the web server 

To install depending packages, run
```shell
npm i
```

To build launch the web server, run
```shell
vite build
vite preview
```