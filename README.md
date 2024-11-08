# Vite + TS implementation of Pollar's kangaroo algorithm using web workers.

## Starting the backend server
Backend server is used for fetching and storing a generated table. Table are stored in .json files for simplicity.

To run the server go to the `table-server` and run the next command:

```shell
go run main.go
```

This command will launch the backend server on :3000 port.

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