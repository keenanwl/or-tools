package sat

import (
	"errors"
	"math"
	"strconv"

	"or-tools/ortools/go/sat/gen"
)

type CpModel struct {
	proto *gen.CpModelProto
}

func NewCpModel() *CpModel {
	return &CpModel{
		proto: &gen.CpModelProto{
			Objective: &gen.CpObjectiveProto{
				Vars:          make([]int32, 0),
				Coeffs:        make([]int64, 0),
				Offset:        0,
				ScalingFactor: 0,
				Domain:        make([]int64, 0),
			},
		},
	}
}

func (m *CpModel) SetName(name string) {
	m.proto.Name = name
}

func (m *CpModel) Name() string {
	return m.proto.Name
}

/** Creates an integer variable with domain [lb, ub]. */
func (m *CpModel) NewIntVar(lb int64, ub int64, name string) *IntVar {
	return NewIntVarLowerUpperBounds(m.proto, lb, ub, name)
}

/** Returns a non empty string explaining the issue if the model is invalid. */
func (m *CpModel) Validate() string {
	return gen.SatHelperValidateModel(*m.proto)
}

func (m *CpModel) Minimize(expr LinearExpr) {

	for i := 0; i < expr.NumElements(); i++ {
		m.proto.Objective.Coeffs = append(m.proto.Objective.Coeffs, int64(expr.Coefficient(i)))
		m.proto.Objective.Vars = append(m.proto.Objective.Vars, int32(expr.Variable(i).Index()))
	}

}

func (m *CpModel) AddMaxEquality(target IntVar, vars []IntVar, name string) *gen.ConstraintProto {

	varIndexes := make([]int32, 0)
	for i := range vars {
		varIndexes = append(varIndexes, int32(vars[i].Index()))
	}

	maxEquality := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_IntMax{
			IntMax: &gen.IntegerArgumentProto{
				Target: int32(target.Index()),
				Vars:   varIndexes,
			},
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, maxEquality)

	return maxEquality

}

func (m *CpModel) AddNoOverlap(intervalVars []intervalVar, name string) *gen.ConstraintProto {

	intervals := make([]int32, 0)
	for i := range intervalVars {
		intervals = append(intervals, int32(intervalVars[i].Index()))
	}

	cp := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_NoOverlap{
			NoOverlap: &gen.NoOverlapConstraintProto{
				Intervals: intervals,
			},
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, cp)

	return cp

}

func (m *CpModel) AddAllDifferent(vars []IntVar, name string) *gen.ConstraintProto {

	allIndexes := make([]int32, 0)
	for i := range vars {
		allIndexes = append(allIndexes, int32(vars[i].Index()))
	}

	diff := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_AllDiff{
			AllDiff: &gen.AllDifferentConstraintProto{
				Vars: allIndexes,
			},
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, diff)

	return diff

}

func (m *CpModel) AddEquality(expr LinearExpr, num int, name string) {

	constraint := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         m.linearExpressionInDomain(expr, NewDomain(int64(num)), name),
	}
	m.proto.Constraints = append(m.proto.Constraints, constraint)

}

func (m *CpModel) AddEquality2(left LinearExpr, right LinearExpr, name string) {

	constraint := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         m.linearExpressionInDomain(NewDifference(left, right), NewDomain(0), name),
	}
	m.proto.Constraints = append(m.proto.Constraints, constraint)

}

func (m *CpModel) AddLinearConstraint2(expr LinearExpr, lb int, ub int, name string) {

	constraint := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         m.linearExpressionInDomain(expr, NewDomain2(int64(lb), int64(ub)), name),
	}
	m.proto.Constraints = append(m.proto.Constraints, constraint)

}

func (m *CpModel) linearExpressionInDomain(expr LinearExpr, domain *gen.IntegerVariableProto, name string) *gen.ConstraintProto_Linear {

	linear := &gen.LinearConstraintProto{
		Vars:   make([]int32, 0),
		Coeffs: make([]int64, 0),
		Domain: domain.Domain,
	}

	for i := 0; i < expr.NumElements(); i++ {
		linear.Vars = append(linear.Vars, int32(expr.Variable(i).Index()))
		linear.Coeffs = append(linear.Coeffs, int64(expr.Coefficient(i)))
	}

	return &gen.ConstraintProto_Linear{
		Linear: linear,
	}

}

func (m *CpModel) AddEqualities(entities []IntVar, equalities []int, name string) {

	for i := 0; i < len(equalities)-1; i++ {
		m.AddEquality2(&entities[equalities[i]], &entities[equalities[i+1]], name)
	}

}

func NewMatrix64(rows, cols int) [][]int64 {
	m := make([][]int64, rows)
	for r := range m {
		m[r] = make([]int64, cols)
	}
	return m
}

// Helper from tests class?
func (m *CpModel) AddAllowedAssignmentsUnpacked(
	entities []IntVar,
	allowedAssignments []int64,
	allowedAssignmentValues []int,
	name string,
) (*gen.ConstraintProto_Table, error) {

	allAllowedValues := NewMatrix64(len(allowedAssignmentValues), len(allowedAssignments))
	for i := 0; i < len(allowedAssignmentValues); i++ {
		value := allowedAssignmentValues[i]
		for j := 0; j < len(allowedAssignments); j++ {
			allAllowedValues[i][j] = int64(value)
		}
	}

	specificEntities := make([]IntVar, len(allowedAssignments))
	for i := 0; i < len(allowedAssignments); i++ {
		specificEntities[i] = entities[allowedAssignments[i]]
	}

	return m.AddAllowedAssignments(specificEntities, allAllowedValues, name)

}

func (m *CpModel) AddAllowedAssignments(variables []IntVar, tuplesList [][]int64, name string) (*gen.ConstraintProto_Table, error) {

	tableVariables := []int32{}
	for i := range variables {
		tableVariables = append(tableVariables, int32(variables[i].Index()))
	}

	tableValues := []int64{}
	for t := 0; t < len(tuplesList); t++ {
		if len(tuplesList[t]) != len(variables) {
			return nil, errors.New("tuple " + strconv.Itoa(t) + " does not have the same length as the variables")
		}

		for i := 0; i < len(tuplesList[t]); i++ {
			tableValues = append(tableValues, tuplesList[t][i])
		}
	}

	table := &gen.ConstraintProto_Table{
		Table: &gen.TableConstraintProto{
			Vars:    tableVariables,
			Values:  tableValues,
			Negated: false,
		},
	}

	constraint := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         table,
	}

	m.proto.Constraints = append(m.proto.Constraints, constraint)

	return table, nil

}

func (m *CpModel) AddGreaterOrEqual(expr LinearExpr, val int, name string) {

	constraint := &gen.ConstraintProto{
		Name:               name,
		EnforcementLiteral: nil,
		Constraint:         m.linearExpressionInDomain(expr, NewDomain2(int64(val), math.MaxInt64), name),
	}

	m.proto.Constraints = append(m.proto.Constraints, constraint)

}

func NewDomain(num int64) *gen.IntegerVariableProto {
	return &gen.IntegerVariableProto{
		Domain: []int64{num, num},
	}
}

func NewDomain2(lb, ub int64) *gen.IntegerVariableProto {
	return &gen.IntegerVariableProto{
		Domain: []int64{lb, ub},
	}
}

func (m *CpModel) AddForbiddenAssignments(variables []IntVar, tuplesList [][]int64, name string) (*gen.ConstraintProto_Table, error) {

	table, err := m.AddAllowedAssignments(variables, tuplesList, name)
	if err != nil {
		return nil, err
	}

	table.Table.Negated = true

	return table, nil

}

func (m *CpModel) AddForbiddenAssignmentsUnpacked(forbiddenAssignmentsValues []int, forbiddenAssignments []int, entities []IntVar, name string) (*gen.ConstraintProto_Table, error) {

	specificEntities := make([]IntVar, len(forbiddenAssignments))
	for i := 0; i < len(forbiddenAssignments); i++ {
		specificEntities[i] = entities[forbiddenAssignments[i]]
	}

	notAllowedValues := NewMatrix64(len(forbiddenAssignmentsValues), len(forbiddenAssignments))
	for i := 0; i < len(forbiddenAssignmentsValues); i++ {
		value := forbiddenAssignmentsValues[i]
		for j := 0; j < len(forbiddenAssignments); j++ {
			notAllowedValues[i][j] = int64(value)
		}
	}

	return m.AddForbiddenAssignments(specificEntities, notAllowedValues, name)

}
