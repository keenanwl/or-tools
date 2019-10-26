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
	-$(MKDIR_P) ortools/go$Ssat$Sgen

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

$(OBJ_DIR)/swig/sat_go_wrap.$O: \
	$(GEN_DIR)/ortools/sat/sat_go_wrap.cc \
	$(SAT_DEPS) \
	| $(OBJ_DIR)/swig
	$(CCC) $(CFLAGS) \
	-c $(GEN_PATH)$Sortools$Ssat$Ssat_go_wrap.cc \
	$(OBJ_OUT)$(OBJ_DIR)$Sswig$Ssat_go_wrap.$O

$(GO_OR_TOOLS_NATIVE_LIBS): \
 $(OR_TOOLS_LIBS) \
 $(OBJ_DIR)/swig/sat_go_wrap.$O
	$(DYNAMIC_LD) $(LD_OUT)$(LIB_DIR)$S$(LIB_PREFIX)goortools.$(SWIG_GO_LIB_EXT) \
 $(OBJ_DIR)$Sswig$Ssat_go_wrap.$O \
 $(OR_TOOLS_LNK) \
 $(OR_TOOLS_LDFLAGS)

go_pimpl: \
	ortools/go/sat/gen/cp_model.pb.go \
	ortools/go/sat/gen/sat_parameters.pb.go \
	$(GEN_DIR)/ortools/sat/sat_go_wrap.cc \
	$(GO_OR_TOOLS_NATIVE_LIBS)
	cd ortools/go/sat; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v" \
	go build;

# LD_LIBRARY_PATH -> Linux
# DYLD_LIBRARY_PATH -> Mac OS
test_go_pimpl: go_pimpl
	cd ortools/go/sat; \
	CGO_LDFLAGS="-L$(OR_TOOLS_TOP)/lib -lgoortools -v" \
	LD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	DYLD_LIBRARY_PATH="$(OR_TOOLS_TOP)/dependencies/install/lib:$(OR_TOOLS_TOP)/lib:" \
	go test -v;

check_go_pimpl: test_go_pimpl

################
##  Cleaning  ##
################
.PHONY: clean_go # Clean Go output from previous build.
clean_go:
	-$(DELREC) ortools/go$Ssat$Sgen
	-$(DEL) $(GEN_PATH)$Sortools$Ssat$S*go_wrap*
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
