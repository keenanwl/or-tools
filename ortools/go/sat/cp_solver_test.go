package sat

import (
	"fmt"
	"strconv"
	"testing"

	"or-tools/ortools/go/sat/gen"
)

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
				model.AddEquality(&grid[i][j], initialGrid[i][j])
			}
			row[j] = grid[i][j]
		}
		model.AddAllDifferent(row[:])
	}

	// All different column
	for j := 0; j < n; j++ {
		column := [n]IntVar{}
		for i := 0; i < n; i++ {
			column[i] = grid[i][j]
		}
		model.AddAllDifferent(column[:])
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
			model.AddAllDifferent(cell[:])
		}
	}

	solver := cpSolver{}
	status := solver.Solve(*model)

	if status.Status != gen.CpSolverStatus_OPTIMAL {
		t.Fatalf("Expecting status Optimal, got: %s", status.Status)
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
	model.AddNoOverlap([]intervalVar{*task0, *task1, *task2, *weekend0, *weekend1, *weekend2})

	// Makespan objective.
	obj := model.NewIntVar(0, horizon, "makespan")
	model.AddMaxEquality(*obj, []IntVar{*end0, *end1, *end2})
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
