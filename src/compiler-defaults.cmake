cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/compiler.cmake)

#[[
 Pre-defined compiler define formatters

 TODO:
  - add cc define formatters for all supported compilers
]]
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

#GCC define formatter
assert_name_unique(
 gnu_compiler_define_formatter
 COMMAND
 "Name collision: Function 'gnu_compiler_define_formatter' is already "
 "defined elsewhere!"
)
function(gnu_compiler_define_formatter ccdf_ARG ccdf_VALUE ccdf_DEST)
 set(
  "${ccdf_DEST}"
  "-D${ccdf_ARG}=${ccdf_VALUE}"
  PARENT_SCOPE
 )
endfunction()
add_compiler_define_formatter(GNU gnu_compiler_define_formatter)
