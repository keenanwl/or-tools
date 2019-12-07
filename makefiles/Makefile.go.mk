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
GO_OR_TOOLS_NATIVE_LIBS := $(LIB_DIR)/$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_EXT)

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

ortools/go/sat/gen:
	-$(MKDIR_P) ortools$Sgo$Ssat$Sgen

ortools/go/linear_solver/gen:
	-$(MKDIR_P) ortools$Sgo$Slinear_solver$Sgen

ortools/go/util/gen:
	-$(MKDIR_P) ortools$Sgo$Sutil$Sgen

ortools/go/sat/gen/cp_model.pb.go: \
 $(SRC_DIR)/ortools/sat/cp_model.proto \
 | ortools/go/sat/gen
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Ssat$Scp_model.proto

ortools/go/sat/gen/sat_parameters.pb.go: \
 $(SRC_DIR)/ortools/sat/sat_parameters.proto \
 | ortools/go/sat/gen
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Ssat$Ssat_parameters.proto

$(GEN_DIR)/go/util/gen/optional_boolean.pb.go: \
 $(SRC_DIR)/ortools/util/optional_boolean.proto \
 | ortools/go/util/gen
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Sutil$Soptional_boolean.proto

ortools/go/linear_solver/gen/mp_model.pb.go: \
 $(SRC_DIR)/ortools/linear_solver/linear_solver.proto \
 | ortools/go/linear_solver/gen
	test -f $(GO_PATH)/bin/protoc-gen-go && echo $(GO_PATH)/bin/protoc-gen-go || go get -u github.com/golang/protobuf/protoc-gen-go
	$(PROTOC) --proto_path=$(SRC_DIR) --go_out=. $(SRC_DIR)$Sortools$Slinear_solver$Slinear_solver.proto

$(GEN_DIR)/ortools/sat/sat_go_wrap.cc: \
 $(SRC_DIR)/ortools/sat/go/sat.i \
 $(SRC_DIR)/ortools/base/base.i \
 $(SAT_DEPS) \
 | $(GEN_DIR)/ortools/sat
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
 -o $(GEN_PATH)$Sortools$Ssat$Ssat_go_wrap.cc \
 -package ortools/go/sat/gen \
 -module sat_wrapper \
 -outdir ortools/go$Ssat$Sgen \
 -intgosize 64 \
 -v \
 $(SRC_DIR)$Sortools$Ssat$Sgo$Ssat.i

$(GEN_DIR)/ortools/util/util_go_wrap.cc: \
  $(SRC_DIR)/ortools/util/go/sorted_interval_list.i \
  $(SRC_DIR)/ortools/base/base.i \
  $(UTIL_DEPS) \
  | $(GEN_DIR)/ortools/util
	 $(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
  -o $(GEN_PATH)$Sortools$Sutil$Sutil_go_wrap.cc \
  -package ortools$Sgo$Slinear_solver$Sgen \
  -module linear_solver_wrapper \
  -outdir ortools$Sgo$Slinear_solver$Sgen \
  -intgosize 64 \
  -v \
  $(SRC_DIR)$Sortools$Sutil$Sgo$Ssorted_interval_list.i

$(GEN_DIR)/ortools/linear_solver/linear_solver_go_wrap.cc: \
  $(SRC_DIR)/ortools/linear_solver/go/linear_solver.i \
  $(SRC_DIR)/ortools/base/base.i \
  $(LP_DEPS) \
  | $(GEN_DIR)/ortools/linear_solver
	$(SWIG_BINARY) $(SWIG_INC) -I$(INC_DIR) -c++ -go -cgo \
  -o $(GEN_PATH)$Sortools$Slinear_solver$Slinear_solver_go_wrap.cc \
  -package ortools$Sgo$Slinear_solver$Sgen \
  -module linear_solver_wrapper \
  -outdir ortools$Sgo$Slinear_solver$Sgen \
  -intgosize 64 \
  -v \
  $(SRC_DIR)$Sortools$Slinear_solver$Sgo$Slinear_solver.i

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
	$(OBJ_DIR)/swig/sat_go_wrap.$O \
	$(OBJ_DIR)/swig/util_go_wrap.$O
	$(DYNAMIC_LD) $(LD_OUT)$(LIB_DIR)$S$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_EXT) \
	$(OBJ_DIR)$Sswig$Ssat_go_wrap.$O \
	$(OBJ_DIR)$Sswig$Sutil_go_wrap.$O \
	$(OR_TOOLS_LNK) \
 	$(OR_TOOLS_LDFLAGS)

go_pimpl: \
	ortools/go/sat/gen/cp_model.pb.go \
	ortools/go/sat/gen/sat_parameters.pb.go \
	ortools/go/linear_solver/gen/mp_model.pb.go \
	$(GEN_DIR)/ortools/linear_solver/linear_solver_go_wrap.cc \
	$(GEN_DIR)/go/util/gen/optional_boolean.pb.go \
	$(GEN_DIR)/ortools/sat/sat_go_wrap.cc \
	$(GEN_DIR)/ortools/util/util_go_wrap.cc \
	$(GO_OR_TOOLS_NATIVE_LIBS)
	cd ortools/go/linear_solver; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v" \
	go build;

# LD_LIBRARY_PATH -> Linux
# DYLD_LIBRARY_PATH -> Mac OS
test_go_pimpl: go_pimpl
	cd ortools/go; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v" \
	LD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	DYLD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	go test -v ./...;

check_go_pimpl: test_go_pimpl

################
##  Cleaning  ##
################
.PHONY: clean_go # Clean Go output from previous build.
clean_go:
	-$(DELREC) ortools$Sgo$Ssat$Sgen
	-$(DELREC) ortools$Sgo$Slinear_solver$Sgen
	-$(DELREC) ortools$Sgo$Sutil$Sgen
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*go_wrap*
	-$(DEL) $(GEN_PATH)$Sortools$Sutil$S*go_wrap*
	-$(DEL) $(OBJ_DIR)$Sswig$S*go_wrap*
	-$(DEL) $(LIB_DIR)$S$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_EXT)


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

ifeq ($(SYSTEM),win)
	@echo off & echo(
else
	@echo
endif
