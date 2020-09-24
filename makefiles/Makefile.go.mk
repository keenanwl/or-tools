# ---------- Golang support using SWIG ----------
.PHONY: help_go # Generate list of Go targets with descriptions.
help_go:
	@echo Use one of the following Go targets:
ifeq ($(SYSTEM),win)
	@$(GREP) "^.PHONY: .* #" $(CURDIR)/makefiles/Makefile.go.mk | $(SED) "s/\.PHONY: \(.*\) # \(.*\)/\1\ \2/"
	@echo off & echo(
else
	@$(GREP) "^.PHONY: .* #" $(CURDIR)/makefiles/Makefile.go.mk | $(SED) "s/\.PHONY: \(.*\) # \(.*\)/\1\ \2/" | expand -t24
	@echo
endif

GO_BIN = $(shell $(WHICH) go)
GO_PATH = $(shell [ -z "${GOPATH}" ] || echo $(GOPATH))
GO_OR_TOOLS_NATIVE_LIBS := $(LIB_DIR)/$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_SUFFIX)

HAS_GO = true
ifndef GO_BIN
HAS_GO =
endif
ifndef GO_PATH
HAS_GO =
endif

# Main target
.PHONY: go # Build Go OR-Tools.
.PHONY: test_go # Test Go OR-Tools using various examples.
ifndef HAS_GO
go: detect_go
check_go: go
test_go: go
else
go: go_pimpl
check_go: check_go_pimpl
test_go: test_go_pimpl
BUILT_LANGUAGES +=, Golang
endif

$(GEN_DIR)/ortools/go/constraint_solver:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Sconstraint_solver

$(GEN_DIR)/ortools/go/sat:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Ssat

$(GEN_DIR)/ortools/go/linear_solver:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Slinear_solver

$(GEN_DIR)/ortools/go/util:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Sutil

$(GEN_DIR)/ortools/go/sorted_interval:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Ssorted_interval

$(GEN_DIR)/ortools/go/graph:
	-$(MKDIR_P) $(GEN_DIR)$Sortools$Sgo$Sgraph

$(GEN_DIR)/ortools/go/sat/cp_model.pb.go: \
 $(SRC_DIR)/ortools/sat/cp_model.proto \
 | $(GEN_DIR)/ortools/go/sat
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Ssat$Scp_model.proto

$(GEN_DIR)/ortools/go/sat/sat_parameters.pb.go: \
 $(SRC_DIR)/ortools/sat/sat_parameters.proto \
 | $(GEN_DIR)/ortools/go/sat
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Ssat$Ssat_parameters.proto

$(GEN_DIR)/ortools/go/util/optional_boolean.pb.go: \
 $(SRC_DIR)/ortools/util/optional_boolean.proto \
 | $(GEN_DIR)/ortools/go/util
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sutil$Soptional_boolean.proto

$(GEN_DIR)/ortools/go/linear_solver/mp_model.pb.go: \
 $(SRC_DIR)/ortools/linear_solver/linear_solver.proto \
 | $(GEN_DIR)/ortools/go/linear_solver
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Slinear_solver$Slinear_solver.proto

$(GEN_DIR)/ortools/go/constraint_solver/search_limit.pb.go: \
 $(SRC_DIR)/ortools/constraint_solver/search_limit.proto \
 | $(GEN_DIR)/ortools/go/constraint_solver
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sconstraint_solver$Ssearch_limit.proto

$(GEN_DIR)/ortools/go/constraint_solver/solver_parameters.pb.go: \
 $(SRC_DIR)/ortools/constraint_solver/solver_parameters.proto \
 | $(GEN_DIR)/ortools/go/constraint_solver
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sconstraint_solver$Ssolver_parameters.proto

$(GEN_DIR)/ortools/go/constraint_solver/routing_parameters.pb.go: \
 $(SRC_DIR)/ortools/constraint_solver/routing_parameters.proto \
 | $(GEN_DIR)/ortools/go/constraint_solver
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sconstraint_solver$Srouting_parameters.proto

$(GEN_DIR)/ortools/go/constraint_solver/routing_enums.pb.go: \
 $(SRC_DIR)/ortools/constraint_solver/routing_enums.proto \
 | $(GEN_DIR)/ortools/go/constraint_solver
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sconstraint_solver$Srouting_enums.proto

$(GEN_DIR)/ortools/sat/sat_go_wrap.cc: \
 $(SRC_DIR)/ortools/sat/go/sat.i \
 $(SRC_DIR)/ortools/base/base.i \
 $(SAT_DEPS) \
 | $(GEN_DIR)/ortools/go/sat
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
 -o $(GEN_PATH)$Sortools$Ssat$Ssat_go_wrap.cc \
 -package sat \
 -module sat_wrapper \
 -outdir $(GEN_DIR)$Sortools$Sgo$Ssat \
 -intgosize 64 \
 -v \
 $(SRC_DIR)$Sortools$Ssat$Sgo$Ssat.i

$(GEN_DIR)/ortools/linear_solver/linear_solver_go_wrap.cc: \
  $(SRC_DIR)/ortools/linear_solver/go/linear_solver.i \
  $(SRC_DIR)/ortools/base/base.i \
  $(SRC_DIR)/ortools/util/go/vector.i \
  $(LP_DEPS) \
  | $(GEN_DIR)/ortools/go/linear_solver
	$(SWIG_BINARY) $(SWIG_INC) -c++ -go -cgo \
  -o $(GEN_PATH)$Sortools$Slinear_solver$Slinear_solver_go_wrap.cc \
  -package linear_solver \
  -module linear_solver_wrapper \
  -outdir $(GEN_DIR)$Sortools$Sgo$Slinear_solver \
  -intgosize 64 \
  -v \
  $(SRC_DIR)$Sortools$Slinear_solver$Sgo$Slinear_solver.i

$(GEN_DIR)/ortools/graph/graph_go_wrap.cc: \
   $(SRC_DIR)/ortools/graph/go/graph.i \
   $(SRC_DIR)/ortools/base/base.i \
   $(GRAPH_DEPS) \
   | $(GEN_DIR)/ortools/go/graph
	 $(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
   -o $(GEN_PATH)$Sortools$Sgraph$Sgraph_go_wrap.cc \
   -package graph \
   -module graph_wrapper \
   -outdir $(GEN_DIR)$Sortools$Sgo$Sgraph \
   -intgosize 64 \
   $(SRC_DIR)$Sortools$Sgraph$Sgo$Sgraph.i

$(GEN_DIR)/ortools/constraint_solver/constraint_solver_go_wrap.cc: \
	$(SRC_DIR)/ortools/constraint_solver/go/constraint_solver.i \
	$(SRC_DIR)/ortools/constraint_solver/go/routing.i \
	$(SRC_DIR)/ortools/base/base.i \
	$(SRC_DIR)/ortools/util/go/vector.i \
	$(SRC_DIR)/ortools/util/go/proto.i \
	$(CP_DEPS) \
	$(SRC_DIR)/ortools/constraint_solver/routing.h \
	| $(GEN_DIR)/ortools/go/constraint_solver
	 $(SWIG_BINARY) $(SWIG_INC) -c++ -go -cgo \
	-o $(GEN_PATH)$Sortools$Sconstraint_solver$Sconstraint_solver_go_wrap.cc \
	-package constraint_solver \
	-module constraint_solver \
	-outdir $(GEN_DIR)$Sortools$Sgo$Sconstraint_solver \
	-intgosize 64 \
	$(SRC_DIR)$Sortools$Sconstraint_solver$Sgo$Srouting.i

$(GEN_DIR)/ortools/util/util_go_wrap.cc: \
  $(SRC_DIR)/ortools/util/go/sorted_interval_list.i \
  $(SRC_DIR)/ortools/base/base.i \
  $(UTIL_DEPS) \
  | $(GEN_DIR)/ortools/go/util
	 $(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
  -o $(GEN_PATH)$Sortools$Sutil$Sutil_go_wrap.cc \
  -package util \
  -module util \
  -outdir $(GEN_DIR)$Sortools$Sgo$Sutil \
  -intgosize 64 \
  -v \
  $(SRC_DIR)$Sortools$Sutil$Sgo$Ssorted_interval_list.i
	$(SED) -i -e 's/< long long >/< int64 >/g' \
  $(GEN_DIR)/ortools/util/util_go_wrap.cc

$(OBJ_DIR)/swig/constraint_solver_go_wrap.$O: \
	$(GEN_DIR)/ortools/constraint_solver/constraint_solver_go_wrap.cc \
	$(CP_DEPS) \
	$(SRC_DIR)/ortools/constraint_solver/routing.h \
	| $(OBJ_DIR)/swig
		$(CCC) $(CFLAGS) \
	-c $(GEN_PATH)$Sortools$Sconstraint_solver$Sconstraint_solver_go_wrap.cc \
	$(OBJ_OUT)$(OBJ_DIR)$Sswig$Sconstraint_solver_go_wrap.$O

$(OBJ_DIR)/swig/graph_go_wrap.$O: \
   $(GEN_DIR)/ortools/graph/graph_go_wrap.cc \
   $(GRAPH_DEPS) \
   | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) \
   -c $(GEN_PATH)$Sortools$Sgraph$Sgraph_go_wrap.cc \
   $(OBJ_OUT)$(OBJ_DIR)$Sswig$Sgraph_go_wrap.$O

$(OBJ_DIR)/swig/linear_solver_go_wrap.$O: \
   $(GEN_DIR)/ortools/linear_solver/linear_solver_go_wrap.cc \
   $(LP_DEPS) \
     | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) \
     -c $(GEN_PATH)$Sortools$Slinear_solver$Slinear_solver_go_wrap.cc \
   $(OBJ_OUT)$(OBJ_DIR)$Sswig$Slinear_solver_go_wrap.$O

$(OBJ_DIR)/swig/util_go_wrap.$O: \
 $(GEN_DIR)/ortools/util/util_go_wrap.cc \
 $(UTIL_DEPS) \
 | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) \
 -c $(GEN_PATH)$Sortools$Sutil$Sutil_go_wrap.cc \
 $(OBJ_OUT)$(OBJ_DIR)$Sswig$Sutil_go_wrap.$O

$(OBJ_DIR)/swig/sat_go_wrap.$O: \
  $(GEN_DIR)/ortools/sat/sat_go_wrap.cc \
  $(SAT_DEPS) \
  | $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) \
  -c $(GEN_PATH)$Sortools$Ssat$Ssat_go_wrap.cc \
  $(OBJ_OUT)$(OBJ_DIR)$Sswig$Ssat_go_wrap.$O

$(GO_OR_TOOLS_NATIVE_LIBS): \
  $(OR_TOOLS_LIBS) \
  $(OBJ_DIR)/swig/constraint_solver_go_wrap.$O \
  $(OBJ_DIR)/swig/linear_solver_go_wrap.$O \
  $(OBJ_DIR)/swig/sat_go_wrap.$O \
  $(OBJ_DIR)/swig/graph_go_wrap.$O \
  $(OBJ_DIR)/swig/util_go_wrap.$O
	$(DYNAMIC_LD) $(LD_OUT)$(LIB_DIR)$S$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_SUFFIX) \
  $(OBJ_DIR)$Sswig$Sconstraint_solver_go_wrap.$O \
  $(OBJ_DIR)$Sswig$Sgraph_go_wrap.$O \
  $(OBJ_DIR)$Sswig$Slinear_solver_go_wrap.$O \
  $(OBJ_DIR)$Sswig$Ssat_go_wrap.$O \
  $(OBJ_DIR)$Sswig$Sutil_go_wrap.$O \
  $(OR_TOOLS_LNK) \
  $(OR_TOOLS_LDFLAGS)

go_pimpl: \
	$(GEN_DIR)/ortools/go/sat/cp_model.pb.go \
	$(GEN_DIR)/ortools/go/sat/sat_parameters.pb.go \
	$(GEN_DIR)/ortools/go/linear_solver/mp_model.pb.go \
	$(GEN_DIR)/ortools/go/constraint_solver/search_limit.pb.go \
    $(GEN_DIR)/ortools/go/constraint_solver/solver_parameters.pb.go \
    $(GEN_DIR)/ortools/go/constraint_solver/routing_parameters.pb.go \
    $(GEN_DIR)/ortools/go/constraint_solver/routing_enums.pb.go \
	$(GEN_DIR)/ortools/go/util/optional_boolean.pb.go \
	$(GEN_DIR)/ortools/graph/graph_go_wrap.cc \
	$(GEN_DIR)/ortools/constraint_solver/constraint_solver_go_wrap.cc \
	$(GEN_DIR)/ortools/linear_solver/linear_solver_go_wrap.cc \
	$(GEN_DIR)/ortools/util/util_go_wrap.cc \
	$(GEN_DIR)/ortools/sat/sat_go_wrap.cc \
	$(GO_OR_TOOLS_NATIVE_LIBS)
	cd ortools; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v -Wl,--unresolved-symbols=ignore-all" \
	go build go/linear_solver/linear_solver.go;

# -Wl,--unresolved-symbols=ignore-all  ------>
# https://github.com/golang/go/issues/12216#issuecomment-169465786
# LD_LIBRARY_PATH -> Linux
# DYLD_LIBRARY_PATH -> Mac OS
test_go_pimpl: go_pimpl
	cd ortools/go; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v -Wl,--unresolved-symbols=ignore-all" \
	LD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	DYLD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	go test -v ./...;

check_go_pimpl: test_go_pimpl

################
##  Cleaning  ##
################
.PHONY: clean_go # Clean Go output from previous build.
clean_go:
	-$(DELREC) $(GEN_DIR)$Sortools$Sgo
	-$(DEL) $(GEN_PATH)$Sortools$Sconstraint_solver$S*go_wrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sgraph$S*go_wrap*
	-$(DEL) $(GEN_PATH)$Sortools$Slinear_solver$S*go_wrap*
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*go_wrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S*go_wrap*
	-$(DEL) $(OBJ_DIR)$Sswig$S*go_wrap*
	-$(DEL) $(LIB_DIR)$S$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_SUFFIX)

#############
##  DEBUG  ##
#############
.PHONY: detect_go # Show variables used to build Go OR-Tools.
detect_go:
	@echo Relevant info for the Go build:
	@echo These must resolve to proceed
	@echo GO_BIN = $(GO_BIN)
	@echo GO_PATH = $(GO_PATH)
	@echo PROTOC_GEN_GO = $(PROTOC_GEN_GO)
	@echo GO_OR_TOOLS_NATIVE_LIBS = $(GO_OR_TOOLS_NATIVE_LIBS)
	@echo SWIG_INC = $(SWIG_INC)
	@echo DYNAMIC_LD = $(DYNAMIC_LD)

ifeq ($(SYSTEM),win)
	@echo off & echo(
else
	@echo
endif
