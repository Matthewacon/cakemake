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

##`is_empty` tests
function(is_empty_no_argument_yields_true)
 is_empty(empty)
 assert_true(${empty})
endfunction()
define_test(is_empty_no_argument_yields_true)

function(is_empty_with_arguments_yields_false)
 is_empty(empty "Hello world!")
 assert_false(${empty})

 is_empty(empty 1 2 3)
 assert_false(${empty})
endfunction()
define_test(is_empty_with_arguments_yields_false)

##`escape_string` tests
function(
 escape_string_escapes_the_expected_characters_and_yields_the_expected_result
)
 #Ensure string with no replacements is unmodified
 set(value1 "Hello world!")
 set(expected1 "Hello world!")
 escape_string(result1 "${value1}")
 assert_equals("${expected1}" "${result1}")

 #Ensure escape sequences are escaped
 set(value2 "\n\r\t")
 set(expected2 "\\n\\r\\t")
 escape_string(result2 "${value2}")
 assert_equals("${expected2}" "${result2}")

 #Ensure special characters are escaped
 set(value3 "\\\"")
 set(expected3 "\\\\\\\"")
 escape_string(result3 "${value3}")
 assert_equals("${expected3}" "${result3}")

 #Ensure escaping of all targets works together
 set(value4 "\"Hello\r\n\t\\world!\"")
 set(expected4 "\\\"Hello\\r\\n\\t\\\\world!\\\"")
 escape_string(result4 "${value4}")
 assert_equals("${expected4}" "${result4}")

 #Ensure no arguments yields an empty string
 set(expected5 "")
 escape_string(result5)
 assert_equals("${expected5}" "${result5}")
endfunction()
define_test(
 escape_string_escapes_the_expected_characters_and_yields_the_expected_result
)

##`get_project_prefix` tests
function(get_project_prefix_outside_project_scope_yields_expected_value)
 unset(CMAKE_PROJECT_NAME)
 get_project_prefix(project_prefix)
 assert_equals("NO_PROJECT" "${project_prefix}")
endfunction()
define_test(get_project_prefix_outside_project_scope_yields_expected_value)

function(get_project_prefix_in_project_scope_yields_project_name)
 unset(CMAKE_PROJECT_NAME)
 set(CMAKE_PROJECT_NAME "example_project")
 string(TOUPPER "${CMAKE_PROJECT_NAME}" expected_value)
 get_project_prefix(project_prefix)
 assert_equals("${expected_value}" "${project_prefix}")
 unset(expected_value)
endfunction()
define_test(get_project_prefix_in_project_scope_yields_project_name)

##`generate_unique_name` tests
function(generate_unique_name_yields_expected_value_for_command_condition)
 #Test for existing command
 generate_unique_name(set COMMAND unique_name)
 assert_not_equals(set "${unique_name}")

 #Test for non-existent command
 generate_unique_name(abcd COMMAND unique_name)
 assert_equals(abcd "${unique_name}")
endfunction()
define_test(generate_unique_name_yields_expected_value_for_command_condition)

function(generate_unique_name_yields_expected_value_for_variable_condition)
 #Test for existing variable
 set(VAR1 "")
 generate_unique_name(VAR1 VARIABLE unique_name)
 assert_not_equals(VAR1 "${unique_name}")

 #Test for existing cache variable
 set(VAR2 "" CACHE STRING "")
 generate_unique_name(VAR2 VARIABLE unique_name)
 assert_not_equals(VAR2 "${unique_name}")

 #Test for non-existent variable
 unset(VAR3)
 generate_unique_name(VAR3 VARIABLE unique_name)
 assert_equals(VAR3 "${unique_name}")
endfunction()
define_test(generate_unique_name_yields_expected_value_for_variable_condition)

function(generate_unique_name_yields_expected_value_for_cache_condition)
 #Test for existing cache variable
 set(VAR1 "" CACHE STRING "")
 generate_unique_name(VAR1 CACHE unique_name)
 assert_not_equals(VAR1 "${unique_name}")

 #Test for existing variable
 set(VAR2 "")
 generate_unique_name(VAR2 CACHE unique_name)
 assert_equals(VAR2 "${unique_name}")

 #Test for non-existent cache variable
 unset(VAR3 CACHE)
 generate_unique_name(VAR3 CACHE unique_name)
 assert_equals(VAR3 "${unique_name}")
endfunction()
define_test(generate_unique_name_yields_expected_value_for_cache_condition)

function(generate_unique_name_yields_expected_value_for_env_condition)
endfunction()
define_test(generate_unique_name_yields_expected_value_for_env_condition)
