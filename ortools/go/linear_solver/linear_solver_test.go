package linear_solver

import (
	"errors"
	"fmt"
	"math"
	"os"
	"os/signal"
	"syscall"
	"testing"

	genLinearSolver "ortools/gen/ortools/go/linear_solver"
)

func recoverGlog() {
	if r := recover(); r != nil {
		fmt.Println("recovered from ", r)
	}
}

func SetupCloseHandler() {
	c := make(chan os.Signal, 2)
	signal.Notify(c, os.Interrupt, syscall.SIGABRT)
	go func() {
		<-c
		for {
			fmt.Println("\r- Ctrl+C pressed in Terminal")
		}

		//os.Exit(0)
	}()
}

// TODO: determine if this test is possible
// to port from /examples/tests/TestLinearSolver.java
// glog calls abort() which becomes SIGABRT
// and it is unclear to me how best to disable
// this behavior in order to pass back a meaning
// error message.
/*func TestSameConstraint(t *testing.T) {

	fmt.Printf("----------------Same Constraint----------------\n")

	defer recoverGlog()

	//SetupCloseHandler()

	solver := genLinearSolver.NewSolver("My_solver_name", genLinearSolver.MPSolverCBC_MIXED_INTEGER_PROGRAMMING)

	solver.MakeConstraint("my_const_name")
	c := solver.MakeConstraint("my_const_name")
	fmt.Println(c)

	//if solver.NumConstraints() == 2 {
	//t.Fatal("Expected duplicate constraint to not be present")
	//}

	if solver.Solve() == genLinearSolver.MPSolverOptimal {
		t.Fatal("Expected duplicate constraint name to produce error")
	}

}
*/

func TestBooleanProgramming(t *testing.T) {

	fmt.Printf(
		"----------------%v----------------\n",
		genLinearSolver.MPModelRequest_SolverType_name[int32(genLinearSolver.MPSolverBOP_INTEGER_PROGRAMMING)])

	solver := genLinearSolver.NewSolver("BooleanProgrammingExample", genLinearSolver.MPSolverBOP_INTEGER_PROGRAMMING)

	x := solver.MakeBoolVar("x")
	y := solver.MakeBoolVar("y")

	solver.Objective().SetCoefficient(x, 2.0)
	solver.Objective().SetCoefficient(y, 1.0)
	solver.Objective().SetMinimization()

	c0 := solver.MakeConstraint(1.0, 2.0, "c0")
	c0.SetCoefficient(x, 1.0)
	c0.SetCoefficient(y, 2.0)

	err := SolveAndPrint(solver, []genLinearSolver.MPVariable{x, y}, []genLinearSolver.MPConstraint{c0})
	if err != nil {
		t.Fatal(err)
	}

}

func TestMixedIntegerProgramming(t *testing.T) {

	fmt.Printf(
		"----------------%v----------------\n",
		genLinearSolver.MPModelRequest_SolverType_name[int32(genLinearSolver.MPSolverCBC_MIXED_INTEGER_PROGRAMMING)])

	solver := genLinearSolver.NewSolver("MixedIntegerProgrammingExample", genLinearSolver.MPSolverCBC_MIXED_INTEGER_PROGRAMMING)

	x := solver.MakeIntVar(0.0, math.Inf(1), "x")
	y := solver.MakeIntVar(0.0, math.Inf(1), "Y")

	solver.Objective().SetCoefficient(x, 1)
	solver.Objective().SetCoefficient(y, 10)
	solver.Objective().SetMaximization()

	c0 := solver.MakeConstraint(math.Inf(-1), 17.5, "c0")
	c0.SetCoefficient(x, 1)
	c0.SetCoefficient(y, 7)

	c1 := solver.MakeConstraint(math.Inf(-1), 3.5, "c1")
	c1.SetCoefficient(x, 1)
	c1.SetCoefficient(y, 0)

	err := SolveAndPrint(solver, []genLinearSolver.MPVariable{x, y}, []genLinearSolver.MPConstraint{c0, c1})
	if err != nil {
		t.Fatal(err)
	}

}

func TestLinearProgramming(t *testing.T) {

	fmt.Printf(
		"----------------%v----------------\n",
		genLinearSolver.MPModelRequest_SolverType_name[int32(genLinearSolver.MPSolverCLP_LINEAR_PROGRAMMING)])

	solver := genLinearSolver.NewSolver("LinearProgrammingExample", genLinearSolver.MPSolverCLP_LINEAR_PROGRAMMING)

	x := solver.MakeNumVar(0.0, math.Inf(1), "x")
	y := solver.MakeNumVar(0.0, math.Inf(1), "y")

	solver.Objective().SetCoefficient(x, 3)
	solver.Objective().SetCoefficient(y, 4)
	solver.Objective().SetMinimization()

	c0 := solver.MakeConstraint(math.Inf(-1), 14.0, "c0")
	c0.SetCoefficient(x, 1)
	c0.SetCoefficient(y, 2)

	c1 := solver.MakeConstraint(0.0, math.Inf(1), "c1")
	c1.SetCoefficient(x, 3)
	c1.SetCoefficient(y, -1)

	c2 := solver.MakeConstraint(math.Inf(-1), 2.0, "c2")
	c2.SetCoefficient(x, 1)
	c2.SetCoefficient(y, -1)

	err := SolveAndPrint(solver, []genLinearSolver.MPVariable{x, y}, []genLinearSolver.MPConstraint{c0, c1, c2})
	if err != nil {
		t.Fatal(err)
	}

}

func SolveAndPrint(solver genLinearSolver.MPSolver, variables []genLinearSolver.MPVariable, constraints []genLinearSolver.MPConstraint) error {

	fmt.Printf("Number of variables = %v\n", solver.NumVariables())
	fmt.Printf("Number of constraints = %v\n", solver.NumConstraints())

	status := solver.Solve()

	if status != genLinearSolver.MPSolverOptimal {
		return errors.New("The problem does not have an optimal solution!")
	}

	fmt.Printf("Solution:\n")

	for _, v := range variables {
		fmt.Printf("%s = %v\n", v.Name(), v.SolutionValue())
	}

	fmt.Printf("Optimal objective value = %v\n\n", solver.Objective().Value())
	fmt.Println("Advanced usage:")
	fmt.Printf("Problem solved in %v ms\n", solver.WallTime())
	fmt.Printf("Problem solved in %v iterations", solver.Iterations())

	for _, v := range variables {
		fmt.Printf("%s: reduced cost %v\n", v.Name(), v.ReducedCost())
	}

	activities := solver.ComputeConstraintActivities()

	for _, c := range constraints {
		fmt.Printf("%v: dual value = %v; activity = %v\n", c.Name(), c.DualValue(), activities[c.Index()])
	}

	return nil

}
