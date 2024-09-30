package flags

import "flag"

const defaultSecretSize = 48
const defaultConfigPath = "config.json"

type Flags struct {
	SecretSize int64
	ConfigPath string
}

// GetFlags get provided flags program flags.
//
// Not that for the next fields default values are:
//   - SecretSize - 48 bits
//   - ConfigPath - "config.json"
func GetFlags() Flags {
	secretSize := flag.Uint("secret-size", defaultSecretSize, "Size of secret to generate config for")
	configPath := flag.String("config", defaultConfigPath, "Path for generated config")
	flag.Parse()

	return Flags{
		SecretSize: int64(*secretSize),
		ConfigPath: *configPath,
	}
}
