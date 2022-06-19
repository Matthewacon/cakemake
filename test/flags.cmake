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

##TODO `add_build_flag` tests
function(add_build_flag_invalid_flag_name_raises_error)
 add_build_flag("")
endfunction()
define_test(
 add_build_flag_invalid_flag_name_raises_error
 REGEX "Flag name cannot be empty!"
 EXPECT_FAIL
)

function(add_build_flag_with_no_value_unsets_flag_value)
 set(some_flag "Example value")
 add_build_flag(some_flag)
 if(DEFINED some_flag)
  message(
   FATAL_ERROR
   "Expected variable 'some_flag' to be unset!"
  )
 endif()
endfunction()
define_test(add_build_flag_with_no_value_unsets_flag_value)

function(add_build_flag_with_value_sets_value)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)

 #Add flag
 unset(some_flag)
 add_build_flag(some_flag VALUE "Hello world!")

 #Ensure flag was added to project flags list var
 list(FIND "${flags_list_var}" some_flag exists)
 assert_not_equals(-1 ${exists})

 #Ensure flag was updated with correct value
 assert_equals("Hello world!" "${some_flag}")
endfunction()
define_test(add_build_flag_with_value_sets_value)

function(add_build_flag_with_multiple_values_appends_to_list)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)

 #Add flag
 unset(some_flag)
 add_build_flag(some_flag VALUE 1 2 3 4 5)

 #Ensure flag was added to project flags list var
 list(FIND "${flags_list_var}" some_flag exists)
 assert_not_equals(-1 ${exists})

 #Ensure flag was updated with correct value
 assert_equals("1;2;3;4;5" "${some_flag}")
endfunction()
define_test(add_build_flag_with_multiple_values_appends_to_list)

function(
 add_build_flag_without_description_named_parameter_uses_default_description
)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)
 set(FLAGS_DESCRIPTION_VAR "${flags_list_var}_some_flag_DESCRIPTION")

 #Add flag
 add_build_flag(some_flag)

 #Ensure flag description matches default
 assert_equals("[no description provided]" "${${FLAGS_DESCRIPTION_VAR}}")
endfunction()
define_test(
add_build_flag_without_description_named_parameter_uses_default_description
)

function(add_build_flag_with_description_named_parameter_sets_description)
 #Get name of flag description variable
 get_project_flags_variable(project_flags_list_var)
 set(DESCRIPTION_VAR "${project_flags_list_var}_some_flag_DESCRIPTION")

 add_build_flag(
  some_flag
  DESCRIPTION "Some flag"
 )
 assert_equals("Some flag" "${${DESCRIPTION_VAR}}")
endfunction()
define_test(add_build_flag_with_description_named_parameter_sets_description)

function(
 add_build_flag_with_force_option_and_not_cache_named_parameter_raises_error
)
 add_build_flag(some_var FORCE)
endfunction()
define_test(
 add_build_flag_with_force_option_and_not_cache_named_parameter_raises_error
 REGEX "'FORCE' can only be set alongside 'CACHE'!"
 EXPECT_FAIL
)

function(add_build_flag_with_cache_named_parameter_sets_up_cache_variable)
 add_build_flag(some_flag VALUE "Hello world!" CACHE STRING)

 if(NOT DEFINED CACHE{some_flag})
  message(
   FATAL_ERROR
   "'CACHE' named parameter did not set up cache flag value!"
  )
 endif()
 assert_equals("Hello world!" "${some_flag}")
endfunction()
define_test(add_build_flag_with_cache_named_parameter_sets_up_cache_variable)

#[[TODO
 - add_fixed_build_flag
 - is_build_flag_configurable
 - get_build_flag_list
 - get_build_flag
 - get_build_flag_description
 - get_build_flags_pretty
]]
