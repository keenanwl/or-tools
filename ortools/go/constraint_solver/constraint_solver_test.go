package constraint_solver

//func Test_RabbitsPheasants(t *testing.T) {
//
//	parameters := gen.SolverDefaultSolverParameters()
//	parameters.TraceSearch = true
//
//	solver := gen.NewSolver("Solver1", parameters)
//	rabbits := solver.MakeIntVar(int64(0), int64(100), "Rabbits")
//	pheasants := solver.MakeIntVar(int64(0), int64(100), "Pheasants")
//
//	args := []gen.IntVar{
//		*rabbits,
//		*pheasants,
//	}
//
//	args2 := make([]gen.IntVar, 2)
//	copy(args2, args)
//
//	//fmt.Println(args2)
//	/*
//		r := args[0]
//		_, ok := r.(gen.IntExpr)
//		fmt.Printf("%T\n", ok)*/
//
//	//solver.addConstraint(solver.makeEquality(solver.makeSum(rabbits, pheasants), 20));
//	solver.AddConstraint(solver.MakeEquality(solver.MakeSum(args2), int64(20)))
//	solver.AddConstraint(
//		solver.MakeEquality(
//			solver.MakeSum(
//				solver.MakeProd(rabbits, int64(4)),
//				solver.MakeProd(pheasants, int64(2)),
//			),
//			int64(56),
//		),
//	)
//
//	db := solver.MakePhase(rabbits, pheasants, gen.SolverCHOOSE_FIRST_UNBOUND, gen.SolverASSIGN_MIN_VALUE)
//	solver.NewSearch(db)
//	solver.NextSolution()
//
//	t.Logf("Rabbits: %v", rabbits)
//	t.Logf("Pheasants: %v", pheasants)
//
//}
