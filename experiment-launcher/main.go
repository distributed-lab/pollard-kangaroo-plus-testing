package main

import (
	"fmt"
	"os"
	"sync"
	"test-launcher/packages"
	"time"
)

// ConfWrapper is a wrapper around packages.ConfigElement that is used for execution of
// numerous tests in multiple threads
type ConfWrapper struct {
	packages.ConfigElement
	TestNum int
}

func isDirExists(path string) bool {
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		return true
	}
	return info.IsDir()
}

func initTestDir(logDir string) {
	if !isDirExists(logDir) {
		err := os.Mkdir(fmt.Sprintf("../%s", logDir), os.ModePerm)
		if err != nil {
			panic(err)
		}
	}
}

func main() {
	// Gte provided flags
	flags := packages.GetFlags()

	// Create directories if missing
	initTestDir(flags.LogsDir)
	initTestDir(flags.TablesDir)

	// Read config file for tests
	conf, err := packages.ReadConfigData(flags.ConfigPath)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Printf("Running %d workers at a time\n", flags.CpuNum)

	start := time.Now()

	var wg sync.WaitGroup
	confQueue := make(chan ConfWrapper)

	// Start workers
	for i := 0; i < flags.CpuNum; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for binConf := range confQueue {
				err = packages.RunBinary(binConf.ConfigElement, binConf.TestNum,
					flags.SecretsSize, flags.BinPath, flags.LogsDir, flags.TablesDir,
					flags.SecretPath)

				if err != nil {
					fmt.Println(err)
					return
				}
			}
		}(i + 1)
	}

	// Send messages to the queue
	for i, c := range conf {
		confQueue <- ConfWrapper{
			c,
			i,
		}
	}
	close(confQueue) // Close the channel when all messages are sent

	// Wait for all workers to finish
	wg.Wait()

	elapsed := time.Since(start)

	fmt.Println("All tasks completed")
	fmt.Printf("Time spent: %s\n", elapsed)
}
