cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "A second example test suite")
include("${CMAKE_CURRENT_LIST_DIR}/../test.cmake")

function(first_test)
 message("Hello world from 'first_test'!")
endfunction()
define_test(first_test)

function(second_test)
 message("Hello world from 'second_test'!")
endfunction()
define_test(second_test)
