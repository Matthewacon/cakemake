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
  detected_compiler
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

##`get_detected_compiler` tests
function(
 get_detected_compiler_with_empty_destination_variable_name_raises_error
)
 get_detected_compiler("")
endfunction()
define_test(
 get_detected_compiler_with_empty_destination_variable_name_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_detected_compiler_without_prior_detect_compiler_invocation_raises_error)
 get_detected_compiler(detected_compiler)
endfunction()
define_test(
 get_detected_compiler_without_prior_detect_compiler_invocation_raises_error
 REGEX
  "The detected compiler ID is not set! You must call `detect_compiler` "
  "before attempting to retrieve the detected compiler ID!"
 EXPECT_FAIL
)

function(get_detected_compiler_yields_the_expected_compiler_id)
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )

 get_detected_compiler(detected_compiler)
 assert_equals("${compiler_id_var}" "${detected_compiler}")
endfunction()
define_test(get_detected_compiler_yields_the_expected_compiler_id)

##`get_supported_compilers` tests
function(get_supported_compilers_yields_empty_string_when_detect_compiler_is_not_invoked)
 get_supported_compilers(supported_compilers)

 assert_equals("" "${supported_compilers}")
endfunction()
define_test(
 get_supported_compilers_yields_empty_string_when_detect_compiler_is_not_invoked
)

function(get_supported_compilers_yields_expected_value_after_detect_compilers_invocation)
 set(expected_supported_compilers "a b c")

 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS ${expected_supported_compilers}
  ALLOW_UNSUPPORTED
 )

 get_supported_compilers(supported_compilers)
 assert_equals("${expected_supported_compilers}" "${supported_compilers}")
endfunction()
define_test(get_supported_compilers_yields_expected_value_after_detect_compilers_invocation)

##`is_compiler_supported` tests
#TODO Missing argument validation tests
function(
 is_compiler_supported_raises_error_when_invoked_before_detect_compiler
)
 is_compiler_supported(unused some_compiler)
endfunction()
define_test(
 is_compiler_supported_raises_error_when_invoked_before_detect_compiler
 REGEX
  "The detected compiler ID is not set! You must call `detect_compiler` "
  "before checking for supported compilers!"
 EXPECT_FAIL
)

function(is_compiler_supported_yields_false_for_unsupported_compilers)
 set(stub a)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS a b c
 )

 is_compiler_supported(value1 unsupported_compiler)
 assert_false(value1)
endfunction()
define_test(is_compiler_supported_yields_false_for_unsupported_compilers)

function(is_compiler_supported_yields_true_for_supported_compilers)
 set(stub a)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS a b c
 )

 is_compiler_supported(value1 a)
 assert_true(value1)

 is_compiler_supported(value2 b)
 assert_true(value2)

 is_compiler_supported(value3 c)
 assert_true(value3)
endfunction()
define_test(is_compiler_supported_yields_true_for_supported_compilers)

function(
 is_compiler_supported_yields_true_for_all_values_when_allow_unsupported_is_specified
)
 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS a
  ALLOW_UNSUPPORTED
 )

 is_compiler_supported(value1 not_in_list)
 assert_true(value1)

 is_compiler_supported(value2 a)
 assert_true(value2)
endfunction()
define_test(
 is_compiler_supported_yields_true_for_all_values_when_allow_unsupported_is_specified
)

##`add_compiler_define_formatter` tests
function(add_compiler_define_formatter_with_empty_compiler_name_raises_erorr)
 add_compiler_define_formatter("" "")
endfunction()
define_test(
 add_compiler_define_formatter_with_empty_compiler_name_raises_erorr
 REGEX "The <COMPILER> argument must not be empty!"
 EXPECT_FAIL
)

function(
 add_compiler_define_formatter_with_empty_formatter_function_name_raises_error
)
 add_compiler_define_formatter("some_compiler" "")
endfunction()
define_test(
 add_compiler_define_formatter_with_empty_formatter_function_name_raises_error
 REGEX "The <FORMATTER_FUNCTION> argument must not be empty!"
 EXPECT_FAIL
)

function(
 add_compiler_define_formatter_with_non_existent_formatter_function_raises_error
)
 add_compiler_define_formatter("some_compiler" "some_compiler_formatter")
endfunction()
define_test(
 add_compiler_define_formatter_with_non_existent_formatter_function_raises_error
 REGEX "The formatter function 'some_compiler_formatter' is not defined!"
 EXPECT_FAIL
)

function(
 add_compiler_define_formatter_invoked_for_existing_formatter_raises_error
)
 #Compiler details prefix
 get_project_compiler_details_prefix(prefix)

 set("${prefix}_FORMATTERS" "some_compiler")
 set("${prefix}_some_compiler_FORMATTER" "some_compiler_formatter")
 function(some_compiler_formatter)
 endfunction()

 add_compiler_define_formatter("some_compiler" "some_compiler_formatter")
endfunction()
define_test(
 add_compiler_define_formatter_invoked_for_existing_formatter_raises_error
 REGEX
  "The compiler 'some_compiler' already has a define formatter specified! "
  "\\(formatter: 'some_compiler_formatter'\\)"
 EXPECT_FAIL
)

function(add_compiler_define_formatter_sets_the_expected_variables)
 #Compiler details prefix
 get_project_compiler_details_prefix(prefix)

 set(compiler_formatter_list_var "${prefix}_FORMATTERS")
 set(compiler_formatter_name_var "${prefix}_some_compiler_2_FORMATTER")

 function(some_compiler_2_formatter ARG VALUE DEST)
 endfunction()
 add_compiler_define_formatter(some_compiler_2 some_compiler_2_formatter)

 assert_equals("some_compiler_2" "${${compiler_formatter_list_var}}")
 assert_equals("some_compiler_2_formatter" "${${compiler_formatter_name_var}}")
endfunction()
define_test(add_compiler_define_formatter_sets_the_expected_variables)

##`get_compiler_define_formatter` tests
function(get_compiler_define_formatter_with_empty_compiler_name_raises_error)
 get_compiler_define_formatter("" "")
endfunction()
define_test(
 get_compiler_define_formatter_with_empty_compiler_name_raises_error
 REGEX "The <COMPILER> argument must not be empty!"
 EXPECT_FAIL
)

function(
 get_compiler_define_formatter_with_empty_destination_variable_raises_error
)
 get_compiler_define_formatter("some_compiler" "")
endfunction()
define_test(
 get_compiler_define_formatter_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(
 get_compiler_define_formatter_yields_empty_string_for_nonexistent_formatters
)
 get_compiler_define_formatter(some_compiler the_formatter_name)
 assert_equals("" "${the_formatter_name}")
endfunction()
define_test(
 get_compiler_define_formatter_yields_empty_string_for_nonexistent_formatters
)

function(
 get_compiler_define_formatter_yields_expected_value_for_existing_formatter
)
 #Compiler details prefix
 get_project_compiler_details_prefix(prefix)

 set(formatter_list_var "${prefix}_FORMATTERS")
 set(formatter_name_var "${prefix}_some_compiler_FORMATTER")

 #Set up dummy data
 set("${formatter_list_var}" "some_compiler")
 set("${formatter_name_var}" "some_compiler_formatter")

 get_compiler_define_formatter(some_compiler the_formatter_name)
 assert_equals("some_compiler_formatter" "${the_formatter_name}")
endfunction()
define_test(
get_compiler_define_formatter_yields_expected_value_for_existing_formatter
)

##`remove_compiler_define_formatter` tests
function(
 remove_compiler_define_formatter_with_empty_compiler_name_raises_error
)
 remove_compiler_define_formatter("")
endfunction()
define_test(
 remove_compiler_define_formatter_with_empty_compiler_name_raises_error
 REGEX "The <COMPILER> argument must not be empty!"
 EXPECT_FAIL
)

function(remove_compiler_define_formatter_removes_expected_values)
 #Compiler details prefix
 get_project_compiler_details_prefix(prefix)

 set(formatter_list_var "${prefix}_FORMATTERS")
 set(formatter_name_var "${prefix}_some_compiler_FORMATTER")

 #Set up dummy values
 set("${formatter_list_var}" "some_compiler")
 set("${formatter_name_var}" "some_compiler_formatter")

 remove_compiler_define_formatter(some_compiler)
 assert_equals("" "${${formatter_list_var}}")
 is_name_unique("${formatter_name_var}" VARIABLE association_is_deleted)
 assert_true(association_is_deleted)
endfunction()
define_test(remove_compiler_define_formatter_removes_expected_values)

##`add_cc_define` tests
function(add_cc_define_with_empty_define_name_raises_error)
 add_cc_define("" "")
endfunction()
define_test(
 add_cc_define_with_empty_define_name_raises_error
 REGEX "The <DEFINE_NAME> argument must not be empty!"
 EXPECT_FAIL
)

function(
 add_cc_define_with_missing_formatter_for_current_compiler_raises_error
)
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS "${compiler_id_var}"
 )

 add_cc_define(some_define "")
endfunction()
define_test(
 add_cc_define_with_missing_formatter_for_current_compiler_raises_error
 REGEX
  "Missing formatter for compiler 'some_compiler'! You must specify a define "
  "formatter using `add_compiler_define_formatter\\(\\)` for the compiler "
  "'some_compiler'!"
)

function(add_cc_define_invokes_the_expected_formatter_when_adding_an_argument)
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )

 function(formatter_1 ARG VALUE DEST)
  set(formatter_1_invoked TRUE PARENT_SCOPE)
  set("${DEST}" "-D${ARG}=${VALUE}" PARENT_SCOPE)
 endfunction()
 add_compiler_define_formatter(some_compiler formatter_1)

 add_cc_define(some_define some_value)
 assert_true("${formatter_1_invoked}")
endfunction()
define_test(
 add_cc_define_invokes_the_expected_formatter_when_adding_an_argument
)

function(add_cc_define_with_malformed_compiler_define_formatter_raises_error)
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )

 function(formatter_2 ARG VALUE DEST)
 endfunction()
 add_compiler_define_formatter(some_compiler formatter_2)

 add_cc_define(some_define some_value)
endfunction()
define_test(
 add_cc_define_with_malformed_compiler_define_formatter_raises_error
 REGEX
  "The define formatter for the compiler 'some_compiler' did not return a "
  "value! \\(function: 'formatter_2'\\)"
 EXPECT_FAIL
)

function(add_cc_define_sets_the_expected_variables)
 #Get compiler details prefix
 get_project_compiler_details_prefix(prefix)

 #Set up test
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )

 function(formatter_3 ARG VALUE DEST)
  set("${DEST}" "-D${ARG}=${VALUE}" PARENT_SCOPE)
 endfunction()
 add_compiler_define_formatter(some_compiler formatter_3)

 add_cc_define(some_define some_value)

 set(define_list_var "${prefix}_CC_DEFINES")
 set(define_value_var "${prefix}_CC_DEFINE_some_define")
 set(define_formatted_var "${prefix}_CC_DEFINE_some_define_FORMATTED")

 assert_equals("some_define" "${${define_list_var}}")
 assert_equals("some_value" "${${define_value_var}}")
 assert_equals("-Dsome_define=some_value" "${${define_formatted_var}}")
endfunction()
define_test(add_cc_define_sets_the_expected_variables)


##`get_cc_defines` tests
function(get_cc_defines_with_empty_destination_variable_raises_error)
 get_cc_defines("")
endfunction()
define_test(
 get_cc_defines_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(
 get_cc_defines_with_no_prior_add_cc_define_invocation_yields_empty_list
)
 get_cc_defines(cc_defines)
 assert_equals("" "${cc_defines}")
endfunction()
define_test(
 get_cc_defines_with_no_prior_add_cc_define_invocation_yields_empty_list
)

function(
 get_cc_defines_with_prior_add_cc_define_invocations_yields_expected_list
)
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )
 function(formatter_4 ARG VALUE DEST)
  set("${DEST}" "-D${ARG}=${VALUE}" PARENT_SCOPE)
 endfunction()
 add_compiler_define_formatter(some_compiler formatter_4)

 add_cc_define(a a)
 add_cc_define(b b)
 add_cc_define(c c)

 #Get cc defines
 get_cc_defines(cc_defines)
 assert_equals("a;b;c" "${cc_defines}")
endfunction()
define_test(
 get_cc_defines_with_prior_add_cc_define_invocations_yields_expected_list
)

##`get_cc_define_value` tests
function(get_cc_define_value_with_empty_cc_define_name_raises_error)
 get_cc_define_value("" "")
endfunction()
define_test(
 get_cc_define_value_with_empty_cc_define_name_raises_error
 REGEX "The <DEFINE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_cc_define_value_with_empty_destination_variable_name_raises_error)
 #Compiler define prefix
 get_project_compiler_details_prefix(prefix)
 set(cc_defines_list_var "${prefix}_CC_DEFINES")
 set("${cc_defines_list_var}" "some_arg")

 get_cc_define_value("some_arg" "")
endfunction()
define_test(
 get_cc_define_value_with_empty_destination_variable_name_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_cc_define_value_with_non_existent_cc_define_raises_error)
 get_cc_define_value(some_define unused)
endfunction()
define_test(
 get_cc_define_value_with_non_existent_cc_define_raises_error
 REGEX "The cc define 'some_define' does not exist!"
 EXPECT_FAIL
)

function(get_cc_define_value_yields_expected_value)
 #Compiler details prefix
 get_project_compiler_details_prefix(prefix)
 set(cc_defines_list_var "${prefix}_CC_DEFINES")
 set(cc_define_value_var "${prefix}_CC_DEFINE_some_define")

 set("${cc_defines_list_var}" "some_define")
 set("${cc_define_value_var}" "some_value")

 get_cc_define_value(some_define value)
 assert_equals("some_value" "${value}")
endfunction()
define_test(get_cc_define_value_yields_expected_value)

##`get_formatted_cc_define` tests
function(get_formatted_cc_define_with_empty_cc_define_name_raises_error)
 get_formatted_cc_define("" "")
endfunction()
define_test(
 get_formatted_cc_define_with_empty_cc_define_name_raises_error
 REGEX "The <DEFINE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_formatted_cc_define_with_empty_destination_variable_raises_error)
 get_formatted_cc_define(some_define "")
endfunction()
define_test(
 get_formatted_cc_define_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_formatted_cc_define_with_non_existent_cc_define_name_raises_error)
 get_formatted_cc_define(some_define unused)
endfunction()
define_test(
 get_formatted_cc_define_with_non_existent_cc_define_name_raises_error
 REGEX "The cc define 'some_define' does not exist!"
 EXPECT_FAIL
)

function(get_formatted_cc_define_yields_the_expected_value)
 #Set up test
 set(compiler_id_var "some_compiler")
 detect_compiler(
  unused
  COMPILER_ID compiler_id_var
  SUPPORTED_COMPILERS some_compiler
 )

 function(formatter_5 ARG VALUE DEST)
  set("${DEST}" "-D${ARG}=${VALUE}" PARENT_SCOPE)
 endfunction()
 add_compiler_define_formatter(some_compiler formatter_5)

 add_cc_define(some_define some_value)

 #Get formatted cc define
 get_formatted_cc_define(some_define value)
 assert_equals("-Dsome_define=some_value" "${value}")
endfunction()
define_test(get_formatted_cc_define_yields_the_expected_value)

##TODO `add_cc_or_ld_argument` tests
function(add_cc_or_ld_argument_with_empty_type_raises_error)
 add_cc_or_ld_argument("" "" "")
endfunction()
define_test(
 add_cc_or_ld_argument_with_empty_type_raises_error
 REGEX "The <TYPE> argument must not be empty!"
 EXPECT_FAIL
)

function(add_cc_or_ld_argument_with_empty_compiler_id_raises_error)
 add_cc_or_ld_argument(COMPILER "" "")
endfunction()
define_test(
 add_cc_or_ld_argument_with_empty_compiler_id_raises_error
 REGEX "The <COMPILER> argument must not be empty!"
 EXPECT_FAIL
)

function(add_cc_or_ld_argument_with_emtpy_flag_raises_error)
 add_cc_or_ld_argument(LINKER some_compiler_id "")
endfunction()
define_test(
 add_cc_or_ld_argument_with_emtpy_flag_raises_error
 REGEX "The <FLAG> argument must not be empty!"
 EXPECT_FAIL
)

function(add_cc_or_ld_argument_with_invalid_type_raises_error)
 add_cc_or_ld_argument(INVALID_TYPE some_compiler_id abc)
endfunction()
define_test(
 add_cc_or_ld_argument_with_invalid_type_raises_error
 REGEX
  "The type 'INVALID_TYPE' is not a valid option! Must be one of: "
  "\[COMPILER, LINKER\]"
 EXPECT_FAIL
)

function(add_cc_or_ld_argument_with_invalid_compiler_id_variable_raises_error)
 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_cc_or_ld_argument(COMPILER some_unsupported_compiler asd)
endfunction()
define_test(
 add_cc_or_ld_argument_with_invalid_compiler_id_variable_raises_error
 REGEX "Compiler 'some_unsupported_compiler' is not supported!"
 EXPECT_FAIL
)

function(
 add_cc_or_ld_argument_with_invalid_compiler_when_allow_unsupported_is_specified_does_not_yield_error
)
 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
  ALLOW_UNSUPPORTED
 )

 add_cc_or_ld_argument(COMPILER some_unsupported_compiler asd)
endfunction()
define_test(
 add_cc_or_ld_argument_with_invalid_compiler_when_allow_unsupported_is_specified_does_not_yield_error
)

function(add_cc_or_ld_argument_sets_expected_variable_for_compiler_argument)
 get_project_compiler_details_prefix(prefix)

 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_cc_or_ld_argument(COMPILER stub "-Dsome=value")
 add_cc_or_ld_argument(COMPILER stub "--hello_world")

 set(compiler_arg_list_var "${prefix}_stub_COMPILER_ARGS")
 assert_equals("-Dsome=value;--hello_world" "${${compiler_arg_list_var}}")
endfunction()
define_test(add_cc_or_ld_argument_sets_expected_variable_for_compiler_argument)

function(add_cc_or_ld_argument_sets_expected_variable_for_linker_argument)
 get_project_compiler_details_prefix(prefix)

 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_cc_or_ld_argument(LINKER stub "--example=123")
 add_cc_or_ld_argument(LINKER stub "-x")

 set(linker_arg_list_var "${prefix}_stub_LINKER_ARGS")
 assert_equals("--example=123;-x" "${${linker_arg_list_var}}")
endfunction()
define_test(add_cc_or_ld_argument_sets_expected_variable_for_linker_argument)

##`get_cc_and_ld_arguments` tests
function(get_cc_or_ld_arguments_with_empty_type_raises_error)
 get_cc_or_ld_arguments("" "" "")
endfunction()
define_test(
 get_cc_or_ld_arguments_with_empty_type_raises_error
 REGEX "The <TYPE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_cc_or_ld_arguments_with_empty_compiler_raises_error)
 get_cc_or_ld_arguments(LINKER "" "")
endfunction()
define_test(
 get_cc_or_ld_arguments_with_empty_compiler_raises_error
 REGEX "The <COMPILER> argument must not be empty!"
 EXPECT_FAIL
)

function(get_cc_or_ld_arguments_with_empty_destination_variable_raises_error)
 get_cc_or_ld_arguments(COMPILER example "")
endfunction()
define_test(
 get_cc_or_ld_arguments_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(get_cc_or_ld_arguments_with_invalid_type_raises_error)
 get_cc_or_ld_arguments(INVALID none unused)
endfunction()
define_test(
 get_cc_or_ld_arguments_with_invalid_type_raises_error
 REGEX
  "The type 'INVALID' is not a valid option! Must be one of: "
  "\[COMPILER, LINKER\]."
 EXPECT_FAIL
)

function(get_cc_or_ld_arguments_with_compiler_type_yields_expected_value)
 set(stub stub)

 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_cc_or_ld_argument(COMPILER stub "-x")
 add_cc_or_ld_argument(COMPILER stub "--y")
 add_cc_or_ld_argument(COMPILER stub "--z=a")

 get_cc_or_ld_arguments(COMPILER stub value)
 assert_equals("-x;--y;--z=a" "${value}")

endfunction()
define_test(get_cc_or_ld_arguments_with_compiler_type_yields_expected_value)

function(get_cc_or_ld_arguments_with_linker_type_yields_expected_value)
 set(stub stub)

 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_cc_or_ld_argument(LINKER stub "-a")
 add_cc_or_ld_argument(LINKER stub "-b")

 get_cc_or_ld_arguments(LINKER stub value)
 assert_equals("-a;-b" "${value}")
endfunction()
define_test(get_cc_or_ld_arguments_with_linker_type_yields_expected_value)

#`generate_inline_namespace` tests
function(
 generate_inline_namespace_with_empty_destination_variable_raises_error
)
 generate_inline_namespace("")
endfunction()
define_test(
 generate_inline_namespace_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(
 generate_inline_namespace_with_no_prior_project_invocation_raises_error
)
 generate_inline_namespace(unused)
endfunction()
define_test(
 generate_inline_namespace_with_no_prior_project_invocation_raises_error
 REGEX
  "Cannot generate an inline namespace string without a prior `project\\(\\)` "
  "invocation, with a `VERSION` argument!"
 EXPECT_FAIL
)

function(
 generate_inline_namespace_with_prior_project_invocation_missing_version_argument_raises_error
)
 set(CMAKE_PROJECT_NAME example)
 generate_inline_namespace(unused)
endfunction()
define_test(
 generate_inline_namespace_with_prior_project_invocation_missing_version_argument_raises_error
 REGEX
  "Cannot generate an inline namespace string without a prior `project\\(\\)` "
  "invocation, with a `VERSION` argument!"
 EXPECT_FAIL
)

function(generate_inline_namespace_yields_expected_value)
 set(CMAKE_PROJECT_NAME example)
 set(CMAKE_PROJECT_VERSION "1.0.0")
 generate_inline_namespace(result)
 assert_equals("example_1_0_0" "${result}")
endfunction()
define_test(generate_inline_namespace_yields_expected_value)

##`generate_guard_symbol` tests
function(generate_guard_symbol_with_empty_destination_variable_raises_error)
 generate_guard_symbol("")
endfunction()
define_test(
 generate_guard_symbol_with_empty_destination_variable_raises_error
 REGEX "The <DESTINATION_VARIABLE> argument must not be empty!"
 EXPECT_FAIL
)

function(generate_guard_symbol_with_no_abi_breaking_flags_raises_error)
 generate_guard_symbol(unused)
endfunction()
define_test(
 generate_guard_symbol_with_no_abi_breaking_flags_raises_error
 REGEX "The 'ABI_BREAKING_FLAGS'... argument must not be empty!"
 EXPECT_FAIL
)

function(generate_guard_symbol_with_invalid_abi_breaking_flags_raises_error)
 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 generate_guard_symbol(
  unused
  ABI_BREAKING_FLAGS a b c
 )
endfunction()
define_test(
 generate_guard_symbol_with_invalid_abi_breaking_flags_raises_error
 REGEX
  "The build flag 'a' does not exist!"
  EXPECT_FAIL
)

function(
 generate_guard_symbol_with_abi_breaking_flag_with_no_value_raises_error
)
 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )
 add_build_flag(
  a
  VALUE "abc"
 )
 add_build_flag(b)
 add_build_flag(
  c
  VALUE "def"
 )

 generate_guard_symbol(
  unused
  ABI_BREAKING_FLAGS a b c
 )
endfunction()
define_test(
 generate_guard_symbol_with_abi_breaking_flag_with_no_value_raises_error
 REGEX
  "The flag 'b' does not have a value! All flags must have a value to be used "
  "in a guard symbol!"
 EXPECT_FAIL
)

function(generate_guard_symbol_yields_expected_value)
 #[[
  Needs to be set before any other command because running setting this
  variable clears all set variables, possibly for subproject compatibility
  reasons?
 ]]
 set(CMAKE_PROJECT_NAME example)

 set(stub stub)
 detect_compiler(
  unused
  COMPILER_ID stub
  SUPPORTED_COMPILERS stub
 )

 add_build_flag(
  flag1
  VALUE "abc"
 )
 add_build_flag(
  flag2
  VALUE "def"
 )
 add_build_flag(
  flag3
  VALUE "ghi"
 )

 generate_guard_symbol(
  guard_symbol
  ABI_BREAKING_FLAGS flag1 flag2 flag3
 )

 string(
  APPEND expected_guard_symbol
  "if_you_are_seeing_this_symbol_in_a_linker_related_error_then_you_are_"
  "trying_to_link_against_another_binary_with_a_differently_configured_build_"
  "of_example__this_is_not_allowed_as_some_build_flags_may_break_abi_"
  "compatibility_between_builds_with_different_configurations__your_"
  "configuration_is_as_follows"
  "____flag1__abc"
  "____flag2__def"
  "____flag3__ghi"
 )
 assert_equals(
  "${expected_guard_symbol}"
  "${guard_symbol}"
 )
endfunction()
define_test(generate_guard_symbol_yields_expected_value)
