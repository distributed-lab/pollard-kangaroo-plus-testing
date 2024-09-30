package writer

import (
	"encoding/binary"
	"errors"
	"fmt"
	"math/big"
	"os"
)

func WriteNumberOfSecrets(file *os.File, secretsNum int) error {
	count := uint64(secretsNum)
	err := binary.Write(file, binary.BigEndian, count)
	if err != nil {
		return errors.New(fmt.Sprintf("failed to write a number of secrets: %v", err))
	}

	return nil
}

func WriteSecret(file *os.File, num *big.Int) error {
	bigIntBytes := num.Bytes()

	// Write the size of the byte slice (size_t equivalent)
	strSize := uint64(len(bigIntBytes))
	err := binary.Write(file, binary.BigEndian, strSize)
	if err != nil {
		return errors.New(fmt.Sprintf("failed to write num size: %v", err))
	}

	// Write the actual byte slice (the "string" content)
	_, err = file.Write(bigIntBytes)
	if err != nil {
		return errors.New(fmt.Sprintf("failed to write num: %v", err))
	}

	return nil
}
