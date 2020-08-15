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

// This is the java SWIG wrapper for ../sorted_interval_list.h.  See that file.

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

%unignore operations_research::SortedDisjointIntervalList;
%unignore operations_research::SortedDisjointIntervalList::SortedDisjointIntervalList;
%ignore operations_research::SortedDisjointIntervalList::SortedDisjointIntervalList(const std::vector<ClosedInterval>&);
%unignore operations_research::SortedDisjointIntervalList::~SortedDisjointIntervalList;

%rename (SortedDisjointIntervalList) operations_research::SortedDisjointIntervalList;
%rename (InsertInterval) operations_research::SortedDisjointIntervalList::InsertInterval;
%rename (InsertIntervals) operations_research::SortedDisjointIntervalList::InsertIntervals;
%rename (NumIntervals) operations_research::SortedDisjointIntervalList::NumIntervals;
%rename (BuildComplementOnInterval) operations_research::SortedDisjointIntervalList::BuildComplementOnInterval;
%rename (String) operations_research::SortedDisjointIntervalList::DebugString;


%unignore operations_research;
%unignore operations_research::Domain;
%unignore operations_research::Domain::Domain;

%rename (AdditionWith) operations_research::Domain::AdditionWith;
%rename (AllValues) operations_research::Domain::AllValues;
%rename (Complement) operations_research::Domain::Complement;
%rename (Contains) operations_research::Domain::Contains;
%rename (FlattenedIntervals) operations_research::Domain::FlattenedIntervals;
%rename (FromFlatIntervals) operations_research::Domain::FromFlatIntervals;
%rename (FromIntervals) operations_research::Domain::FromVectorIntervals;
%rename (FromValues) operations_research::Domain::FromValues;
%rename (IntersectionWith) operations_research::Domain::IntersectionWith;
%rename (IsEmpty) operations_research::Domain::IsEmpty;
%rename (Max) operations_research::Domain::Max;
%rename (Min) operations_research::Domain::Min;
%rename (Negation) operations_research::Domain::Negation;
%rename (Size) operations_research::Domain::Size;
%rename (ToString) operations_research::Domain::ToString;
%rename (UnionWith) operations_research::Domain::UnionWith;

%include "ortools/util/sorted_interval_list.h"
%unignoreall
