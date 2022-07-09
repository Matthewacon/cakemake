cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

#Configure test suite
set(SUITE_NAME "Test suite for src/compiler.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../test.cmake")

#Include script to test
include("${CMAKE_CURRENT_LIST_DIR}/../src/compiler.cmake")

##`get_project_compiler_details_prefix` tests
function(
 get_project_compiler_details_prefix_raises_error_for_invalid_destination_variable
)
 get_project_compiler_details_prefix("")
endfunction()
define_test(
 get_project_compiler_details_prefix_raises_error_for_invalid_destination_variable
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_project_compiler_details_prefix_yields_expected_value)
 get_project_compiler_details_prefix(result)
 assert_equals("NO_PROJECT_COMPILER_DETAILS" "${result}")
endfunction()
define_test(get_project_compiler_details_prefix_yields_expected_value)

##`detect_compiler` tests
function(detect_compiler_raises_error_for_invalid_destination_variable)
 detect_compiler("")
endfunction()
define_test(
 detect_compiler_raises_error_for_invalid_destination_variable
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(detect_compiler_detects_the_correct_compiler_and_sets_all_expected_values)
 #Compiler details variable prefix
 get_project_compiler_details_prefix(prefix)

 set(my_compiler_id_variable "abcd")

 detect_compiler(
  detected_compiler
  COMPILER_ID my_compiler_id_variable
  SUPPORTED_COMPILERS abcd efgh
 )

 assert_equals("abcd" "${detected_compiler}")
 assert_equals("abcd" "${${prefix}_DETECTED_COMPILER_ID}")
 assert_equals("abcd;efgh" "${${prefix}_SUPPORTED_COMPILERS}")
 assert_equals("FALSE" "${${prefix}_ALLOW_UNSUPPORTED}")
endfunction()
define_test(
 detect_compiler_detects_the_correct_compiler_and_sets_all_expected_values
)

function(define_compiler_raises_error_when_detecting_unsupported_compiler)
 #Compiler details varaible prefix
 get_project_compiler_details_prefix(prefix)

 set(my_compiler_id_variable "some_unsupported_compiler")

 detect_compiler(
  detected_compiler
  COMPILER_ID my_compiler_id_variable
  SUPPORTED_COMPILERS a b c
 )
endfunction()
define_test(
 define_compiler_raises_error_when_detecting_unsupported_compiler
 REGEX "'some_unsupported_compiler' is an unsupported compiler. Supported "
  "compilers include: "
  "\n - a"
  "\n - b"
  "\n - c"
 EXPECT_FAIL
)

function(
 define_compiler_succeeds_when_detecting_unsupported_compiler_with_allow_unsupported
)
 #Compiler details variable prefix
 get_project_compiler_details_prefix(prefix)

 set(my_compiler_id_variable "some_unsupported_compiler")

 detect_compiler(
  detect_compiler
  COMPILER_ID my_compiler_id_variable
  SUPPORTED_COMPILERS a b c
  ALLOW_UNSUPPORTED
 )

 assert_equals("some_unsupported_compiler" "${detected_compiler}")
 assert_equals("some_unsupported_compiler" "${${prefix}_DETECTED_COMPILER_ID}")
 assert_equals("a;b;c" "${${prefix}_SUPPORTED_COMPILERS}")
 assert_equals("TRUE" "${${prefix}_ALLOW_UNSUPPORTED}")
endfunction()
define_test(
 define_compiler_succeeds_when_detecting_unsupported_compiler_with_allow_unsupported
)

##TODO `get_supported_compilers` tests
##TODO `is_compiler_supported` tests
##TODO `add_compiler_define_formatter` tests
##TODO `get_compiler_define_formatter` tests
##TODO `remove_compiler_define_formatter` tests
##TODO `add_cc_define` tests
##TODO `add_cc_or_ld_argument` tests
