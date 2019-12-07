package linear_solver

import "ortools/go/linear_solver/gen"

type MPModel struct {
	proto *gen.MPModelProto
}

func (m *MPModel) SetName(name string) {
	m.proto.Name = &name
}

func (m *MPModel) Name() *string {
	return m.proto.Name
}
