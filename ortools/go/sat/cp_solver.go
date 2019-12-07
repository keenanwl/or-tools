package sat

import "ortools/go/sat/gen"

type cpSolver struct {
	solveParameters *gen.CpModelProto
}

func (s *cpSolver) Solve(model CpModel) gen.CpSolverResponse {

	return gen.SatHelperSolve(*model.proto)

}
