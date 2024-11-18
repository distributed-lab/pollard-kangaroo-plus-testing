package flags

import "flag"

const defaultSecretsSize = 48
const defaultSecretsAmount = 10
const defaultSecretsPath = "secrets.bin"

type Flags struct {
	SecretSize   int
	SecretAmount int
	SecretsPath  string
}

// GetFlags get provided flags program flags.
//
// Not that for the next fields default values are:
//   - SecretSize - 48 bits
//   - SecretAmount - 10
func GetFlags() Flags {
	size := flag.Uint("size", defaultSecretsSize, "Secret size (in bits)")
	amount := flag.Uint("amount", defaultSecretsAmount, "Amount of secrets to be generated")
	path := flag.String("path", defaultSecretsPath, "Path for secrets to be generated")
	flag.Parse()

	return Flags{
		SecretSize:   int(*size),
		SecretAmount: int(*amount),
		SecretsPath:  *path,
	}
}
