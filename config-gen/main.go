package main

import (
	"config-gen/config"
	"config-gen/flags"
	"config-gen/generator"
	"fmt"
	"math/big"
)

// WData used for reducing number of computation as serves as temporary structure for
// storing information.
type WData struct {
	D    int64 // N / T rate
	W    int64
	M    float64 // slog upper bound range multiplier
	R    int64   // Number of slogs for preprocessing
	Tame int64
}

// calculateW calculates W parameter by the next formula: alpha * sqrt(l/t)
func calculateW(alpha float64, l *big.Int, t int64) int64 {
	lFloat := new(big.Float).SetInt(l)
	lFloat.Quo(lFloat, big.NewFloat(float64(t)))
	result := new(big.Float).Sqrt(lFloat)
	result.Mul(result, big.NewFloat(alpha))
	finalResult, _ := result.Int64()
	return finalResult
}

func main() {
	f := flags.GetFlags()

	l := new(big.Int).Exp(big.NewInt(2), big.NewInt(f.SecretSize), nil)

	fmt.Printf("For %d bit secret l is %s\n", f.SecretSize, l.String())
	fmt.Printf("Config will be generated into %s\n", f.ConfigPath)

	// Generate ranges of configurable constants
	alphas := generator.GenFloats64(generator.MinAlpha, generator.MaxAlpha, generator.NumberAlphas)
	ms := generator.GenFloats64(generator.MinM, generator.MaxM, generator.NumberMs)
	is := generator.GenFloats64(generator.MinI, generator.MaxI, generator.NumberIs)
	tames := generator.GenInts64(generator.MinTame, generator.MaxTame, generator.NumberTames)
	ds := generator.GenInts64(generator.MinD, generator.MaxD, generator.NumberDs)
	rs := generator.GenInts64(generator.MinR, generator.MaxR, generator.NumberRs)

	println("Generating", generator.GeneralNumber, "variants")

	var tableGenConfigs config.Config
	var tableUseConfigs config.Config

	usefulCounter := 0
	var wCounter = make(map[WData]int)
	for _, alpha := range alphas {
		for _, m := range ms {
			for _, i := range is {
				for _, tame := range tames {
					for _, d := range ds {
						for _, r := range rs {
							newElem := config.ConfigElement{
								Alpha: alpha,
								M:     m,
								I:     i,
								Tame:  tame,
								D:     d,
								R:     r,
							}

							w := calculateW(alpha, l, tame)
							elem := WData{
								W:    w,
								D:    d,
								M:    m,
								R:    r,
								Tame: tame,
							}

							wElem, isFound := wCounter[elem]
							if !isFound {
								tableGenConfigs = append(tableGenConfigs, newElem)
								preprCombInd := len(tableGenConfigs) - 1
								wCounter[elem] = preprCombInd

								tableGenConfigs[preprCombInd].AllowWriteTable = true
								tableGenConfigs[preprCombInd].TableNum = usefulCounter
								usefulCounter++
							} else {
								tableUseConfigs = append(tableUseConfigs, newElem)
								tableUseConfigs[len(tableUseConfigs)-1].TableNum = wElem
							}
						}
					}
				}
			}
		}
	}

	tableUseConfigs = append(tableGenConfigs, tableUseConfigs...)

	fmt.Printf("Generation completed. It is needed to perform %d "+
		"preprocessings from %d\n", usefulCounter, len(tableUseConfigs))

	err := tableUseConfigs.Write(f.ConfigPath)
	if err != nil {
		fmt.Println(err)
		return
	}

	println("Successfully generated", len(tableUseConfigs), "tableUseConfigs")
}
