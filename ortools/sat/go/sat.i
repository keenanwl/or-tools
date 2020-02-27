// Copyright 2010-2018 Google LLC
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

%include "stdint.i"

%include "ortools/base/base.i"

%{
#include "ortools/sat/cp_model.pb.h"
#include "ortools/sat/sat_parameters.pb.h"
#include "ortools/sat/swig_helper.h"
%}

typedef int64_t int64;
typedef uint64_t uint64;

%go_import("github.com/golang/protobuf/proto")

%module(directors="1") sat_wrapper

%include "ortools/util/go/proto.i"

PROTO_INPUT(operations_research::sat::CpModelProto,
	CpModelProto,
	model_proto);

PROTO_INPUT(operations_research::sat::SatParameters,
	SatParameters,
	parameters);

PROTO_INPUT(operations_research::sat::CpSolverResponse,
	CpSolverResponse,
	response);

PROTO2_RETURN(operations_research::sat::CpSolverResponse,
	CpSolverResponse);

%ignoreall

%unignore operations_research;
%unignore operations_research::sat;

// Wrap the relevant part of the SatHelper.
%unignore operations_research::sat::SatHelper;
%rename (solve) operations_research::sat::SatHelper::Solve;
%rename (solveWithParameters) operations_research::sat::SatHelper::SolveWithParameters;

%rename (validateModel) operations_research::sat::SatHelper::ValidateModel;

%include "ortools/sat/swig_helper.h"

%unignoreall
