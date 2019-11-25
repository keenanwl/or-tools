package sat

import (
	"fmt"
	"math/rand"
	"strconv"
	"testing"

	"or-tools/ortools/go/sat/gen"
)

func TestCrashInPresolve(t *testing.T) {

	model := NewCpModel()

	x := model.NewIntVar(0, 5, "x")
	y := model.NewIntVar(0, 5, "Y")
	model.AddLinearConstraint2(InitSumOfVariables([]IntVar{*x, *y}), 0, 1, "linear")

	obj := model.NewIntVar(0, 3, "obj")
	model.AddGreaterOrEqual(obj, 2, "greater or equal")
	model.AddMaxEquality(*obj, []IntVar{*x, *y}, "max eq")
	model.Minimize(obj)

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_INFEASIBLE {
		t.Fatalf("expected status: Infeasible, got status: %s", status.Status)
	}

}

func TestCpModel_TestCrashInSolveWithAllowedAssignment(t *testing.T) {

	model := NewCpModel()
	const numEntityOne = 50000
	const numEntityTwo = 100

	entitiesOne := [numEntityOne]IntVar{}

	for i := 0; i < len(entitiesOne); i++ {
		entitiesOne[i] = *model.NewIntVar(1, numEntityTwo, "E"+strconv.Itoa(i))
	}

	allAllowedValues := NewMatrix64(numEntityTwo, len(entitiesOne))

	for i := 0; i < numEntityTwo; i++ {
		for j := 0; j < len(entitiesOne); j++ {
			allAllowedValues[i][j] = int64(i)
		}
	}

	_, err := model.AddAllowedAssignments(entitiesOne[:], allAllowedValues[:], "Table")
	if err != nil {
		t.Fatalf("got error adding table: %s", err)
	}

	for i := 0; i < len(entitiesOne); i++ {
		r := rand.New(rand.NewSource(numEntityTwo))
		model.AddEquality(&entitiesOne[i], r.Int(), "equality")
	}

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_INFEASIBLE {
		t.Fatalf("expecting status infeasible, got: %s", status.Status)
	}

}

func TestCpModel_CrashEquality(t *testing.T) {

	model := NewCpModel()
	entities := [20]IntVar{}
	for i := 0; i < len(entities); i++ {
		entities[i] = *model.NewIntVar(1, 5, "E"+strconv.Itoa(i))
	}

	equalities := []int{18, 4, 19, 3, 12}
	model.AddEqualities(entities[:], equalities, "equalities")

	allowedAssignments := []int64{12, 8, 15}
	allowedAssignmentValues := []int{1, 3}

	_, err := model.AddAllowedAssignmentsUnpacked(entities[:], allowedAssignments, allowedAssignmentValues, "Allowed assignments")
	if err != nil {
		t.Fatalf("unepected error adding allowed assignment condition")
	}

	forbiddenAssignments1 := []int{6, 15, 19}
	forbiddenAssignments1Values := []int{3}
	forbiddenAssignments2 := []int{10, 19}
	forbiddenAssignments2Values := []int{4}
	forbiddenAssignments3 := []int{18, 0, 9, 7}
	forbiddenAssignments3Values := []int{4}
	forbiddenAssignments4 := []int{14, 11}
	forbiddenAssignments4Values := []int{1, 2, 3, 4, 5}
	forbiddenAssignments5 := []int{5, 16, 1, 3}
	forbiddenAssignments5Values := []int{1, 2, 3, 4, 5}
	forbiddenAssignments6 := []int{2, 6, 11, 4}
	forbiddenAssignments6Values := []int{1, 2, 3, 4, 5}
	forbiddenAssignments7 := []int{6, 18, 12, 2, 9, 14}
	forbiddenAssignments7Values := []int{1, 2, 3, 4, 5}

	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments1Values, forbiddenAssignments1, entities[:], "Forbidden1")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 1")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments2Values, forbiddenAssignments2, entities[:], "Forbidden2")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 2")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments3Values, forbiddenAssignments3, entities[:], "Forbidden3")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 3")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments4Values, forbiddenAssignments4, entities[:], "Forbidden4")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 4")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments5Values, forbiddenAssignments5, entities[:], "Forbidden5")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 5")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments6Values, forbiddenAssignments6, entities[:], "Forbidden6")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 6")
	}
	_, err = model.AddForbiddenAssignmentsUnpacked(forbiddenAssignments7Values, forbiddenAssignments7, entities[:], "Forbidden7")
	if err != nil {
		t.Fatalf("error adding forbidden assignements 7")
	}

	configuration := []int{5, 4, 2, 3, 3, 3, 4, 3, 3, 1, 4, 4, 3, 1, 4, 1, 4, 4, 3, 3}
	for i := 0; i < len(configuration); i++ {
		model.AddEquality(&entities[i], configuration[i], "equality")
	}

	solver := cpSolver{}
	status := solver.Solve(*model)
	if status.Status != gen.CpSolverStatus_INFEASIBLE {
		t.Fatalf("expected infeasible, got: %s", status.Status)
	}

}

func TestCpModel_Sudoku_sat(t *testing.T) {

	model := NewCpModel()
	cellSize := 3
	const n = 9
	const nFlat = 81

	// 0 marks an unknown value
	initialGrid := [n][n]int{
		{0, 6, 0, 0, 5, 0, 0, 2, 0},
		{0, 0, 0, 3, 0, 0, 0, 9, 0},
		{7, 0, 0, 6, 0, 0, 0, 1, 0},
		{0, 0, 6, 0, 3, 0, 4, 0, 0},
		{0, 0, 4, 0, 7, 0, 1, 0, 0},
		{0, 0, 5, 0, 9, 0, 8, 0, 0},
		{0, 4, 0, 0, 0, 1, 0, 0, 6},
		{0, 3, 0, 0, 0, 8, 0, 0, 0},
		{0, 2, 0, 0, 4, 0, 0, 5, 0},
	}

	expectedSolution := [n][n]int64{
		{8, 6, 1, 4, 5, 9, 7, 2, 3},
		{4, 5, 2, 3, 1, 7, 6, 9, 8},
		{7, 9, 3, 6, 8, 2, 5, 1, 4},
		{2, 1, 6, 8, 3, 5, 4, 7, 9},
		{9, 8, 4, 2, 7, 6, 1, 3, 5},
		{3, 7, 5, 1, 9, 4, 8, 6, 2},
		{5, 4, 7, 9, 2, 1, 3, 8, 6},
		{1, 3, 9, 5, 6, 8, 2, 4, 7},
		{6, 2, 8, 7, 4, 3, 9, 5, 1},
	}

	grid := [n][n]IntVar{}
	gridFlat := [nFlat]IntVar{}

	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			grid[i][j] = *model.NewIntVar(1, 9, "grid["+strconv.Itoa(i)+","+strconv.Itoa(j)+"]")
			gridFlat[i*n+j] = grid[i][j]
		}
	}

	// Constraints
	// All different row
	for i := 0; i < n; i++ {
		row := [n]IntVar{}
		for j := 0; j < n; j++ {
			// Add initial points
			if initialGrid[i][j] > 0 {
				model.AddEquality(&grid[i][j], initialGrid[i][j], "equality")
			}
			row[j] = grid[i][j]
		}
		model.AddAllDifferent(row[:], "all different")
	}

	// All different column
	for j := 0; j < n; j++ {
		column := [n]IntVar{}
		for i := 0; i < n; i++ {
			column[i] = grid[i][j]
		}
		model.AddAllDifferent(column[:], "all different")
	}

	// All different cells
	for i := 0; i < cellSize; i++ {
		for j := 0; j < cellSize; j++ {
			cell := [n]IntVar{}
			for di := 0; di < cellSize; di++ {
				for dj := 0; dj < cellSize; dj++ {
					cell[di*cellSize+dj] = grid[i*cellSize+di][j*cellSize+dj]
				}
			}
			model.AddAllDifferent(cell[:], "all different")
		}
	}

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_OPTIMAL {
		t.Fatalf("expecting status optimal, got: %s", status.Status)
	}

	fmt.Println("Test Sudoku")
	for i := 0; i < n; i++ {
		row := [n]int64{}
		for j := 0; j < n; j++ {
			row[j] = status.Solution[i*n+j]
		}
		if row != expectedSolution[i] {
			t.Fatalf("expected row %v to have values %v, got %v instead", i, expectedSolution[i], row)
		}
		fmt.Println(row)
	}

}

func TestCpModel_Schedule_NoOverlap(t *testing.T) {

	model := NewCpModel()
	var horizon int64 = 21

	// Task 0, duration 2.
	start0 := model.NewIntVar(0, horizon, "start0")
	duration0 := 2
	end0 := model.NewIntVar(0, horizon, "end0")
	task0 := model.NewIntervalVar(*start0, duration0, *end0, "task0")

	//  Task 1, duration 4.
	start1 := model.NewIntVar(0, horizon, "start1")
	duration1 := 4
	end1 := model.NewIntVar(0, horizon, "end1")
	task1 := model.NewIntervalVar(*start1, duration1, *end1, "task1")

	// Task 2, duration 3.
	start2 := model.NewIntVar(0, horizon, "start2")
	duration2 := 3
	end2 := model.NewIntVar(0, horizon, "end2")
	task2 := model.NewIntervalVar(*start2, duration2, *end2, "task2")

	// Weekends.
	weekend0 := model.NewFixedInterval(5, 2, "weekend0")
	weekend1 := model.NewFixedInterval(12, 2, "weekend1")
	weekend2 := model.NewFixedInterval(19, 2, "weekend2")

	// No Overlap constraint. This constraint enforces that no two intervals can overlap.
	// In this example, as we use 3 fixed intervals that span over weekends, this constraint makes
	// sure that all tasks are executed on weekdays.
	model.AddNoOverlap([]intervalVar{*task0, *task1, *task2, *weekend0, *weekend1, *weekend2}, "no overlap")

	// Makespan objective.
	obj := model.NewIntVar(0, horizon, "makespan")
	model.AddMaxEquality(*obj, []IntVar{*end0, *end1, *end2}, "max eq")
	model.Minimize(obj)

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_OPTIMAL {
		t.Fatalf("expecting solver status to be optimal, got %s", status.Status)
	}

	if len(model.Validate()) > 0 {
		t.Fatalf("expecting model to validate, got %s", model.Validate())
	}

	if status.ObjectiveValue != 11 {
		t.Fatalf("expecting objective value to be 11, got %v", status.ObjectiveValue)
	}

	if status.Solution[start0.Index()] != 0 {
		t.Fatalf("expecting task 0 to start at 0, got %v", status.Solution[start0.Index()])
	}

	if status.Solution[start1.Index()] != 7 {
		t.Fatalf("expecting task 1 to start at 7, got %v", status.Solution[start1.Index()])
	}

	if status.Solution[start2.Index()] != 2 {
		t.Fatalf("expecting task 2 to start at 2, got %v", status.Solution[start2.Index()])
	}

	fmt.Printf("Optimal Schedule Length: %v\n", status.ObjectiveValue)
	fmt.Printf("Task 0 starts at %v\n", status.Solution[start0.Index()])
	fmt.Printf("Task 1 starts at %v\n", status.Solution[start1.Index()])
	fmt.Printf("Task 2 starts at %v\n", status.Solution[start2.Index()])

}
