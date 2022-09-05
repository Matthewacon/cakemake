#[[
 This file contains all of the Clang-specific implementations of the
 abstractions in `../compiler.cmake`
]]
cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../compiler.cmake)

#Clang define formatter
assert_name_unique(
 clang_compiler_define_formatter
 COMMAND
 "Name collision: Function 'clang_compiler_define_formatter' is already "
 "defined elsewhere!"
)
function(clang_compiler_define_formatter ccdf_ARG ccdf_VALUE ccdf_DEST)
 set(
  "${ccdf_DEST}"
  "-D${ccdf_ARG}=${ccdf_VALUE}"
  PARENT_SCOPE
 )
endfunction()
add_compiler_define_formatter(Clang clang_compiler_define_formatter)

#Precompiled header handler
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
 message(
  WARNING
  "The Clang precompiled header handler is currently unimplemented!"
 )
else()
 message(
  WARNING
  "cakemake does not support precompiled headers for Clang on the "
  "'${CMAKE_SYSTEM_NAME}' platform!"
 )
endif()
