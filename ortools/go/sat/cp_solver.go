package sat

import (
	"fmt"

	"ortools/go/sat/gen"
)

type CpSolver struct {
	solveParameters *gen.CpModelProto
}

type CpSolverResponse gen.CpSolverResponse

func NewCpSolver() *CpSolver {
	return &CpSolver{}
}

func (s *CpSolver) Solve(model CpModel) gen.CpSolverResponse {

	//fmt.Println(model.proto.String())
	allSolutions := false
	return gen.SatHelperSolveWithParameters(*model.proto, gen.SatParameters{
		EnumerateAllSolutions: &allSolutions,
	})

}

type GoCallback interface {
	gen.SolutionCallback
	deleteCallback()
	IsGoCallback()
}
type goCallback struct {
	gen.SolutionCallback
}

func (p *goCallback) deleteCallback() {
	DeleteDirectorSolutionCallback(p)
}

func (p *goCallback) IsGoCallback() {}

type overwrittenMethodsOnCallback struct {
	p        gen.SolutionCallback
	callback func(response CpSolverResponse)
}

func (om *overwrittenMethodsOnCallback) OnSolutionCallback() {

	om.callback(CpSolverResponse(om.p.Response()))

}

func NewGoCallback(callback func(response CpSolverResponse)) GoCallback {
	om := &overwrittenMethodsOnCallback{callback: callback}
	p := gen.NewDirectorSolutionCallback(om)
	om.p = p

	return &goCallback{SolutionCallback: p}
}

func DeleteDirectorSolutionCallback(p GoCallback) {
	p.deleteCallback()
}

func (p *overwrittenMethodsOnCallback) Run() {
	fmt.Println("GoCallback.Run")
}

func (s *CpSolver) SolveAllSolutions(model CpModel, callback func(response CpSolverResponse)) CpSolverResponse {

	cb := NewGoCallback(callback)

	allSolutions := true
	se := gen.SatHelperSolveWithParametersAndSolutionCallback(
		*model.proto,
		gen.SatParameters{
			EnumerateAllSolutions: &allSolutions,
		},
		cb,
	)

	return CpSolverResponse(se)

}
