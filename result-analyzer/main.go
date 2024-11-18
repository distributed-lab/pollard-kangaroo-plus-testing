package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"result-analyzer/flags"
	"sort"
	"strconv"
	"strings"
)

type FileStat struct {
	FileName  string
	TotalTime int
}

func main() {
	f := flags.GetFlags()

	if f.TopNumber == 0 {
		println("So, you really want to output top 0 files? Bruuh...")
		return
	}

	files, err := os.ReadDir(f.LogDir)
	if err != nil {
		fmt.Println("Error reading directory:", err)
		return
	}

	var fileTimes []FileStat

	// Regex to match the Total time line
	re := regexp.MustCompile(`Total time:\s*(\d+)\s*ms`)

	for _, file := range files {
		if filepath.Ext(file.Name()) == ".txt" {
			filePath := filepath.Join(f.LogDir, file.Name())
			data, err := os.ReadFile(filePath)
			if err != nil {
				fmt.Printf("Error reading file %s: %v\n", file.Name(), err)
				continue
			}

			// Split the data into lines and look for the last occurrence of the total time
			lines := strings.Split(string(data), "\n")
			for i := len(lines) - 1; i >= 0; i-- {
				line := lines[i]
				if matches := re.FindStringSubmatch(line); matches != nil {
					totalTime, err := strconv.Atoi(matches[1])
					if err == nil {
						fileTimes = append(fileTimes, FileStat{FileName: file.Name(), TotalTime: totalTime})
					}
					break // Found the last occurrence, break the loop
				}
			}
		}
	}

	// Sort the files by total time
	sort.Slice(fileTimes, func(i, j int) bool {
		return fileTimes[i].TotalTime < fileTimes[j].TotalTime
	})

	// Output the top 10 files with lowest total time
	if len(fileTimes) != 0 {
		fmt.Printf("Top %d files with lowest total time:\n", f.TopNumber)
		fmt.Printf("%-30s %s\n", "File Name", "Total Time (ms)")
		fmt.Println(strings.Repeat("-", 50))
		for i, fileTime := range fileTimes {
			if i >= 10 {
				break
			}
			fmt.Printf("%-30s %d\n", fileTime.FileName, fileTime.TotalTime)
		}
	} else {
		fmt.Printf("No logs found in %s\n", f.LogDir)
	}

}
