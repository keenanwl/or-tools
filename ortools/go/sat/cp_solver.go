package sat

import "or-tools/ortools/go/gen"

type cpSolver struct {
	solveParameters *gen.CpModelProto
}

func (s *cpSolver) Solve(model cpModel) gen.CpSolverResponse {

	return gen.SatHelperSolve(*model.proto)

}
