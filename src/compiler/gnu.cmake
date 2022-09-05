#[[
 This file contains all of the GNU-specific implementations of the
 abstractions in `../compiler.cmake`
]]
cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/../compiler.cmake)

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
