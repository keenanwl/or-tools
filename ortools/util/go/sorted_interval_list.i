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

// This is the go SWIG wrapper for ../sorted_interval_list.h.  See that file.

%include "ortools/base/base.i"

%include "ortools/util/go/vector.i"

%{
#include <vector>
#include "ortools/base/integral_types.h"
#include "ortools/util/sorted_interval_list.h"
%}

%module operations_research;

%ignoreall

%unignore operations_research;

%unignore operations_research::Domain;
%unignore operations_research::Domain::Domain;


%include "ortools/util/sorted_interval_list.h"

%unignoreall