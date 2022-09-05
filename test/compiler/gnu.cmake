cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "Test suite for src/compiler/gnu.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../../test.cmake")

#Include script to test
include("${CMAKE_CURRENT_LIST_DIR}/../../src/compiler/gnu.cmake")

##`gnu_compiler_define_formatter` tests
function(gnu_compiler_define_formatter_yields_expected_value)
 gnu_compiler_define_formatter(
  A
  B
  value
 )
 assert_equals("-DA=B" "${value}")
endfunction()
define_test(gnu_compiler_define_formatter_yields_expected_value)
