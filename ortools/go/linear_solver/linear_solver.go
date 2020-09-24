package linear_solver

import "ortools/gen/ortools/go/linear_solver"

type MPModel struct {
	proto *linear_solver.MPModelProto
}

func (m *MPModel) SetName(name string) {
	m.proto.Name = &name
}

func (m *MPModel) Name() *string {
	return m.proto.Name
}
