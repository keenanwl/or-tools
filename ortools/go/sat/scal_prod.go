package sat

type ScalProd struct {
	variables    []IntVar
	coefficients []int
}

func InitScalProd(variables []IntVar, coefficients []int) *ScalProd {

	return &ScalProd{
		variables:    variables,
		coefficients: coefficients,
	}

}

func Term(variable IntVar, coefficient int) *ScalProd {
	return InitScalProd([]IntVar{variable}, []int{coefficient})
}

func (s *ScalProd) NumElements() int {
	return len(s.variables)
}

func (s *ScalProd) Variable(index int) *IntVar {
	return &s.variables[index]
}

func (s *ScalProd) Coefficient(index int) int {
	return s.coefficients[index]
}
