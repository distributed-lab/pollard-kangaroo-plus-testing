package flags

import "flag"

const defaultLogDir = "../experiment-launcher/logs"
const defaultTopNum = 10

type Flags struct {
	LogDir    string
	TopNumber int
}

// GetFlags get provided flags program flags.
//
// Not that for the next fields default values are:
//   - LogDir - ../experiment-launcher/logs
func GetFlags() Flags {
	logDir := flag.String("log", defaultLogDir, "Path for test logs")
	topNum := flag.Uint("top", defaultTopNum, "Number of top files to output")
	flag.Parse()

	return Flags{
		LogDir:    *logDir,
		TopNumber: int(*topNum),
	}
}
