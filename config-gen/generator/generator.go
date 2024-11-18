package generator

func GenFloats64(min float64, max float64, elements int64) []float64 {
	values := make([]float64, elements)

	for i := int64(0); i < elements; i++ {
		values[i] = min + (float64(i) * (max - min) / float64(elements-1))
	}

	return values
}

func GenInts64(min int64, max int64, elements int64) []int64 {
	values := make([]int64, elements)

	for i := int64(0); i < elements; i++ {
		values[i] = min + (i * (max - min) / int64(elements-1))
	}

	return values
}

func GenWs(w int64, elements int64) []int64 {
	values := make([]int64, elements)

	for i := int64(1); i <= elements; i++ {
		values[i-1] = w * i
	}

	return values
}
