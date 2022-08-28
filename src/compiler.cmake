cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/flags.cmake)

#[[TODO:
 - Set up global cache variable for prefixing all definitions in this library
 - Add help messages to all functions
 - Ensure that all relevant functions check that `detect_compiler` was invoked
   beforehand
 - Custom linker support
 - Make all DESTINATION_VARIABLE arguments the first argument
]]

#[[
 Generates a unique prefix for storing infromation related to compiler flags,
 source flags, linker flags, etc...
]]
assert_name_unique(
 get_project_compiler_details_prefix
 COMMAND
 "Name collision: Function 'get_project_compiler_details_prefix' is already "
 "defined elsewhere!"
)
function(get_project_compiler_details_prefix gpcdp_DESTINATION_VARIABLE)
 string(
  APPEND gpcdp_HELP_MESSAGE
  "'get_project_compiler_details_prefix' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
 )

 #Validate destination variable
 is_empty(gpcdp_DESTINATION_VARIABLE_EMPTY "${gpcdp_DESTINATION_VARIABLE}")
 if(gpcdp_DESTINATION_VARIABLE_EMPTY)
  message("${gpcdp_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_project_compiler_details_prefix: The <DESTINATION_VARIABLE> argument "
   "must not be empty!"
  )
 endif()
 unset(gpcdp_DESTINATION_VARIABLE_EMPTY)

 #Get project prefix
 get_project_prefix("${gpcdp_DESTINATION_VARIABLE}")

 #Create unique variable name for storing compiler related information
 string(APPEND "${gpcdp_DESTINATION_VARIABLE}" "_COMPILER_DETAILS")

 #Set destination variable in parent scope
 set(
  "${gpcdp_DESTINATION_VARIABLE}" "${${gpcdp_DESTINATION_VARIABLE}}"
  PARENT_SCOPE
 )
endfunction()

#[[
 Detect the compiler and validate it against a user-supplied list of supported
 compilers. Stores list of supported compilers for the current project, as well
 as the detected compiler, for later use.
]]
assert_name_unique(
 detect_compiler
 COMMAND
 "Name collision: Function 'detect_compiler' is already defined elsewhere!"
)
function(detect_compiler dc_DESTINATION_VARIABLE)
 #Help message utility function
 string(
  APPEND dc_HELP_MESSAGE
  "'detect_compiler' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE> - The name of the variable to "
  "place the detected compiler ID"
  "\n - (REQUIRED) 'COMPILER_ID' - CMake compiler ID variable to track; ie. "
  "CMAKE_CXX_COMPILER_ID. For more information, see: "
  "https://cmake.org/cmake/help/v3.19/variable/CMAKE_LANG_COMPILER_ID.html"
  "\n - (REQUIRED) 'SUPPORTED_COMPILERS'...: - Space separated list of "
  "compiler IDs supported by your project"
  "\n\nExamples:"
  "\n detect_compiler("
  "\n  MY_DETECTED_COMPILER_ID_RESULT"
  "\n  COMPILER_ID CMAKE_C_COMPILER_ID"
  "\n  SUPPORTED_COMPILERS Clang GNU Intel MSVC"
  "\n )"
  "\n message(\"DETECTED COMPILER: \${MY_DETECTED_COMPILER_ID_RESULT}\")"
  "\n ---"
  "\n detect_compiler("
  "\n  MY_DETECTED_COMPILER_ID_RESULT"
  "\n  ALLOW_UNSUPPORTED #do not emit an error if no suitable compiler is found"
  "\n  COMPILER_ID CMAKE_C_COMPILER_ID"
  "\n  SUPPORTED_COMPILERS Clang GNU Intel MSVC"
  "\n )"
  "\n message(\"DETECTED COMPILER: \${MY_DETECTED_COMPILER_ID_RESULT}\")"
 )

 #Validate detected compiler destination variable name
 is_empty(dc_DESTINATION_VARIABLE_EMPTY "${dc_DESTINATION_VARIABLE}")
 if(dc_DESTINATION_VARIABLE_EMPTY)
  message("${dc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "detect_compiler: The <DESTINATION_VARIABLE> argument must not be empty!"
  )
 endif()
 unset(dc_DESTINATION_VARIABLE_EMPTY)

 #Parse arguments
 cmake_parse_arguments(
  dc
  "ALLOW_UNSUPPORTED"
  "COMPILER_ID"
  "SUPPORTED_COMPILERS"
  ${ARGN}
 )

 #Validate `dc_COMPILER`
 if(NOT DEFINED dc_COMPILER_ID)
  message("${dc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "detect_compiler: The 'COMPILER_ID' argument must be provided!"
  )
 endif()

 if(NOT DEFINED "${dc_COMPILER_ID}")
  message("${dc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "detect_compiler: The provided compiler ID variable, '${dc_COMPILER_ID}', "
   "is not set! Are you sure that you provided the correct compiler ID "
   "variable?"
  )
 endif()

 #Validate `dc_SUPPORTED_COMPILERS`
 if(NOT DEFINED dc_SUPPORTED_COMPILERS)
  message("${dc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "detect_compiler: At least one compiler must be provided for the "
   "'SUPPORTED_COMPILERS' argument! See "
   "https://cmake.org/cmake/help/v3.19/variable/CMAKE_LANG_COMPILER_ID.html "
   "for more information."
  )
 endif()

 #Determine whether `${dc_COMPILER_ID}` is in the list of supported compilers
 set(dc_SUPPORTED_COMPILER_DETECTED FALSE)
 foreach(COMPILER ${dc_SUPPORTED_COMPILERS})
  #If supported compiler is found, set destination variable on parent scope
  if("${COMPILER}" STREQUAL "${${dc_COMPILER_ID}}")
   set(dc_SUPPORTED_COMPILER_DETECTED TRUE)
   set("${dc_DESTINATION_VARIABLE}" "${${dc_COMPILER_ID}}" PARENT_SCOPE)
   break()
  endif()
 endforeach()

 #Get compiler details variable
 get_project_compiler_details_prefix(dc_COMPILER_DETAILS_PREFIX)

 #[[
  Set the destination variable in the parent scope if `ALLOW_UNSUPPORTED` is
  specified
 ]]
 if(dc_ALLOW_UNSUPPORTED)
  set("${dc_DESTINATION_VARIABLE}" "${${dc_COMPILER_ID}}" PARENT_SCOPE)
 endif()

 #Store supported compiler list, flags and other information
 set(
  "${dc_COMPILER_DETAILS_PREFIX}_ALLOW_UNSUPPORTED" "${dc_ALLOW_UNSUPPORTED}"
  PARENT_SCOPE
 )
 set(
  "${dc_COMPILER_DETAILS_PREFIX}_DETECTED_COMPILER_ID"
  "${${dc_COMPILER_ID}}"
  PARENT_SCOPE
 )
 set(
  "${dc_COMPILER_DETAILS_PREFIX}_SUPPORTED_COMPILERS"
  "${dc_SUPPORTED_COMPILERS}"
  PARENT_SCOPE
 )

 #Emit diagnostic if compiler is not supported
 if(NOT dc_SUPPORTED_COMPILER_DETECTED)
  #Set up diagnostic level
  if(dc_ALLOW_UNSUPPORTED)
   set(dc_DIAGNOSTIC_LEVEL WARNING)
  else()
   set(dc_DIAGNOSTIC_LEVEL FATAL_ERROR)
  endif()

  #Assemble pretty compiler list
  foreach(COMPILER ${dc_SUPPORTED_COMPILERS})
   string(APPEND dc_PRETTY_COMPILER_STR "\n - ${COMPILER}")
  endforeach()

  #Emit diagnostic
  message(
   ${dc_DIAGNOSTIC_LEVEL}
   "detect_compiler: '${${dc_COMPILER_ID}}' is an unsupported compiler. "
   "Supported compilers include: ${dc_PRETTY_COMPILER_STR}"
  )
  unset(dc_PRETTY_COMPILER_STR)
  unset(dc_DIAGNOSTIC_LEVEL)
 endif()
 unset(dc_SUPPORTED_COMPILER_DETECTED)
endfunction()

#[[
 Retrieves the detected compiler ID and places it in the destination variable,
 in the parent scope.

 Note: Must invoke `detect_compiler` before attempting to retreive the detected
 compiler ID.
]]
assert_name_unique(
 get_detected_compiler
 COMMAND
 "Name collision: Function 'get_detected_compiler' is already defined "
 "elsewhere!"
)
function(get_detected_compiler gdc_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND gdc_HELP_MESSAGE
  "'get_detected_compiler' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the variable to place "
  "the detected compiler ID in, in the parent scope"
  "\n\nExample:"
  "\n detect_compiler("
  "\n  detected_compiler_id"
  "\n  COMPILER_ID CMAKE_C_COMPILER_ID"
  "\n  SUPPORTED_COMPILERS GNU"
  "\n )"
  "\n get_detected_compiler(retrieved_compiler_id)"
  "\n #Prints \"GNU -- GNU\""
  "\n message(\"\${detected_compiler_id} -- \${retrieved_compiler_id} \")"
 )

 #Validate destination variable name
 is_empty(gdc_DESTINATION_VARIABLE_EMPTY "${gdc_DESTINATION_VARIABLE}")
 if(gdc_DESTINATION_VARIABLE_EMPTY)
  message("${gdc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_detected_compiler: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(gdc_DESTINATION_VARIABLE_EMPTY)

 #Compiler details prefix
 get_project_compiler_details_prefix(gdc_COMPILER_DETAILS_PREFIX)

 #Ensure `detect_compiler` was invoked before
 set(gdc_COMPILER_ID_VAR "${gdc_COMPILER_DETAILS_PREFIX}_DETECTED_COMPILER_ID")
 if(NOT DEFINED "${gdc_COMPILER_ID_VAR}")
  message("${gdc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_detected_compiler: The detected compiler ID is not set! You must call "
   "`detect_compiler` before attempting to retrieve the detected compiler ID!"
  )
 endif()

 #Set destination variable in parent scope
 set("${gdc_DESTINATION_VARIABLE}" "${${gdc_COMPILER_ID_VAR}}" PARENT_SCOPE)
endfunction()

#[[
 Retrieves the list of supported compilers and places it in the destination
 variable
]]
assert_name_unique(
 get_supported_compilers
 COMMAND
 "Name collision: Function 'get_supported_compilers' is already defined "
 "elsewhere!"
)
function(get_supported_compilers gsc_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND gsc_HELP_MESSAGE
  "'get_supported_compilers' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the variable to place "
  "the result in"
  "\n\nExample:"
  "\n detect_compiler("
  "\n  MY_DETECTED_COMPILER"
  "\n  COMPILER_ID CMAKE_CXX_COMPILER_ID"
  "\n  SUPPORTED_COMPILERS A B C D E"
  "\n )"
  "\n get_supported_compilers(MY_SUPPORTED_COMPILERS)"
  "\n #prints \"A;B;C;D;E\""
  "\n message(\"SUPPORTED COMPILERS: \${MY_SUPPORTED_COMPILERS}\")"
 )

 #Validate destination variable name
 is_empty(gsc_DESTINATION_VARIABLE_EMPTY "${gsc_DESTINATION_VARIABLE}")
 if(gsc_DESTINATION_VARIABLE_EMPTY)
  message("${gsc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_supported_compilers: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(gsc_DESTINATION_VARIABLE_EMPTY)

 #Get details prefix
 get_project_compiler_details_prefix(gsc_COMPILER_DETAILS_PREFIX)

 #Set supported compilers on destination variable in parent scope
 set(
  "${gsc_DESTINATION_VARIABLE}"
  "${${gsc_COMPILER_DETAILS_PREFIX}_SUPPORTED_COMPILERS}"
  PARENT_SCOPE
 )
endfunction()

#Checks whether a given compiler ID is supported
assert_name_unique(
 is_compiler_supported
 COMMAND
 "Name collision: Function 'is_compiler_supported' is already defined "
 "elsewhere!"
)
function(is_compiler_supported ics_DESTINATION_VARIABLE ics_COMPILER)
 #Help message
 string(
  APPEND ics_HELP_MESSAGE
  "'is_compiler_supported' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable, to place the result in"
  "\n - (REQUIRED) <COMPILER_ID>: The name of the compiler to check"
  "\n\nExample:"
  "\n detect_compiler("
  "\n  MY_DETECTED_COMPILER_ID_RESULT"
  "\n  COMPILER_ID CMAKE_C_COMPILER_ID"
  "\n  SUPPORTED_COMPILERS GNU MSVC"
  "\n )"
  "\n is_compiler_supported(GNU GNU_SUPPORTED)"
  "\n message(\${GNU_SUPPORTED}) #prints 'TRUE'"
  "\n is_compiler_supported(Clang Clang_SUPPORTED)"
  "\n message(\${Clang_SUPPORTED}) #prints 'FALSE'"
 )

 #Validate destination variable name
 is_empty(ics_DESTINATION_VARIABLE_EMPTY "${ics_DESTINATION_VARIABLE}")
 if(ics_DESTINATION_VARIABLE_EMPTY)
  message("${ics_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "is_compiler_supported: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(ics_DESTINATION_VARIABLE_EMPTY)

 #Validate compiler name
 is_empty(ics_COMPILER_EMPTY "${ics_COMPILER}")
 if(ics_COMPILER_EMPTY)
  message("${ics_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "is_compiler_supported: The <COMPILER> argument must not be empty!"
  )
 endif()
 unset(ics_COMPILER_EMPTY)

 #Get compiler details prefix
 get_project_compiler_details_prefix(ics_COMPILER_DETAILS_PREFIX)

 #Ensure `detect_compiler` was invoked before
 set(ics_COMPILER_ID_VAR "${ics_COMPILER_DETAILS_PREFIX}_DETECTED_COMPILER_ID")
 if(NOT DEFINED "${ics_COMPILER_ID_VAR}")
  message("${ics_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "is_compiler_supported: The detected compiler ID is not set! You must call "
   "`detect_compiler` before checking for supported compilers!"
  )
 endif()

 #Check if compiler is supported
 set(
  ics_SUPPORTED_COMPILER_LIST_VARIABLE
  "${ics_COMPILER_DETAILS_PREFIX}_SUPPORTED_COMPILERS"
 )
 set(
  ics_ALLOW_UNSUPPORTED_COMPILER
  "${ics_COMPILER_DETAILS_PREFIX}_ALLOW_UNSUPPORTED"
 )
 if(ics_COMPILER IN_LIST "${ics_SUPPORTED_COMPILER_LIST_VARIABLE}")
  set(ics_COMPILER_SUPPORTED TRUE)
 else()
  set(ics_COMPILER_SUPPORTED FALSE)
 endif()
 unset(ics_SUPPORTED_COMPILER_LIST_VARIABLE)

 if(${${ics_ALLOW_UNSUPPORTED_COMPILER}})
  #[[
   If `ALLOW_UNSUPPORTED` was specified when detecting the compiler, always
   yield true.
  ]]
  set("${ics_DESTINATION_VARIABLE}" TRUE PARENT_SCOPE)
 else()
  #Set result on destination variable in parent scope
  set("${ics_DESTINATION_VARIABLE}" "${ics_COMPILER_SUPPORTED}" PARENT_SCOPE)
 endif()
 unset(ics_COMPILER_SUPPORTED)
endfunction()

#Adds a compiler-specific formatter for defines and source flags
assert_name_unique(
 add_compiler_define_formatter
 COMMAND
 "Name collision: Function 'add_compiler_define_formatter' is already defined "
 "elsewhere!"
)
function(add_compiler_define_formatter acdf_COMPILER acdf_FORMATTER_FUNCTION)
 #Help message
 string(
  APPEND acdf_HELP_MESSAGE
  "'add_compiler_define_formatter' takes the following arguments:"
  "\n - (REQUIRED) <COMPILER>: The name of the compiler to specify a define "
  "formatter for"
  "\n - (REQUIRED) <FORMATTER_FUNCTION>: The name of the formatter function. "
  "The function prototype should be "
  "`function(my_formatter ARG VALUE DESTINATION_VARIABLE)`"
  "\n\nExample:"
  "\n function(some_compiler_formatter ARG VALUE DEST)"
  "\n  set(\"\${DEST}\" \"-D\${ARG}=\${VALUE}\" PARENT_SCOPE)"
  "\n endfunction()"
  "\n"
  "\n add_compiler_define_formatter(some_compiler some_compiler_formatter)"
 )

 #Validate compiler name
 is_empty(acdf_COMPILER_EMPTY "${acdf_COMPILER}")
 if(acdf_COMPILER_EMPTY)
  message("${acdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define_formatter: The <COMPILER> argument must not be empty!"
  )
 endif()
 unset(acdf_COMPILER_EMPTY)

 #Validate formatter function name
 is_empty(acdf_FORMATTER_FUNCTION_EMPTY "${acdf_FORMATTER_FUNCTION}")
 if(acdf_FORMATTER_FUNCTION_EMPTY)
  message("${acdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define_formatter: The <FORMATTER_FUNCTION> argument must not "
   "be empty!"
  )
 endif()
 unset(acdf_FORMATTER_FUNCTION_EMPTY)

 if(NOT COMMAND "${acdf_FORMATTER_FUNCTION}")
  message("${acdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define_formatter: The formatter function "
   "'${acdf_FORMATTER_FUNCTION}' is not defined!"
  )
 endif()

 #Compiler details prefix
 get_project_compiler_details_prefix(acdf_COMPILER_DETAILS_PREFIX)

 #Ensure define formatter does not already exist
 set(
  acdf_DEFINE_FORMATTER_LIST_VAR
  "${acdf_COMPILER_DETAILS_PREFIX}_FORMATTERS"
 )
 set(
  acdf_DEFINE_FORMATTER_NAME_VAR
  "${acdf_COMPILER_DETAILS_PREFIX}_${acdf_COMPILER}_FORMATTER"
 )

 if("${acdf_COMPILER}" IN_LIST "${acdf_DEFINE_FORMATTER_LIST_VAR}")
  message("${acdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define_formatter: The compiler '${acdf_COMPILER}' already "
   "has a define formatter specified! (formatter: "
   "'${${acdf_DEFINE_FORMATTER_NAME_VAR}}')"
  )
 endif()

 #Add compiler define formatter
 list(
  APPEND ${acdf_DEFINE_FORMATTER_LIST_VAR}
  "${acdf_COMPILER}"
 )
 set(
  "${acdf_DEFINE_FORMATTER_LIST_VAR}"
  "${${acdf_DEFINE_FORMATTER_LIST_VAR}}"
  PARENT_SCOPE
 )

 set(
  "${acdf_DEFINE_FORMATTER_NAME_VAR}"
  "${acdf_FORMATTER_FUNCTION}"
  PARENT_SCOPE
 )
endfunction()

#[[
 Gets the name of the compiler-specific define formatter function and places it
 in the destination variable
]]
assert_name_unique(
 get_compiler_define_formatter
 COMMAND
 "Name collision: Function 'get_compiler_define_formatter' is already defined "
 "elsewhere!"
)
function(get_compiler_define_formatter gcdf_COMPILER gcdf_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND gcdf_HELP_MESSAGE
  "'get_compiler_define_formatter' takes the following arguments:"
  "\n - (REQUIRED) <COMPILER>: The name of the compiler"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the variable to place "
  "the compiler define formatter function name in, in the parent scope"
  "\n\nExample:"
  "\n add_compiler_define_formatter(some_compiler some_compiler_formatter)"
  "\n get_compiler_define_formatter(some_compiler the_formatter_name)"
  "\n message(\"\${the_formatter_name}\") #prints 'some_compiler_formatter'"
 )

 #Validate compiler name
 is_empty(gcdf_COMPILER_EMPTY "${gcdf_COMPILER}")
 if(gcdf_COMPILER_EMPTY)
  message("${gcdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_define_formatter: The <COMPILER> argument must not be empty!"
  )
 endif()
 unset(gcdf_COMPILER_EMPTY)

 #Validate destination variable name
 is_empty(gcdf_DESTINATION_VARIABLE_EMPTY "${gcdf_DESTINATION_VARIABLE}")
 if(gcdf_DESTINATION_VARIABLE_EMPTY)
  message("${gcdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_define_formatter: The <DESTINATION_VARIABLE> argument must "
   "not be empty!"
  )
 endif()
 unset(gcdf_DESTINATION_VARIABLE_EMPTY)

 #Compiler details prefix
 get_project_compiler_details_prefix(gcdf_COMPILER_DETAILS_PREFIX)

 set(
  gcdf_DEFINE_FORMATTER_NAME_VAR
  "${gcdf_COMPILER_DETAILS_PREFIX}_${gcdf_COMPILER}_FORMATTER"
 )
 set(
  "${gcdf_DESTINATION_VARIABLE}"
  "${${gcdf_DEFINE_FORMATTER_NAME_VAR}}"
  PARENT_SCOPE
 )
endfunction()

#[[
 Removes the association between a compiler and its define formatter function.
 Useful for users that may want to override the default formatters.
]]
assert_name_unique(
 remove_compiler_define_formatter
 COMMAND
 "Name collision: Function 'remove_compiler_define_formatter' is already "
 "defined elsewhere!"
)
function(remove_compiler_define_formatter rcdf_COMPILER)
 #Help message
 string(
  APPEND rcdf_HELP_MESSAGE
  "'remove_compiler_define_formatter' takes the following arguments:"
  "\n - (REQUIRED) <COMPILER>: The name of the compiler to remove the define "
  "formatter for"
  "\n\nExample:"
  "\n remove_compiler_define_formatter(some_compiler)"
  "\n get_compiler_define_formatter(some_compiler the_formatter_name)"
  "\n message(\"\${the_formatter_name}\") #prints nothing"
 )

 #Validate compiler name
 is_empty(rcdf_COMPILER_EMPTY "${rcdf_COMPILER}")
 if(rcdf_COMPILER_EMPTY)
  message("${rcdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "remove_compiler_define_formatter: The <COMPILER> argument must not be "
   "empty!"
  )
 endif()
 unset(rcdf_COMPILER_EMPTY)

 #Compiler details prefix
 get_project_compiler_details_prefix(rcdf_COMPILER_DETAILS_PREFIX)

 set(rcdf_FORMATTER_LIST_VAR "${rcdf_COMPILER_DETAILS_PREFIX}_FORMATTERS")
 set(
  rcdf_FORMATTER_NAME_VAR
  "${rcdf_COMPILER_DETAILS_PREFIX}_${rcdf_COMPILER}_FORMATTER"
 )

 #Remove compiler from list of compilers with associated formatters
 list(REMOVE_ITEM "${rcdf_FORMATTER_LIST_VAR}" "${rcdf_COMPILER}")
 set("${rcdf_FORMATTER_LIST_VAR}" "${${rcdf_FORMATTER_LIST_VAR}}" PARENT_SCOPE)

 #Remove associated compiler formatter
 unset("${rcdf_FORMATTER_NAME_VAR}" PARENT_SCOPE)
endfunction()

#Add compiler-specific source define for c-preprocessor
assert_name_unique(
 add_compiler_define
 COMMAND
 "Name collision: Function 'add_compiler_define' is already defined elsewhere!"
)
function(add_compiler_define acd_ARG acd_VALUE)
 #Help message
 string(
  APPEND acd_HELP_MESSAGE
  "'add_compiler_define' takes the following arguments:"
  "\n - (REQUIRED) <DEFINE_NAME>: The name of the compiler define"
  "\n - (REQUIRED) <VALUE>: The value of the compiler define"
  "\n\nExample:"
  "\n detect_compiler("
  "\n  unused"
  "\n  COMPILER_ID CMAKE_C_CMPILER_ID"
  "\n  SUPPORTED_COMPILERS Clang"
  "\n )"
  "\n add_compiler_define(\"FIRST\" \"123\")"
  "\n add_compiler_define(\"SECOND\" \"456\")"
  "\n "
  "\n #Get the list of compiler defines"
  "\n get_compiler_defines(cc_defines)"
  "\n message(\"\${cc_defines}\") #Prints \"FIRST;SECOND\""
  "\n "
  "\n #Get the value for a given cc define"
  "\n get_compiler_define_value(FIRST FIRST_value)"
  "\n message(\"\${FIRST_value}\") #Prints \"123\""
  "\n "
  "\n #Get the formatted string that will be passed to the compiler"
  "\n get_formatted_compiler_define(SECOND SECOND_formatted)"
  "\n message(\"\${SECOND_formatted}\") #Prints '-DSECOND=456'"
 )

 #Validate compiler define argument name
 is_empty(acd_ARG_EMPTY "${acd_ARG}")
 if(acd_ARG_EMPTY)
  message("${acd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define: The <DEFINE_NAME> argument must not be empty!"
  )
 endif()
 unset(acd_ARG_EMPTY)

 #Compiler details prefix
 get_project_compiler_details_prefix(acd_COMPILER_DETAILS_PREFIX)

 set(acd_DEFINE_LIST_VAR "${acd_COMPILER_DETAILS_PREFIX}_CC_DEFINES")
 set(
  acd_DEFINE_VALUE_VAR
  "${acd_COMPILER_DETAILS_PREFIX}_CC_DEFINE_${acd_ARG}"
 )
 set(
  acd_DEFINE_FORMATTED_VAR
  "${acd_COMPILER_DETAILS_PREFIX}_CC_DEFINE_${acd_ARG}_FORMATTED"
 )

 #Format argument for the detected compiler
 get_detected_compiler(acd_DETECTED_COMPILER_ID)
 get_compiler_define_formatter(
  "${acd_DETECTED_COMPILER_ID}"
  acd_COMPILER_DEFINE_FORMATTER
 )
 is_empty(
  acd_COMPILER_DEFINE_FORMATTER_EMPTY
  "${acd_COMPILER_DEFINE_FORMATTER}"
 )
 if(acd_COMPILER_DEFINE_FORMATTER_EMPTY)
  message("${acd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define: Missing formatter for compiler "
   "'${acd_DETECTED_COMPILER_ID}'! You must specify a define formatter using "
   "`add_compiler_define_formatter()` for the compiler "
   "'${acd_DETECTED_COMPILER_ID}'!"
  )
 endif()
 unset(acd_COMPILER_DEFINE_FORMATTER_EMPTY)

 cmake_language(
  CALL "${acd_COMPILER_DEFINE_FORMATTER}"
  "${acd_ARG}"
  "${acd_VALUE}"
  acd_FORMATTED_DEFINE
 )
 is_empty(acd_FORMATTED_DEFINE_EMPTY "${acd_FORMATTED_DEFINE}")
 if(acd_FORMATTED_DEFINE_EMPTY)
  message("${acd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_compiler_define: The define formatter for the compiler "
   "'${acd_DETECTED_COMPILER_ID}' did not return a value! (function: "
   "'${acd_COMPILER_DEFINE_FORMATTER}')"
  )
 endif()
 unset(acd_FORMATTED_DEFINE_EMPTY)

 #Add arg to list of compiler defines
 list(
  APPEND "${acd_DEFINE_LIST_VAR}"
  "${acd_ARG}"
 )
 set("${acd_DEFINE_LIST_VAR}" "${${acd_DEFINE_LIST_VAR}}" PARENT_SCOPE)

 #Associate value with compiler define
 set("${acd_DEFINE_VALUE_VAR}" "${acd_VALUE}" PARENT_SCOPE)

 #Associate formatted argument with compiler define
 set("${acd_DEFINE_FORMATTED_VAR}" "${acd_FORMATTED_DEFINE}" PARENT_SCOPE)
endfunction()

#[[
 Retrieves the list of compiler defines and places it in the destination
 variable, in the parent scope
]]
assert_name_unique(
 get_compiler_defines
 COMMAND
 "Name collision: Function 'get_compiler_defines' is already defined elsewhere!"
)
function(get_compiler_defines gcd_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND gcd_HELP_MESSAGE
  "'get_compiler_defines' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
  "\n\nEaxmple:"
  "\n add_compiler_define(a a)"
  "\n add_compiler_define(b b)"
  "\n add_compiler_define(c c)"
  "\n get_compiler_defines(cc_defines)"
  "\n message(\"\${cc_defines}\") #Prints 'a;b;c'"
 )

 #Validate detsination variable name
 is_empty(gcd_DESTINATION_VARIABLE_EMPTY "${gcd_DESTINATION_VARIABLE}")
 if(gcd_DESTINATION_VARIABLE_EMPTY)
  message("${gcd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_defines: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(gcd_DESTINATION_VARIABLE_EMPTY)

 #Compiler details prefix
 get_project_compiler_details_prefix(gcd_COMPILER_DETAILS_PREFIX)

 set(gcd_CC_DEFINES_VAR "${gcd_COMPILER_DETAILS_PREFIX}_CC_DEFINES")
 set("${gcd_DESTINATION_VARIABLE}" "${${gcd_CC_DEFINES_VAR}}" PARENT_SCOPE)
endfunction()

#Retrieves the value for a given compiler define
assert_name_unique(
 get_compiler_define_value
 COMMAND
  "Name collision: The function 'get_compiler_define_value' is already defined "
  "elsewhere!"
)
function(get_compiler_define_value gcdv_ARG gcdv_DESTINATION_VARIABLE)
 #Compiler details prefix
 get_project_compiler_details_prefix(gcdv_COMPILER_DETAILS_PREFIX)

 #Help message
 string(
  APPEND gcdv_HELP_MESSAGE
  "'get_compiler_define_value' takes the following arguments:"
  "\n - (REQUIRED) <DEFINE>: The name of the compiler define"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
  "\n\nExample:"
  "\n add_compiler_define(some_define \"Hello world!\")"
  "\n get_compiler_define_value(some_define the_value)"
  "\n message(\"\${the_value}\") #Prints 'some_value'"
 )

 #Validate arg
 is_empty(gcdv_ARG_EMPTY "${gcdv_ARG}")
 if(gcdv_ARG_EMPTY)
  message("${gcdv_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_define_value: The <DEFINE> argument must not be empty!"
  )
 endif()
 unset(gcdv_ARG_EMPTY)

 #Validate destination variable
 is_empty(gcdv_DESTINATION_VARIABLE_EMPTY "${gcdv_DESTINATION_VARIABLE}")
 if(gcdv_DESTINATION_VARIABLE_EMPTY)
  message("${gcdv_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_define_value: The <DESTINATION_VARIABLE> argument must not "
   "be empty!"
  )
 endif()
 unset(gcdv_DESTINATION_VARIABLE_EMPTY)

 set(gcdv_CC_DEFINE_LIST_VAR "${gcdv_COMPILER_DETAILS_PREFIX}_CC_DEFINES")
 set(
  gcdv_CC_DEFINE_VAR
  "${gcdv_COMPILER_DETAILS_PREFIX}_CC_DEFINE_${gcdv_ARG}"
 )

 #Ensure define exists
 if(NOT "${gcdv_ARG}" IN_LIST "${gcdv_CC_DEFINE_LIST_VAR}")
  message("${gcdv_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_compiler_define_value: The compiler define '${gcdv_ARG}' does not "
   "exist!"
  )
 endif()

 #Set compiler define value on destination variable in parent scope
 set("${gcdv_DESTINATION_VARIABLE}" "${${gcdv_CC_DEFINE_VAR}}" PARENT_SCOPE)
endfunction()

#Retrieves the formatted string for a compiler define
assert_name_unique(
 get_formatted_compiler_define
 COMMAND
  "Name collision: The function 'get_formatted_compiler_define' is already "
  "defined elsewhere!"
)
function(get_formatted_compiler_define gfcd_ARG gfcd_DESTINATION_VARIABLE)
 #Compiler details prefix
 get_project_compiler_details_prefix(gfcd_COMPILER_DETAILS_PREFIX)

 #Help message
 string(
  APPEND gfcd_HELP_MESSAGE
  "'get_formatted_compiler_define' takes the following arguments:"
  "\n - (REQUIRED) <DEFINE>: The name of the compiler define"
  "\n - (REQURIED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
  "\n\nExample:"
  "\n #Setup"
  "\n set(compiler_id_var \"some_compiler\")"
  "\n detect_compiler("
  "\n  unused"
  "\n  COMPILER_ID compiler_id_var"
  "\n  SUPPORTED_COMPILERS some_compiler"
  "\n )"
  "\n "
  "\n function(the_formatter ARG VALUE DEST)"
  "\n  set(\"\${DEST}\" \"\-D\${ARG}=\${VALUE}\" PARENT_SCOPE)"
  "\n endfunction()"
  "\n add_compiler_define_formatter(some_compiler the_formatter)"
  "\n "
  "\n #Adding and retrieving formatted compiler defines"
  "\n add_compiler_define(some_define \"hello_world\")"
  "\n get_formatted_compiler_define(some_define value)"
  "\n message(\"\${value}\") #Prints '-Dsome_define=hello_world'"
 )

 #Validate arg
 is_empty(gfcd_ARG_EMPTY "${gfcd_ARG}")
 if(gfcd_ARG_EMPTY)
  message("${gfcd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_formatted_compiler_define: The <DEFINE> argument must not be empty!"
  )
 endif()
 unset(gfcd_ARG_EMPTY)

 #Validate destination variable
 is_empty(gfcd_DESTINATION_VARIABLE_EMPTY "${gfcd_DESTINATION_VARIABLE}")
 if(gfcd_DESTINATION_VARIABLE_EMPTY)
  message("${gfcd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_formatted_compiler_define: The <DESTINATION_VARIABLE> argument must "
   "not be empty!"
  )
 endif()
 unset(gfcd_DESTINATION_VARIABLE_EMPTY)

 set(gfcd_CC_DEFINE_LIST_VAR "${gfcd_COMPILER_DETAILS_PREFIX}_CC_DEFINES")
 set(
  gfcd_CC_DEFINE_FORMATTED_VAR
  "${gfcd_COMPILER_DETAILS_PREFIX}_CC_DEFINE_${gfcd_ARG}_FORMATTED"
 )

 #Ensure compiler define exists
 if(NOT "${gfcd_ARG}" IN_LIST "${gfcd_CC_DEFINE_LIST_VAR}")
  message("${gfcd_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_formatted_compiler_define: The compiler define '${gfcd_ARG}' does not "
   "exist!"
  )
 endif()

 #[[
  Set the formatted compiler define on the destination variable in the parent
  scope
 ]]
 set(
  "${gfcd_DESTINATION_VARIABLE}"
  "${${gfcd_CC_DEFINE_FORMATTED_VAR}}"
  PARENT_SCOPE
 )
endfunction()

#[[
 Adds a compiler or linker flag(s) for the given compiler.

 TODO:
  - Rename to `add_cc_or_ld_arguments`
  - Use list-of-lists; ie. append all unaccompanied arguments to
   `${prefix}_${compiler}_[COMPILER, LINKER]_ARGS` and then append that string
   to a global list, such as `${prefix}_${compiler}_[COMPILER]_ARGS_LISTS`
  - Remove `<COMPILER>` argument; will always be invoked in the context of the
    current compiler
]]
assert_name_unique(
 add_cc_or_ld_argument
 COMMAND
 "Name collision: Function 'add_cc_or_ld_argument' is already defined "
 "elsewhere!"
)
function(add_cc_or_ld_argument acola_TYPE acola_COMPILER)
 #Help message
 string(
  APPEND acola_HELP_MESSAGE
  "'add_cc_or_ld_argument' takes the following arguments:"
  "\n - (REQUIRED) <TYPE>: Either 'COMPILER' or 'LINKER'"
  "\n - (REQUIRED) <COMPILER>: The ID of the compiler for the given flag"
  "\n - (REQURIED) 'FLAGS'...: The flag(s)"
  "\n\nExample:"
  "\n add_cc_or_ld_argument(COMPILER GNU \"-fsanitize=address\")"
 )

 #Validate arguments
 is_empty(acola_TYPE_EMPTY "${acola_TYPE}")
 if(acola_TYPE_EMPTY)
  message("${acola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_argument: The <TYPE> argument must not be empty!"
  )
 endif()
 unset(acola_TYPE_EMPTY)

 is_empty(acola_COMPILER_EMPTY "${acola_COMPILER}")
 if(acola_COMPILER_EMPTY)
  message("${acola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_argument: The <COMPILER> argument must not be empty!"
  )
 endif()
 unset(acola_COMPILER_EMPTY)

 set(acola_FLAGS "${ARGN}")
 is_empty(acola_FLAGS_EMPTY "${acola_FLAGS}")
 if(acola_FLAGS_EMPTY)
  message("${acola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_argument: The 'FLAGS'... argument must not be empty!"
  )
 endif()
 unset(acola_FLAGS_EMPTY)

 list(APPEND acola_VALID_TYPES COMPILER LINKER)
 if(NOT acola_TYPE IN_LIST acola_VALID_TYPES)
  message("${acola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_argument: The type '${acola_TYPE}' is not a valid option! "
   "Must be one of: [COMPILER, LINKER]."
  )
 endif()
 unset(acola_VALID_TYPES)

 is_compiler_supported(acola_COMPILER_SUPPORTED "${acola_COMPILER}")
 if(NOT acola_COMPILER_SUPPORTED)
  message("${acola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_argument: Compiler '${acola_COMPILER}' is not supported!"
  )
 endif()
 unset(acola_COMPILER_SUPPORTED)

 #Compiler details prefix
 get_project_compiler_details_prefix(acola_COMPILER_DETAILS_PREFIX)

 #Determine dest var
 if(acola_TYPE STREQUAL "COMPILER")
  set(
   acola_SUPER_LIST_VAR
   "${acola_COMPILER_DETAILS_PREFIX}_${acola_COMPILER}_COMPILER_ARGS_LISTS"
  )
  set(
   acola_DEST_VAR
   "${acola_COMPILER_DETAILS_PREFIX}_${acola_COMPILER}_UNPAIRED_COMPILER_ARGS"
  )
 elseif(acola_TYPE STREQUAL "LINKER")
  set(
   acola_SUPER_LIST_VAR
   "${acola_COMPILER_DETAILS_PREFIX}_${acola_COMPILER}_LINKER_ARGS_LISTS"
  )
  set(
   acola_DEST_VAR
   "${acola_COMPILER_DETAILS_PREFIX}_${acola_COMPILER}_UNPAIRED_LINKER_ARGS"
  )
 endif()

 #Append dest var arg list to compiler/linker args super list
 if(NOT "${acola_DEST_VAR}" IN_LIST "${acola_SUPER_LIST_VAR}")
  list(
   APPEND "${acola_SUPER_LIST_VAR}"
   "${acola_DEST_VAR}"
  )
  set(
   "${acola_SUPER_LIST_VAR}"
   "${${acola_SUPER_LIST_VAR}}"
   PARENT_SCOPE
  )
 endif()

 #Append to compiler/linker args in parent scope
 list(
  APPEND "${acola_DEST_VAR}"
  "${acola_FLAGS}"
 )
 set(
  "${acola_DEST_VAR}"
  "${${acola_DEST_VAR}}"
  PARENT_SCOPE
 )
endfunction()

#[[
 Retrieves the list of cc and ld arguments and places it in the destination
 variable, in the parent scope

 TODO:
  - Change to read from global compiler/linkers args lists and return the
  flattened concatenated result
  - Remove `<COMPILER>` argument; will always be invoked in the context of the
    current compiler
]]
assert_name_unique(
 get_cc_or_ld_arguments
 COMMAND
 "Name collision: Function 'get_cc_or_ld_arguments' is already defined "
 "elsewhere!"
)
function(get_cc_or_ld_arguments
 gcola_TYPE
 gcola_COMPILER
 gcola_DESTINATION_VARIABLE
)
 #Help message
 string(
  APPEND gcola_HELP_MESSAGE
  "'get_cc_or_ld_argument' takes the following arguments:"
  "\n - (REQUIRED) <TYPE>: Either 'COMPILER' or 'LINKER'"
  "\n - (REQUIRED) <COMPILER>: The ID of the compiler to retrieve arguments "
  "for"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
 )

 #Validate arguments
 is_empty(gcola_TYPE_EMPTY "${gcola_TYPE}")
 if(gcola_TYPE_EMPTY)
  message("${gcola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_cc_or_ld_arguments: The <TYPE> argument must not be empty!"
  )
 endif()
 unset(gcola_TYPE_EMPTY)

 is_empty(gcola_COMPILER_EMPTY "${gcola_COMPILER}")
 if(gcola_COMPILER_EMPTY)
  message("${gcola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_cc_or_ld_arguments: The <COMPILER> argument must not be empty!"
  )
 endif()
 unset(gcola_COMPILER_EMPTY)

 is_empty(gcola_DESTINATION_VARIABLE_EMPTY "${gcola_DESTINATION_VARIABLE}")
 if(gcola_DESTINATION_VARIABLE_EMPTY)
  message("${gcola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_cc_or_ld_arguments: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(gcola_DESTINATION_VARIABLE_EMPTY)

 list(APPEND gcola_ALLOWED_TYPES COMPILER LINKER)
 if(NOT gcola_TYPE IN_LIST gcola_ALLOWED_TYPES)
  message("${gcola_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "get_cc_or_ld_arguments: The type '${gcola_TYPE}' is not a valid option! "
   "Must be one of: [COMPILER, LINKER]."
  )
 endif()
 unset(gcola_ALLOWED_TYPES)

 #Compiler details prefix
 get_project_compiler_details_prefix(gcola_COMPILER_DETAILS_PREFIX)

 #Determine which list var to use
 if(gcola_TYPE STREQUAL "COMPILER")
  set(
   gcola_ARGS_LISTS_VAR
   "${gcola_COMPILER_DETAILS_PREFIX}_${gcola_COMPILER}_COMPILER_ARGS_LISTS"
  )
 elseif(gcola_TYPE STREQUAL "LINKER")
  set(
   gcola_ARGS_LISTS_VAR
   "${gcola_COMPILER_DETAILS_PREFIX}_${gcola_COMPILER}_LINKER_ARGS_LISTS"
  )
 endif()

 #Collect all arguments
 foreach(gcola_ARGS_LIST ${${gcola_ARGS_LISTS_VAR}})
  list(
   APPEND gcola_TOTAL_ARGS_LIST
   "${${gcola_ARGS_LIST}}"
  )
 endforeach()

 #Set destination variable in parent scope
 set(
  "${gcola_DESTINATION_VARIABLE}"
  "${gcola_TOTAL_ARGS_LIST}"
  PARENT_SCOPE
 )
endfunction()

#TODO
assert_name_unique(
 add_cc_or_ld_arguments_for_build_flag
 COMMAND
 "Name collision: Function 'add_cc_or_ld_arguments_for_build_flag' is already "
 "defined elsewhere!"
)
function(add_cc_or_ld_arguments_for_build_flag
 acolafbf_TYPE
 acolafbf_COMPILER
 acolafbf_FLAG
)
 #TODO Help message
 string(
  APPEND acolafbf_HELP_MESSAGE
  "TODO"
 )

 #Validate arguments
 is_empty(acolafbf_TYPE_EMPTY "${acolafbf_TYPE}")
 if(acolafbf_TYPE_EMPTY)
  message("${acolafbf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_arguments_for_build_flag: The <TYPE> argument must not be "
   "empty!"
  )
 endif()
 unset(acolafbf_TYPE_EMPTY)

 is_empty(acolafbf_COMPILER_EMPTY "${acolafbf_COMPILER}")
 if(acolafbf_COMPILER_EMPTY)
  message("${acolafbf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_arguments_for_build_flag: The <COMPILER> argument must not "
   "be empty!"
  )
 endif()
 unset(acolafbf_COMPILER_EMPTY)

 is_empty(acolafbf_FLAG_EMPTY "${acolafbf_FLAG}")
 if(acolafbf_FLAG_EMPTY)
  message("${acolafbf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_arguments_for_build_flag: The <FLAG> argument must not be "
   "empty!"
  )
 endif()
 unset(acolafbf_FLAG_EMPTY)

 is_compiler_supported(acolafbf_COMPILER_SUPPORTED "${acolafbf_COMPILER}")
 if(NOT acolafbf_COMPILER_SUPPORTED)
  message("${acolafbf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "add_cc_or_ld_arguments_for_build_flag: Compiler '${acolafbf_COMPILER}' is "
   "not supported!"
  )
 endif()

 #Compiler details prefix
 get_project_compiler_details_prefix(acolafbf_COMPILER_DETAILS_PREFIX)

 #Determine dest var
 if(acolafbf_TYPE STREQUAL "COMPILER")
  string(
   APPEND acolafbf_SUPER_LIST_VAR
   "${acolafbf_COMPILER_DETAILS_PREFIX}_${acolafbf_COMPILER}_COMPILER_ARGS_"
   "LISTS"
  )
  string(
   APPEND acolafbf_DEST_VAR
   "${acolafbf_COMPILER_DETAILS_PREFIX}_${acolafbf_COMPILER}_${acolafbf_FLAG}_"
   "FLAG_COMPILER_ARGS"
  )
 elseif(acolafbf_TYPE STREQUAL "LINKER")
  string(
   APPEND acolafbf_SUPER_LIST_VAR
   "${acolafbf_COMPILER_DETAILS_PREFIX}_${acolafbf_COMPILER}_LINKER_ARGS_"
   "LISTS"
  )
  string(
   APPEND acolafbf_DEST_VAR
   "${acolafbf_COMPILER_DETAILS_PREFIX}_${acolafbf_COMPILER}_${acolafbf_FLAG}_"
   "FLAG_LINKER_ARGS"
  )
 endif()

 #Append dest var arg list to compiler/linker args super list
 if(NOT "${acolafbf_DEST_VAR}" IN_LIST "${acolafbf_SUPER_LIST_VAR}")
  list(
   APPEND "${acolafbf_SUPER_LIST_VAR}"
   "${acolafbf_DEST_VAR}"
  )
  set(
   "${acolafbf_SUPER_LIST_VAR}"
   "${${acolafbf_SUPER_LIST_VAR}}"
   PARENT_SCOPE
  )
 endif()

 #Append to compiler/linker flag args in parent scope
 list(
  APPEND "${acolafbf_DEST_VAR}"
  "${acolafbf_FLAGS}"
 )
 set(
  "${acolafbf_DEST_VAR}"
  "${${acolafbf_DEST_VAR}}"
  PARENT_SCOPE
 )
endfunction()

#TODO
assert_name_unique(
 get_cc_or_ld_arguments_for_build_flag
 COMMAND
 "Name collision: Function 'get_cc_or_ld_arguments_for_build_flag' is already "
 "defined elsewhere!"
)
function(get_cc_or_ld_arguments_for_build_flag)
 message(FATAL_ERROR "Unimplemented!")
endfunction()

#[[
 Assemble version inline namespace with the project name and version. Using
 this should prevent linking against binaries compiled with a different version
 of the same project.
]]
assert_name_unique(
 generate_inline_namespace
 COMMAND
 "Name collision: Function 'generate_inline_namespace' command already "
 "defined elsewhere!"
)
function(generate_inline_namespace gin_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND gin_HELP_MESSAGE
  "'generate_inline_namespace' takes the following arguments: "
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
  "\n\nExample:"
  "\n project("
  "\n  example"
  "\n  VERSION 1.0.0"
  "\n )"
  "\n generate_inline_namespace(value)"
  "\n message(\"\${value}\") #prints \"example_1_0_0\""
 )

 #Validate argument
 is_empty(gin_DESTINATION_VARIABLE_EMPTY "${gin_DESTINATION_VARIABLE}")
 if(gin_DESTINATION_VARIABLE_EMPTY)
  message("${gin_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "generate_inline_namespace: The <DESTINATION_VARIABLE> argument must not "
   "be empty!"
  )
 endif()
 unset(gin_DESTINATION_VARIABLE_EMPTY)

 #Ensure `project()` was invoked
 get_project_prefix(gin_PROJECT_PREFIX)
 is_empty(CMAKE_PROJECT_VERSION_EMPTY "${CMAKE_PROJECT_VERSION}")
 if(gin_PROJECT_PREFIX STREQUAL "NO_PROJECT" OR CMAKE_PROJECT_VERSION_EMPTY)
  message("${gin_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "generate_inline_namespace: Cannot generate an inline namespace string "
   "without a prior `project()` invocation, with a `VERSION` argument!"
  )
 endif()
 unset(CMAKE_PROJECT_VERSION_EMPTY)
 unset(gin_PROJECT_PREFIX)

 #Replace version string separators with underscores
 string(
  REPLACE "." "_"
  gin_INLINE_NAMESPACE
  "${CMAKE_PROJECT_NAME}_${CMAKE_PROJECT_VERSION}"
 )

 #Set value on destination variabble in parent scope
 set("${gin_DESTINATION_VARIABLE}" "${gin_INLINE_NAMESPACE}" PARENT_SCOPE)
endfunction()

#[[
 Assemble unique symbol guard based on build configuration, to ensure that it
 is not possible to link against binaries compiled with differently-configured
 builds of the same project
]]
assert_name_unique(
 generate_guard_symbol
 COMMAND
 "Name collision: Function 'generate_guard_symbol' command already defined "
 "elsewhere!"
)
function(generate_guard_symbol ggs_DESTINATION_VARIABLE)
 #Help message
 string(
  APPEND ggs_HELP_MESSAGE
  "'generate_guard_symbol' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable to place the result in, in the parent scope"
  "\n - (REQUIRED) 'ABI_BREAKING_FLAGS'...: - Space separated list of build "
  "flags, configured using `add_build_flag` or `add_fixed_build_flag`, that "
  "will break ABI compatibility when linking against two different versions "
  "of the same library"
  "\n\nExample:"
  "\n add_build_flag(flag1 value1)"
  "\n add_build_flag(flag2 value2)"
  "\n add_build_flag(flag3 value3)"
  "\n generate_guard_symbol("
  "\n  guard_symbol_name"
  "\n  ABI_BREAKING_FLAGS flag1 flag3"
  "\n )"
  "\n #[["
  "\n  Prints a very long guard symbol name with a human-readable warning and "
  "\n  the configuration of the flags that are breaking ABI compatibility"
  "\n ]]"
  "\n message(\"\${guard_symbol_name}\")"
 )

 #Get arguments
 cmake_parse_arguments(
  ggs
  ""
  ""
  "ABI_BREAKING_FLAGS"
  ${ARGN}
 )

 #Validate arguments
 is_empty(ggs_DESTINATION_VARIABLE_EMPTY "${ggs_DESTINATION_VARIABLE}")
 if(ggs_DESTINATION_VARIABLE_EMPTY)
  message("${ggs_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "generate_guard_symbol: The <DESTINATION_VARIABLE> argument must not be "
   "empty!"
  )
 endif()
 unset(ggs_DESTINATION_VARIABLE_EMPTYi)

 is_empty(ggs_ABI_BREAKING_FLAGS_EMPTY "${ggs_ABI_BREAKING_FLAGS}")
 if(ggs_ABI_BREAKING_FLAGS_EMPTY)
  message("${ggs_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "generate_guard_symbol: The 'ABI_BREAKING_FLAGS'... argument must not be "
   "empty!"
  )
 endif()
 unset(ggs_ABI_BREAKING_FLAGS_EMPTY)

 #Ensure flags exist and have a value
 foreach(ggs_FLAG ${ggs_ABI_BREAKING_FLAGS})
  #Ensure flag exists
  does_build_flag_exist("${ggs_FLAG}" ggs_FLAG_EXISTS)
  if(NOT ggs_FLAG_EXISTS)
   message("${ggs_HELP_MESSAGE}")
   message(
    FATAL_ERROR
    "generate_guard_symbol: The build flag '${ggs_FLAG}' does not exist!"
   )
  endif()
  unset(ggs_FLAG_EXISTS)

  #Ensure flag has a value
  is_empty(ggs_FLAG_VALUE_EMPTY "${${ggs_FLAG}}")
  if(ggs_FLAG_VALUE_EMPTY)
   message("${ggs_HELP_MESSAGE}")
   message(
    FATAL_ERROR
    "generate_guard_symbol: The flag '${ggs_FLAG}' does not have a value! All "
    "flags must have a value to be used in a guard symbol!"
   )
  endif()
  unset(ggs_FLAG_VALUE_EMPTY)
 endforeach()

 #Generate guard symbol name
 string(
  APPEND ggs_GUARD_SYMBOL
  "if_you_are_seeing_this_symbol_in_a_linker_related_error_then_you_are_"
  "trying_to_link_against_another_binary_with_a_differently_configured_build_"
  "of_${CMAKE_PROJECT_NAME}__this_is_not_allowed_as_some_build_flags_may_"
  "break_abi_compatibility_between_builds_with_different_configurations__"
  "your_configuration_is_as_follows"
 )
 foreach(ggs_FLAG ${ggs_ABI_BREAKING_FLAGS})
  string(
   APPEND ggs_GUARD_SYMBOL
   "____${ggs_FLAG}__${${ggs_FLAG}}"
  )
 endforeach()

 #Set guard symbol on destination variable in parent scope
 set("${ggs_DESTINATION_VARIABLE}" "${ggs_GUARD_SYMBOL}" PARENT_SCOPE)
endfunction()

#[[ TODO
 - cross-toolchain test coverage abstraction
 - add cc define formatters for all supported compilers
]]
