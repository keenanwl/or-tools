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

// SWIG macros to be used in generating Java wrappers for C++ protocol
// message parameters.  Each protocol message is serialized into
// byte[] before passing into (or returning from) C++ code.
//
// If the C++ function expects an input protocol message:
//   foo(const MyProto* message,...)
// Use PROTO_INPUT macro:
//   PROTO_INPUT(MyProto, com.google.proto.protos.test.MyProto, message)
//
// if the C++ function returns a protocol message:
//   MyProto* foo();
// Use PROTO2_RETURN macro:
//   PROTO2_RETURN(MyProto, com.google.proto.protos.test.MyProto, giveOwnership)
//   -> the 'giveOwnership' parameter should be true iff the C++ function
//      returns a new proto which should be deleted by the client.
//
// Passing each protocol message from Java to C++ by value. Each ProtocolMessage
// is serialized into byte[] when it is passed from Java to C++, the C++ code
// deserializes into C++ native protocol message.
//
// @param CppProtoType the fully qualified C++ protocol message type
// @param GoProtoType the corresponding fully qualified Java protocol message
//        type
// @param param_name the parameter name
//
// TODO(user): move this file to base/swig/java

%include "ortools/base/base.i"

%{
#include "ortools/base/integral_types.h"
%}

%define PROTO_INPUT(CppProtoType, GoProtoType, param_name)
%typemap(gotype) PROTO_TYPE* INPUT, PROTO_TYPE& INPUT "GoProtoType"
%typemap(imtype) PROTO_TYPE* INPUT, PROTO_TYPE& INPUT "[]byte"
%typemap(goin) PROTO_TYPE* INPUT, PROTO_TYPE& INPUT {
  // hello go
  bytes, err := proto.Marshal(&$input)
  if err != nil {
    panic(err)
  }
  $result = bytes
}
%typemap(in) PROTO_TYPE* INPUT (CppProtoType temp), PROTO_TYPE& INPUT (CppProtoType temp) {
  // hello c
  bool parsed_ok = temp.ParseFromArray($input.array, $input.len);
  if (!parsed_ok) {
    _swig_gopanic("Unable to parse CppProtoType protocol message.");
  }
  $1 = &temp;
}

%apply PROTO_TYPE& INPUT { const CppProtoType& param_name }
%apply PROTO_TYPE& INPUT { CppProtoType& param_name }
%apply PROTO_TYPE* INPUT { const CppProtoType* param_name }
%apply PROTO_TYPE* INPUT { CppProtoType* param_name }

%enddef // PROTO_INPUT

%define PROTO2_RETURN(CppProtoType, GoProtoType)
%typemap(gotype) CppProtoType "GoProtoType"
%typemap(imtype) CppProtoType "[]uint8"
%typemap(goout) CppProtoType {

  var pb GoProtoType
  goString := $1

  if len(goString) == 0 {
    panic("trouble with reading")
  } else {
    m := make([]byte, len(goString))
    copy(m, goString)

    err := proto.Unmarshal(m, &pb)

    if err != nil {
      panic(err)
    }

    $result = pb
  }

  return pb
}

%typemap(out) CppProtoType {
  const int size = $1.ByteSize();
  uint8* im = new uint8[size];
  $1.SerializeWithCachedSizesToArray(im);
  $result = (_goslice_){im, size};
}

%enddef // PROTO2_RETURN


