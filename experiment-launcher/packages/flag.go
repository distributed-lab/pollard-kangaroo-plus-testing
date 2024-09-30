package packages

import (
	"flag"
	"runtime"
)

const defaultConfigPath = "config.json"
const defaultBinPath = "binary/test"
const defaultLogFolder = "logs"
const defaultTableFolder = "tables"
const defaultTableSize = 48
const defaultSecretsPath = "binary/secrets.bin"

var defaultCpuNum = runtime.NumCPU() / 2

type Flags struct {
	CpuNum      int
	ConfigPath  string
	BinPath     string
	LogsDir     string
	TablesDir   string
	SecretsSize int
	SecretPath  string
}

// GetFlags get provided flags program flags.
//
// Note, that if no --cpu flag provided, it will be set to maximum number of threads
// divided by 2.
func GetFlags() Flags {
	cpuNum := flag.Int("cpu", defaultCpuNum, "Number of threads to run multiple tests in")
	configPath := flag.String("config", defaultConfigPath, "Path for generated config")
	binPath := flag.String("bin", defaultBinPath, "Path to test binary")
	logPath := flag.String("log", defaultLogFolder, "Directory with tests logs")
	tablePath := flag.String("table", defaultTableFolder, "Directory with tables")
	secretsSize := flag.Int("secrets-size", defaultTableSize, "Size of secrets to make tests on")
	secretsPath := flag.String("secrets-path", defaultSecretsPath, "Path to secrets .bin file")
	flag.Parse()

	return Flags{
		CpuNum:      *cpuNum,
		ConfigPath:  *configPath,
		BinPath:     *binPath,
		LogsDir:     *logPath,
		TablesDir:   *tablePath,
		SecretsSize: *secretsSize,
		SecretPath:  *secretsPath,
	}
}
