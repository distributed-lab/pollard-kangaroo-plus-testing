package packages

import (
	"fmt"
	"os"
	"os/exec"
)

var flags = []string{"-r", "-a", "-m", "-i", "-t", "-d", "-l", "-p", "-w", "-s", "-b"}

func newRelativeTablePath(i int, tableDir string) string {
	return fmt.Sprintf("%s/table_%d.bin", tableDir, i)
}

func newRelativeLogPath(i int, logDir string) string {
	return fmt.Sprintf("%s/test-%d.txt", logDir, i)
}

// mergeFlags merges provided configurable parameters with flags for a test.
func mergeFlags(confElem ConfigElement, i, secretSize int, logsDir, tablesDir, secretsPath string) []string {
	var res []string

	res = append(res, flags[0])
	res = append(res, fmt.Sprintf("%d", confElem.R))

	res = append(res, flags[1])
	res = append(res, fmt.Sprintf("%f", confElem.Alpha))

	res = append(res, flags[2])
	res = append(res, fmt.Sprintf("%f", confElem.M))

	res = append(res, flags[3])
	res = append(res, fmt.Sprintf("%f", confElem.D))

	res = append(res, flags[4])
	res = append(res, fmt.Sprintf("%d", confElem.Tame))

	res = append(res, flags[5])
	res = append(res, fmt.Sprintf("%d", confElem.C))

	res = append(res, flags[6])
	res = append(res, newRelativeLogPath(i, logsDir))

	res = append(res, flags[7])
	res = append(res, newRelativeTablePath(i, tablesDir))

	boolVal := 0
	if confElem.AllowWriteTable {
		boolVal = 1
	}

	res = append(res, flags[8])
	res = append(res, fmt.Sprintf("%d", boolVal))

	res = append(res, flags[9])
	res = append(res, fmt.Sprintf("%d", secretSize))

	res = append(res, flags[10])
	res = append(res, secretsPath)

	return res
}

// RunBinary executes provided test binary with configuration flags.
func RunBinary(confElem ConfigElement, i, secretsSize int, binPath, logsDir, tablesDir, secretsPath string) error {
	fmt.Printf("\n\nRunning test #%d\n\n", i)
	cmd := exec.Command(binPath, mergeFlags(confElem, i, secretsSize, logsDir, tablesDir, secretsPath)...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
