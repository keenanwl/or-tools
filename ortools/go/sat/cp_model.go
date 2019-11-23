package sat

import (
	"or-tools/ortools/go/sat/gen"
)

type cpModel struct {
	proto *gen.CpModelProto
}

func NewCpModel() *cpModel {
	return &cpModel{
		proto: &gen.CpModelProto{
			Objective: &gen.CpObjectiveProto{
				Vars:                 make([]int32, 0),
				Coeffs:               make([]int64, 0),
				Offset:               0,
				ScalingFactor:        0,
				Domain:               make([]int64, 0),
				XXX_NoUnkeyedLiteral: struct{}{},
				XXX_unrecognized:     nil,
				XXX_sizecache:        0,
			},
		},
	}
}

func (m *cpModel) SetName(name string) {
	m.proto.Name = name
}

func (m *cpModel) Name() string {
	return m.proto.Name
}

/** Creates an integer variable with domain [lb, ub]. */
func (m *cpModel) NewIntVar(lb int64, ub int64, name string) *IntVar {
	return newIntVarLowerUpperBounds(m.proto, lb, ub, name)
}

/** Returns a non empty string explaining the issue if the model is invalid. */
func (m *cpModel) Validate() string {
	return gen.SatHelperValidateModel(*m.proto)
}

func (m *cpModel) Minimize(expr LinearExpr) {

	for i := 0; i < expr.NumElements(); i++ {
		m.proto.Objective.Coeffs = append(m.proto.Objective.Coeffs, int64(expr.Coefficient(i)))
		m.proto.Objective.Vars = append(m.proto.Objective.Vars, int32(expr.Variable(i).Index()))
	}

}

func (m *cpModel) AddMaxEquality(target IntVar, vars []IntVar) {

	varIndexes := make([]int32, 0)
	for i := range vars {
		varIndexes = append(varIndexes, int32(vars[i].Index()))
	}

	maxEquality := gen.ConstraintProto{
		Name:               "name",
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_IntMax{
			IntMax: &gen.IntegerArgumentProto{
				Target: int32(target.Index()),
				Vars:   varIndexes,
			},
		},
	}

	m.proto.Constraints = append(m.proto.Constraints, &maxEquality)

}

func (m *cpModel) AddNoOverlap(intervalVars []intervalVar) *gen.ConstraintProto {

	intervals := make([]int32, 0)
	for i := range intervalVars {
		intervals = append(intervals, int32(intervalVars[i].Index()))
	}

	cp := &gen.ConstraintProto{
		Name:               "name",
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

func (m *cpModel) AddAllDifferent(vars []IntVar) *gen.ConstraintProto {

	allIndexes := make([]int32, 0)
	for i := range vars {
		allIndexes = append(allIndexes, int32(vars[i].Index()))
	}

	diff := &gen.ConstraintProto{
		Name:               "name",
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

func (m *cpModel) AddEquality(expr LinearExpr, num int) {

	constraint := m.linearExpressionInDomain(expr, NewDomain(int64(num)))
	m.proto.Constraints = append(m.proto.Constraints, constraint)

}

func (m *cpModel) linearExpressionInDomain(expr LinearExpr, domain *gen.IntegerVariableProto) *gen.ConstraintProto {

	linear := &gen.LinearConstraintProto{
		Vars:   make([]int32, 0),
		Coeffs: make([]int64, 0),
		Domain: domain.Domain,
	}

	for i := 0; i < expr.NumElements(); i++ {
		linear.Vars = append(linear.Vars, int32(expr.Variable(i).Index()))
		linear.Coeffs = append(linear.Coeffs, int64(expr.Coefficient(i)))
	}

	constraint := &gen.ConstraintProto{
		Name:               "name",
		EnforcementLiteral: nil,
		Constraint: &gen.ConstraintProto_Linear{
			Linear: linear,
		},
	}

	return constraint

}

func NewDomain(num int64) *gen.IntegerVariableProto {

	return &gen.IntegerVariableProto{
		Domain: []int64{num, num},
	}

}
