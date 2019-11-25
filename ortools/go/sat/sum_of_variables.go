package sat

type SumOfVariables struct {
	variables []IntVar
}

func InitSumOfVariables(variables []IntVar) *SumOfVariables {
	return &SumOfVariables{
		variables: variables,
	}
}

func (s *SumOfVariables) SetVariables(variables []IntVar) {
	s.variables = variables
}

func (s *SumOfVariables) NumElements() int {
	return len(s.variables)
}

func (s *SumOfVariables) Variable(index int) *IntVar {
	return &s.variables[index]
}

func (s *SumOfVariables) Coefficient(index int) int {
	return 1
}

func (s *SumOfVariables) Sum(variables []IntVar) *SumOfVariables {
	return &SumOfVariables{
		variables: variables,
	}
}

func (s *SumOfVariables) ScalProd(variables []IntVar, coefficients []int) *ScalProd {
	return InitScalProd(variables, coefficients)
}

func (s *SumOfVariables) Term(variable IntVar, coefficient int) *ScalProd {
	return InitScalProd([]IntVar{variable}, []int{coefficient})
}
