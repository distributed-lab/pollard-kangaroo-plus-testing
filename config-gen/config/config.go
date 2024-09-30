package config

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
)

type Config []ConfigElement

type ConfigElement struct {
	R               int64   `json:"r"`
	Alpha           float64 `json:"alpha"`
	M               float64 `json:"m"`
	Tame            int64   `json:"tame"`
	D               int64   `json:"d"`
	I               float64 `json:"i"`
	TableNum        int     `json:"tableNum"`
	AllowWriteTable bool    `json:"allowWriteTable"`
}

func (e Config) Write(path string) error {
	// Create or truncate the file
	file, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("failed to create a file: %v", err)
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	encoder := json.NewEncoder(writer)

	// Write the opening array bracket
	writer.WriteString("[")

	// Write a large amount of data as JSON
	for i, testCase := range e {
		// Write each object as a JSON element
		if err := encoder.Encode(testCase); err != nil {
			return fmt.Errorf("failed encoding JSON: %s", err)
		}

		// Optionally add a comma after each item except the last
		if i != len(e)-1 {
			writer.WriteString(",")
		}
	}

	// Write the closing array bracket
	writer.WriteString("]")

	// Flush the buffer to ensure all data is written to the file
	if err := writer.Flush(); err != nil {
		log.Fatalf("failed to flush buffer: %s", err)
	}

	return nil
}
