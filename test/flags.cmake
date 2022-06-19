cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "Test suite for src/flags.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../test.cmake")

#Include script to test
include("${CMAKE_CURRENT_LIST_DIR}/../src/flags.cmake")

##`get_project_flags_variable` tests
function(
 get_project_flags_variable_empty_destination_varaible_argument_raises_error
)
 get_project_flags_variable("")
endfunction()
define_test(
 get_project_flags_variable_empty_destination_varaible_argument_raises_error
 REGEX "argument must not be empty!"
 EXPECT_FAIL
)

function(get_project_flags_variable_outside_project_scope_yields_expected_name)
 unset(CMAKE_PROJECT_NAME)
 get_project_flags_variable(flags_variable)
 assert_equals("NO_PROJECT_BUILD_FLAGS" "${flags_variable}")
endfunction()
define_test(get_project_flags_variable_outside_project_scope_yields_expected_name)

function(get_project_flags_variable_in_project_yields_expected_name)
 set(CMAKE_PROJECT_NAME "example_project")
 string(TOUPPER "${CMAKE_PROJECT_NAME}" expected_value)
 string(APPEND expected_value "_BUILD_FLAGS")
 get_project_flags_variable(flags_variable)
 assert_equals("${expected_value}" "${flags_variable}")
endfunction()
define_test(get_project_flags_variable_in_project_yields_expected_name)

##`does_build_flag_exist` tests
function(does_build_flag_exist_invalid_flag_argumnet_raises_error)
 does_build_flag_exist("" "")
endfunction()
define_test(
 does_build_flag_exist_invalid_flag_argumnet_raises_error
 REGEX "Flag name cannot be empty!"
 EXPECT_FAIL
)

function(does_build_flag_exist_invalid_destination_variable_raises_error)
 does_build_flag_exist(some_flag "")
endfunction()
define_test(
 does_build_flag_exist_invalid_destination_variable_raises_error
 REGEX "Destination variable name cannot be empty!"
 EXPECT_FAIL
)

function(does_build_flag_exist_nonexistent_flag_yields_false)
 does_build_flag_exist(non_existent_flag exists)
 assert_false(${exists})
endfunction()
define_test(does_build_flag_exist_nonexistent_flag_yields_false)

function(does_build_flag_exist_existing_flag_yields_true)
 #Manually append flag to project flags list
 get_project_flags_variable(flags_list_var)
 list(APPEND "${flags_list_var}" some_flag)

 does_build_flag_exist(some_flag exists)
 assert_true(${exists})
endfunction()
define_test(does_build_flag_exist_existing_flag_yields_true)

#[[TODO
 - add_build_flag
 - add_fixed_build_flag
 - is_build_flag_configurable
 - get_build_flag_list
 - get_build_flag
 - get_build_flag_description
 - get_build_flags_pretty
]]
