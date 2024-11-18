package packages

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
)

type Config []ConfigElement

type ConfigElement struct {
	R               int64   `json:"r"`
	M               float64 `json:"m"`
	I               float64 `json:"i"`
	N               int64   `json:"n"`
	W               int64   `json:"w"`
	TableNum        int     `json:"tableNum"`
	AllowWriteTable bool    `json:"allowWriteTable"`
}

func ReadConfigData(configFile string) (Config, error) {
	// Read the JSON config file
	configData, err := os.ReadFile(configFile)
	if err != nil {
		return Config{}, errors.New(fmt.Sprintf("Error reading config file: %v", err))
	}

	// Parse the JSON into a slice of Config structs
	var data Config
	err = json.Unmarshal(configData, &data)
	if err != nil {
		return Config{}, errors.New(fmt.Sprintf("Error parsing config file: %v", err))
	}

	return data, nil
}
