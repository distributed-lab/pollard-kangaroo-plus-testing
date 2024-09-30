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
	Alpha           float64 `json:"alpha"`
	M               float64 `json:"m"`
	Tame            int64   `json:"tame"`
	C               int64   `json:"c"`
	D               float64 `json:"d"`
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
