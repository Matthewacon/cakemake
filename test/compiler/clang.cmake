cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "Test suite for src/compiler/clang.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../../test.cmake")

#Include script to test
include("${CMAKE_CURRENT_LIST_DIR}/../../src/compiler/clang.cmake")

##`clang_compiler_define_formatter` tests
function(clang_compiler_define_formatter_yields_expected_value)
 clang_compiler_define_formatter(
  A
  B
  value
 )
 assert_equals("-DA=B" "${value}")
endfunction()
define_test(clang_compiler_define_formatter_yields_expected_value)

##TODO Precompiled header handler tests
