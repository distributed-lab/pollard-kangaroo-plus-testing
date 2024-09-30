package main

import (
	"crypto/rand"
	"fmt"
	"math/big"
	"os"
	"secret-generator/flags"
	"secret-generator/writer"
	"strings"
)

func main() {
	f := flags.GetFlags()

	if !strings.HasSuffix(f.SecretsPath, ".bin") {
		println("secrets filename extension should be .bin")
		return
	}

	if f.SecretSize == 0 {
		println("Secret size should be more than 0")
		return
	}

	if f.SecretAmount == 0 {
		println("Amount of secrets should be more than 0")
		return
	}

	file, err := os.Create(f.SecretsPath)
	if err != nil {
		fmt.Println("Error creating file:", err)
		return
	}
	defer file.Close()

	fmt.Printf("Started generating %d secrets of size %d into %s\n", f.SecretAmount, f.SecretSize, f.SecretsPath)

	err = writer.WriteNumberOfSecrets(file, f.SecretAmount)
	if err != nil {
		fmt.Printf("Failed to write number of secrets: %v\n", err)
		return
	}

	for i := 0; i < f.SecretAmount; i++ {
		secret := new(big.Int).Lsh(big.NewInt(1), uint(f.SecretSize))

		// Generate a random big.Int between 0 and max-1
		n, err := rand.Int(rand.Reader, secret)
		if err != nil {
			fmt.Println("Failed to generate a random number:", err)
			return
		}

		err = writer.WriteSecret(file, n)
		if err != nil {
			fmt.Printf("Failed to write a secret: %v\n", err)
			return
		}
	}

	fmt.Printf("%d secrets of size %d successfullt generated!\n", f.SecretAmount, f.SecretSize)
}
