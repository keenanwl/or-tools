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

// SWIG Macros to use std::vector<Num> and const std::vector<Num>& in Java,
// where Num is an atomic numeric type.
//
// Normally we'd simply use %include "std_vector.i" with the %template
// directive (see http://www.swig.org/Doc1.3/Library.html#Library_nn15), but
// in google3 we can't, because exceptions are forbidden.
//
// TODO(user): move to base/swig/java.
//%{
//#define SWIGWORDSIZE64
//%}

%include "stdint.i"

%include "ortools/base/base.i"

%{
#include <vector>
#include "ortools/base/integral_types.h"
%}

// Typemaps to represents arguments of types "const std::vector<CType>&" or
// "std::vector<CType>" as JavaType[] (<PrimitiveType>Array).
// note: CType must be a primitive data type (PDT).
// ref: https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#Get_PrimitiveType_ArrayElements_routines
%define VECTOR_AS_GO_ARRAY(CType, GoType, ArrayType)
// This part is for const std::vector<>&.
%typemap(gotype) const std::vector<CType>& "[]GoType"
//%typemap(goin) const std::vector<CType>& "$goinput"
%typemap(imtype) const std::vector<CType>& "[]GoType"
%typemap(ctype) const std::vector<CType>& %{
  CType*  
%}
%typemap(in) const std::vector<CType>& %{
  // Hello c 1
  $1 = new std::vector<CType>;
  $1->reserve($input.len);

  CType* val = reinterpret_cast<CType*&>(_swig_go_0.array);
  for (int i = 0; i < $input.len; ++i) {
    $1->emplace_back(val[i]);
  }
  std::vector<CType>().swap(*$1);

%}
%typemap(freearg) const std::vector<CType>& %{
  //l3
  delete $1;
%}
%typemap(out) const std::vector<CType>& %{
  //l1
  CType arr[$1.size()];
  std::copy($1.begin(), $1.end(), arr);
  $result = arr;
%}
%typemap(argout) const std::vector<CType>& %{
  //l1
  //CType arr[$input.size()];
  //$result = reinterpret_cast<$1;
%}
//%typemap(goin) const std::vector<CType>& %{
  //l2
  //$result = new std::vector< CType >((const std::vector< CType> &)$1);
//%}
// Now, we do it for std::vector<>.
%typemap(gotype) std::vector<CType> %{[]GoType %}
//%typemap(goin) std::vector<Ctype> %{ $goinput %}
//%typemap(imtype) std::vector<CType> %{ []GoType %}
%typemap(ctype) std::vector<CType>  %{ CType* %}
%typemap(in) std::vector<CType> %{
    // Hello c 2
    $1.clear();
    $1.reserve(sizeof($input));

    CType* val = reinterpret_cast<CType*&>($input);
    for (int i = 0; i < sizeof($input); ++i) {
      $1.emplace_back(*(val+i));
    }
%}
%typemap(goin) const std::vector<CType> %{
  //l55555555
  //var BREAKER
%}
//%typemap(goout) const std::vector<CType> %{
  //l55555555pp
  //var BREAKER
//%}
%typemap(argout) std::vector<CType> %{
  // HERE1
  //$result = new std::vector< CType >((const std::vector< CType> &)$1);
%}
//%typemap(goin) std::vector<CType> {
  // LOOKHHH
//}
%enddef  // VECTOR_AS_JAVA_ARRAY


// Typemaps to represents arguments of types "const std::vector<std::vector<CType>>&" or
// "std::vector<std::vector<CType>>*" as JavaType[][] (ObjectArray of JavaTypeArrays).
// note: CType must be a primitive data type (PDT).
// ref: https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#GetObjectArrayElement
// ref: https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/functions.html#Get_PrimitiveType_ArrayElements_routines
%define MATRIX_AS_GO_ARRAY(CType, GoType, ArrayType)
// This part is for const std::vector<std::vector<>>&.
//%typemap(gotype) const std::vector<std::vector<CType> >& %{
    // GOTYPE
  //[][]GoType
//%}
//%typemap(goin) const std::vector<std::vector<CType> >& %{
  //GO IN HERE
//%}
//%typemap(imtype) const std::vector<std::vector<CType> >& %{
  // IMTYPE
  //[]GoType
//%}
%typemap(ctype)  const std::vector<std::vector<CType> >&  %{
  CType*
%}
%typemap(in) const std::vector<std::vector<CType> >&  (std::vector<std::vector<CType> > result) %{
    result.clear();
    result.resize(sizeof($input));
    //QQQQQQQQQQQ
    CType* inner_array = reinterpret_cast<CType*>($input.array);
    int actualIndex = 0;
    for (int index1 = 0; index1 < sizeof($input); ++index1) {
        result[index1].reserve(sizeof(inner_array[actualIndex]));
        for (int index2 = 0; index2 < sizeof(inner_array[actualIndex]); ++index2) {
            const CType value = inner_array[actualIndex];
            result[index1].emplace_back(value);
            actualIndex++;
        }
    }

    $1 = (&result);
%}
%typemap(out)  const std::vector<std::vector<CType> >&  (std::vector<std::vector<CType> > result) %{
//LALALALALALA2
return $1
%}
%typemap(goin)  const std::vector<std::vector<CType> >& %{
  //LALALALALALA3
%}
%typemap(goout)  const std::vector<std::vector<CType> >& %{
  //LALALALALALA4
%}
// Now, we do it for std::vector<std::vector<>>*
%typemap(gotype) std::vector<std::vector<CType> >* "[][]GoType"
//%typemap(goin) std::vector<std::vector<CType> >* "$goinput"
%typemap(imtype) std::vector<std::vector<CType> >* "[][]GoType"
%typemap(ctype, out="void*") std::vector<std::vector<CType> >*  %{
  CType*
%}
%typemap(in) const std::vector<std::vector<CType> >*  (std::vector<std::vector<CType> > result) %{
    result.clear();
    result.resize(sizeof($input));
    //HEEEAAAA
    CType* inner_array = reinterpret_cast<CType*>($input.array);

    int actualIndex = 0;
    for (int index1 = 0; index1 < sizeof($input); ++index1) {
        result[index1].reserve(sizeof(inner_array[actualIndex]));
        for (int index2 = 0; index2 < sizeof(inner_array[actualIndex]); ++index2) {
            const CType value = inner_array[actualIndex];
            result[index1].emplace_back(value);
            actualIndex++;
        }
    }

    $1 = reinterpret_cast<std::vector<std::vector<CType> >*>(&result);
%}
%typemap(goin) std::vector<std::vector<CType> >* {
  // LOOKHHH
}
%typemap(goout) std::vector<std::vector<CType> >* {
  // LOOKHHH2
}
%enddef  // MATRIX_AS_JAVA_ARRAY

//%define REINTERPRET_CAST(CType, ptr)
//reinterpret_cast<CType*>(ptr)
//%enddef
