package sat

import (
	"fmt"

	genSat "ortools/gen/ortools/go/sat"
)

type CpSolver struct {
	solveParameters *genSat.CpModelProto
}

type CpSolverResponse genSat.CpSolverResponse

func NewCpSolver() *CpSolver {
	return &CpSolver{}
}

func (s *CpSolver) Solve(model CpModel) genSat.CpSolverResponse {

	//fmt.Println(model.proto.String())
	allSolutions := false
	return genSat.SatHelperSolveWithParameters(*model.proto, genSat.SatParameters{
		EnumerateAllSolutions: &allSolutions,
	})

}

type GoCallback interface {
	genSat.SolutionCallback
	deleteCallback()
	IsGoCallback()
}
type goCallback struct {
	genSat.SolutionCallback
}

func (p *goCallback) deleteCallback() {
	DeleteDirectorSolutionCallback(p)
}

func (p *goCallback) IsGoCallback() {}

type overwrittenMethodsOnCallback struct {
	p        genSat.SolutionCallback
	callback func(response CpSolverResponse)
}

func (om *overwrittenMethodsOnCallback) OnSolutionCallback() {

	om.callback(CpSolverResponse(om.p.Response()))

}

func NewGoCallback(callback func(response CpSolverResponse)) GoCallback {
	om := &overwrittenMethodsOnCallback{callback: callback}
	p := genSat.NewDirectorSolutionCallback(om)
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
	se := genSat.SatHelperSolveWithParametersAndSolutionCallback(
		*model.proto,
		genSat.SatParameters{
			EnumerateAllSolutions: &allSolutions,
		},
		cb,
	)

	return CpSolverResponse(se)

}
