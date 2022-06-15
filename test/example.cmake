cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "An example test suite")
include("${CMAKE_CURRENT_LIST_DIR}/../test.cmake")

function(this_is_some_test)
 message("Hello world from 'this_is_some_test'!")
endfunction()
define_test(this_is_some_test)

function(this_is_another_test)
 message("Hello world from 'this_is_another_test'!")
endfunction()
define_test(this_is_another_test)

function(this_is_a_third_test)
 message("this_is_a_third_test")
endfunction()
define_test(this_is_a_third_test)
