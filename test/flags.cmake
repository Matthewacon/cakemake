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

##`add_build_flag` tests
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

function(add_build_flag_adding_the_same_flag_multiple_times_raises_error)
 add_build_flag(some_flag)
 add_build_flag(some_flag)
endfunction()
define_test(
 add_build_flag_adding_the_same_flag_multiple_times_raises_error
 REGEX "Flag 'some_flag' already exists!"
 EXPECT_FAIL
)

##`add_fixed_build_flag` tests
function(add_fixed_build_flag_invalid_flag_name_raises_error)
 add_fixed_build_flag("")
endfunction()
define_test(
 add_fixed_build_flag_invalid_flag_name_raises_error
 REGEX "Flag name cannot be empty!"
 EXPECT_FAIL
)

function(add_fixed_build_flag_sets_unconfigurable_marker)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)
 set(CONFIGURABLE_FLAG "${flags_list_var}_some_fixed_build_flag_CONFIGURABLE")

 #Add flag
 add_fixed_build_flag(some_fixed_build_flag)

 #Ensure unconfigurable marker was set
 assert_false("${${CONFIGURABLE_FLAG}}")
endfunction()
define_test(add_fixed_build_flag_sets_unconfigurable_marker)

function(add_fixed_build_flag_with_no_value_unsets_flag_value)
 set(some_fixed_build_flag "Example value")
 add_fixed_build_flag(some_fixed_build_flag)
 if(DEFINED some_fixed_build_flag)
  message(
   FATAL_ERROR
   "Expected 'some_fixed_build_flag' to be unset!"
  )
 endif()
endfunction()
define_test(add_fixed_build_flag_with_no_value_unsets_flag_value)

function(add_fixed_build_flag_with_value_sets_value)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)

 add_fixed_build_flag(some_fixed_build_flag VALUE "Hello world!")

 #Ensure flag was added to project flags list var
 list(FIND "${flags_list_var}" some_fixed_build_flag exists)
 assert_not_equals(-1 ${exists})

 #Ensure flag was updated with correct value
 assert_equals("Hello world!" "${some_fixed_build_flag}")
endfunction()
define_test(add_fixed_build_flag_with_value_sets_value)

function(add_fixed_build_flag_with_multiple_values_appends_to_list)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)

 #Add flag
 add_fixed_build_flag(some_fixed_build_flag VALUE 1 2 3 4 5)

 #Ensure flag was added to project flags list var
 list(FIND "${flags_list_var}" some_fixed_build_flag exists)
 assert_not_equals(-1 ${exists})

 #Ensure flag was updated with correct value
 assert_equals("1;2;3;4;5" "${some_fixed_build_flag}")
endfunction()
define_test(add_fixed_build_flag_with_multiple_values_appends_to_list)

function(
 add_fixed_build_flag_without_description_named_parameter_uses_default_description
)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)
 set(
  FLAGS_DESCRIPTION_VAR
  "${flags_list_var}_some_fixed_build_flag_DESCRIPTION"
 )

 #Add flag
 add_fixed_build_flag(some_fixed_build_flag)

 #Ensure flag description matches default
 assert_equals("[no description provided]" "${${FLAGS_DESCRIPTION_VAR}}")
endfunction()
define_test(
 add_fixed_build_flag_without_description_named_parameter_uses_default_description
)

function(
 add_fixed_build_flag_with_description_named_parameter_sets_description
)
 #Get project flags list var
 get_project_flags_variable(flags_list_var)
 set(
  FLAGS_DESCRIPTION_VAR
  "${flags_list_var}_some_fixed_build_flag_DESCRIPTION"
 )

 #Add flag
 add_fixed_build_flag(some_fixed_build_flag DESCRIPTION "Hello world!")

 #Ensure flag description matches provided string
 assert_equals("${${FLAGS_DESCRIPTION_VAR}}" "Hello world!")
endfunction()
define_test(
 add_fixed_build_flag_with_description_named_parameter_sets_description
)

function(
 add_fixed_build_flag_with_force_option_and_not_cache_named_parameter_raises_error
)
 add_fixed_build_flag(some_fixed_build_flag FORCE)
endfunction()
define_test(
 add_fixed_build_flag_with_force_option_and_not_cache_named_parameter_raises_error
 REGEX "'FORCE' can only be set alongside 'CACHE'!"
 EXPECT_FAIL
)

function(
 add_fixed_build_flag_with_cache_named_parameter_sets_up_cache_variable
)
 add_fixed_build_flag(some_fixed_build_flag VALUE "ABC" CACHE STRING)

 if(NOT DEFINED CACHE{some_fixed_build_flag})
  message(
   FATAL_ERROR
   "'CACHE' named parameter did not set up cache flag value!"
  )
 endif()
 assert_equals("ABC" "${some_fixed_build_flag}")
endfunction()
define_test(
 add_fixed_build_flag_with_cache_named_parameter_sets_up_cache_variable
)

function(add_fixed_build_flag_adding_the_same_flag_multiple_times_raises_error)
 add_fixed_build_flag(some_fixed_build_flag)
 add_fixed_build_flag(some_fixed_build_flag)
endfunction()
define_test(
 add_fixed_build_flag_adding_the_same_flag_multiple_times_raises_error
 REGEX "Flag 'some_fixed_build_flag' already exists!"
 EXPECT_FAIL
)

##`is_build_flag_configurable` tests
function(is_build_flag_configurable_add_build_flag_yields_true)
 add_build_flag(example_flag)
 is_build_flag_configurable(example_flag is_configurable)
 assert_true(${is_configurable})
endfunction()
define_test(is_build_flag_configurable_add_build_flag_yields_true)

function(is_build_flag_configurable_add_fixed_build_flag_yields_false)
 add_fixed_build_flag(example_flag)
 is_build_flag_configurable(example_flag is_configurable)
 assert_false(${is_configurable})
endfunction()
define_test(is_build_flag_configurable_add_fixed_build_flag_yields_false)

##`get_build_flag_list` tests
function(get_build_flag_list_yields_empty_list_when_no_build_flags_are_present)
 get_build_flag_list(flag_list)
 assert_equals("" "${flag_list}")
endfunction()
define_test(
 get_build_flag_list_yields_empty_list_when_no_build_flags_are_present
)

function(
 get_build_flag_list_yields_expected_value_when_build_flags_are_present
)
 add_build_flag(flag1)
 add_fixed_build_flag(flag2)
 add_fixed_build_flag(flag3)
 add_build_flag(flag4)
 get_build_flag_list(flag_list)
 assert_equals("flag1;flag2;flag3;flag4" "${flag_list}")
endfunction()
define_test(
 get_build_flag_list_yields_expected_value_when_build_flags_are_present
)

##`get_build_flag` tests
function(get_build_flag_with_invalid_flag_name_raises_error)
 get_build_flag("" "")
endfunction()
define_test(
 get_build_flag_with_invalid_flag_name_raises_error
 REGEX "Flag name cannot be empty!"
 EXPECT_FAIL
)

function(get_build_flag_with_invalid_destination_variable_name_raises_error)
 add_build_flag(some_flag)
 get_build_flag(some_flag "")
endfunction()
define_test(
 get_build_flag_with_invalid_destination_variable_name_raises_error
 REGEX "Destination variable name cannot be empty!"
 EXPECT_FAIL
)

function(get_build_flag_with_nonexistent_flag_raises_error)
 get_build_flag(some_flag value)
endfunction()
define_test(
 get_build_flag_with_nonexistent_flag_raises_error
 REGEX "Flag 'some_flag' does not exist!"
 EXPECT_FAIL
)

function(get_build_flag_with_existing_flag_yields_expected_value)
 add_build_flag(flag1 VALUE "Hello world!")
 get_build_flag(flag1 value1)
 assert_equals("Hello world!" "${value1}")

 add_fixed_build_flag(flag2 VALUE "Goodbye world!")
 get_build_flag(flag2 value2)
 assert_equals("Goodbye world!" "${value2}")
endfunction()
define_test(get_build_flag_with_existing_flag_yields_expected_value)

##`get_build_flag_description` tests
function(get_build_flag_description_with_invalid_flag_raises_error)
 get_build_flag_description("" "")
endfunction()
define_test(
 get_build_flag_description_with_invalid_flag_raises_error
 REGEX "Flag name cannot be empty!"
 EXPECT_FAIL
)

function(
 get_build_flag_description_with_invalid_destination_variable_name_raises_error
)
 add_build_flag(some_flag)
 get_build_flag_description(some_flag "")
endfunction()
define_test(
 get_build_flag_description_with_invalid_destination_variable_name_raises_error
 REGEX "Destination variable name cannot be empty!"
 EXPECT_FAIL
)

function(get_build_flag_description_with_nonexistent_flag_raises_error)
 get_build_flag_description(some_flag description)
endfunction()
define_test(
 get_build_flag_description_with_nonexistent_flag_raises_error
 REGEX "Flag 'some_flag' does not exist!"
 EXPECT_FAIL
)

function(get_build_flag_description_with_existing_flag_yields_expected_value)
 #Test with default description
 add_build_flag(flag1)
 get_build_flag_description(flag1 description)
 assert_equals("[no description provided]" "${description}")

 unset(description)
 add_fixed_build_flag(flag2)
 get_build_flag_description(flag2 description)
 assert_equals("[no description provided]" "${description}")

 #Test with specified description
 unset(description)
 add_build_flag(flag3 DESCRIPTION "flag3 description")
 get_build_flag_description(flag3 description)
 assert_equals("flag3 description" "${description}")

 unset(description)
 add_fixed_build_flag(flag4 DESCRIPTION "flag4 description")
 get_build_flag_description(flag4 description)
 assert_equals("flag4 description" "${description}")
endfunction()
define_test(
 get_build_flag_description_with_existing_flag_yields_expected_value
)

##`get_build_flags_pretty` tests
function(get_build_flags_pretty_invalid_destination_variable_name_raises_error)
 get_build_flags_pretty("")
endfunction()
define_test(
 get_build_flags_pretty_invalid_destination_variable_name_raises_error
 REGEX "Destination variable name cannot be empty!"
 EXPECT_FAIL
)

function(get_build_flags_pretty_with_no_build_flags_yields_expected_value)
 get_build_flags_pretty(flags_pretty)
 assert_equals("Build configuration:" "${flags_pretty}")
endfunction()
define_test(get_build_flags_pretty_with_no_build_flags_yields_expected_value)

function(
 get_build_flags_pretty_with_configurable_build_flag_yields_expected_value
)
 add_build_flag(example_flag VALUE "Hello world!")
 get_build_flags_pretty(flags_pretty)
 string(
  APPEND expected
  "Build configuration:"
  "\n - example_flag: Hello world!"
 )
 assert_equals("${expected}" "${flags_pretty}")
endfunction()
define_test(
 get_build_flags_pretty_with_configurable_build_flag_yields_expected_value
)

function(get_build_flags_pretty_with_unconfigurable_flag_yields_expected_value)
 add_fixed_build_flag(example_flag VALUE "Hello world!")
 get_build_flags_pretty(flags_pretty)
 string(
  APPEND expected
  "Build configuration:"
  "\n - [example_flag]: Hello world!"
 )
 assert_equals("${expected}" "${flags_pretty}")
endfunction()
define_test(
 get_build_flags_pretty_with_unconfigurable_flag_yields_expected_value
)

function(get_build_flags_pretty_with_mixed_flags_yields_expected_value)
 add_build_flag(flag1)
 add_fixed_build_flag(flag2 VALUE 123)
 add_build_flag(flag3 VALUE abc)
 add_fixed_build_flag(flag4 VALUE "Hello world!")
 get_build_flags_pretty(flags_pretty)
 string(
  APPEND expected
  "Build configuration:"
  "\n - flag1:   "
  "\n - [flag2]: 123"
  "\n - flag3:   abc"
  "\n - [flag4]: Hello world!"
 )
 assert_equals("${expected}" "${flags_pretty}")
endfunction()
define_test(get_build_flags_pretty_with_mixed_flags_yields_expected_value)
