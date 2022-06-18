cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "Test suite for src/util.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../test.cmake")

#Include script to test
include("${CMAKE_CURRENT_LIST_DIR}/../src/util.cmake")


##`is_name_unique` tests
#`COMMAND` condition test
function(is_name_unique_yields_expected_result_for_command_condition)
 #Test for non-existent command
 is_name_unique(some_nonexistent_command COMMAND exists)
 assert_true(${exists})

 #Test for existing command
 is_name_unique(is_name_unique COMMAND exists)
 assert_false(${exists})

endfunction()
define_test(is_name_unique_yields_expected_result_for_command_condition)

#`VARIABLE` condition test
function(is_name_unique_yields_expected_results_for_variable_condition)
 #Test for non-existent variable
 unset(VAR1)
 is_name_unique(VAR1 VARIABLE exists)
 assert_true(${exists})

 #Test for existing variable
 unset(VAR2)
 set(VAR2 "")
 is_name_unique(VAR2 VARIABLE exists)
 assert_false(${exists})

 #Test for cache varaible
 unset(VAR3 CACHE)
 set(VAR3 "" CACHE STRING "")
 is_name_unique(VAR3 VARIABLE exists)
 assert_false(${exists})
endfunction()
define_test(is_name_unique_yields_expected_results_for_variable_condition)

#`CACHE` condition test
function(is_name_unique_yields_expected_results_for_cache_condition)
 #Test for non-existent variable
 unset(VAR1 CACHE)
 is_name_unique(VAR1 CACHE exists)
 assert_true(${exists})

 #Test for existing variable
 unset(VAR2 CACHE)
 set(VAR2 "" CACHE STRING "")
 is_name_unique(VAR2 CACHE exists)
 assert_false(${exists})

 #Test for non-cache variable
 unset(VAR3)
 set(VAR3 "")
 is_name_unique(VAR3 CACHE exists)
 assert_true(${exists})
endfunction()
define_test(is_name_unique_yields_expected_results_for_cache_condition)

#`ENV` condition test
function(is_name_unique_yields_expected_results_for_environment_condition)
 #Test for non-existent environment variable
 unset(ENV{VAR1})
 is_name_unique(VAR1 ENV exists)
 assert_true(${exists})

 #Test for existing environment variable
 unset(ENV{VAR2})
 set(ENV{VAR2} "")
 is_name_unique(VAR2 ENV exists)
 assert_false(${exists})
endfunction()

##`assert_name_unique` tests
#`COMMNAD` condition tests
function(assert_name_unique_does_not_fail_on_nonexistent_command_condition)
 assert_name_unique(some_nonexistent_command COMMAND)
endfunction()
define_test(assert_name_unique_does_not_fail_on_nonexistent_command_condition)

function(assert_name_unique_raises_error_on_existing_command_condition)
 assert_name_unique(assert_name_unique COMMAND)
endfunction()
define_test(
 assert_name_unique_raises_error_on_existing_command_condition
 REGEX "assert_name_unique: 'assert_name_unique' is not a unique COMMAND!"
 EXPECT_FAIL
)

#`VARAIBLE` condition tests
function(assert_name_unique_does_not_fail_on_nonexistent_variable_condition)
 unset(VAR1)
 assert_name_unique(VAR1 VARIABLE)
endfunction()
define_test(assert_name_unique_does_not_fail_on_nonexistent_variable_condition)

function(assert_name_unique_raises_error_on_existing_variable_condition)
 unset(VAR1)
 set(VAR1 "")
 assert_name_unique(VAR1 VARIABLE)
endfunction()
define_test(
 assert_name_unique_raises_error_on_existing_variable_condition
 REGEX "assert_name_unique: 'VAR1' is not a unique VARIABLE!"
 EXPECT_FAIL
)

function(assert_name_unique_raises_error_on_existing_cache_variable_condition)
 unset(VAR1 CACHE)
 set(VAR1 "" CACHE STRING "")
 assert_name_unique(VAR1 VARIABLE)
endfunction()
define_test(
 assert_name_unique_raises_error_on_existing_cache_variable_condition
 REGEX "assert_name_unique: 'VAR1' is not a unique VARIABLE!"
 EXPECT_FAIL
)

#`CACHE` condition tests
function(assert_name_unique_does_not_fail_on_nonexistent_cache_condition)
 unset(VAR1 CACHE)
 assert_name_unique(VAR1 CACHE)
endfunction()
define_test(assert_name_unique_does_not_fail_on_nonexistent_cache_condition)

function(assert_name_unique_raises_error_on_existing_cache_condition)
 unset(VAR1 CACHE)
 set(VAR1 "" CACHE STRING "")
 assert_name_unique(VAR1 CACHE)
endfunction()
define_test(
 assert_name_unique_raises_error_on_existing_cache_condition
 REGEX "assert_name_unique: 'VAR1' is not a unique CACHE!"
 EXPECT_FAIL
)

function(
 assert_name_unique_does_not_fail_on_nonexistent_variable_cache_condition
)
 unset(VAR1)
 set(VAR1 "")
 assert_name_unique(VAR1 CACHE)
endfunction()
define_test(
 assert_name_unique_does_not_fail_on_nonexistent_variable_cache_condition
)

#`ENV` condition tests
function(assert_name_unique_does_not_fail_on_nonexistent_env_condition)
 unset(ENV{VAR1})
 assert_name_unique(VAR1 ENV)
endfunction()
define_test(assert_name_unique_does_not_fail_on_nonexistent_env_condition)

function(assert_name_unique_raises_error_on_existing_env_condition)
 unset(ENV{VAR1})
 set(ENV{VAR1} " ")
 assert_name_unique(VAR1 ENV)
endfunction()
define_test(
 assert_name_unique_raises_error_on_existing_env_condition
 REGEX "assert_name_unique: 'VAR1' is not a unique ENV!"
 EXPECT_FAIL
)
