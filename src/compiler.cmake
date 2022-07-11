cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)

#[[TODO:
 - Set up global cache variable for prefixing all definitions in this library
 - Add help messages to all functions
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
 #Get compiler details variable
 get_project_compiler_details_prefix(dc_COMPILER_DETAILS_PREFIX)

 #Help message utility function
 string(
  APPEND dc_HELP_MESSAGE
  "'detect_compiler' takes the following arguments:"
  "\n - (REQUIRED) <DESTINATION_VARIABLE> - The name of the variable to "
  "place the detected compiler ID"
  "\n - (REQUIRED) 'COMPILER_ID' - CMake compiler ID variable to track; ie. "
  "CMAKE_CXX_COMPILER_ID. For more information, see: "
  "https://cmake.org/cmake/help/v3.19/variable/CMAKE_LANG_COMPILER_ID.html"
  "\n - (REQUIRED) 'SUPPORTED_COMPILERS'... - Space separated list of "
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
   "detect_compiler: The provided compiler ID variable, '${dc_COMPILER}', is "
   "not set! Are you sure that you provided the correct compiler ID variable?"
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
   "'${${dc_COMPILER_ID}}' is an unsupported compiler. Supported compilers "
   "include: ${dc_PRETTY_COMPILER_STR}"
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
 #Compiler details prefix
 get_project_compiler_details_prefix(gdc_COMPILER_DETAILS_PREFIX)

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
  message(FATAL_ERROR "The <DESTINATION_VARIABLE> argument must not be empty!")
 endif()
 unset(gdc_DESTINATION_VARIABLE_EMPTY)

 #Ensure `detect_compiler` was invoked before
 set(gdc_COMPILER_ID_VAR "${gdc_COMPILER_DETAILS_PREFIX}_DETECTED_COMPILER_ID")
 if(NOT DEFINED "${gdc_COMPILER_ID_VAR}")
  message("${gdc_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "The detected compiler ID is not set! You must call `detect_compiler` "
   "before attempting to retrieve the detected compiler ID!"
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
 #Get details prefix
 get_project_compiler_details_prefix(gsc_COMPILER_DETAILS_PREFIX)

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
 #Get compiler details prefix
 get_project_compiler_details_prefix(ics_COMPILER_DETAILS_PREFIX)

 #Help message
 string(
  APPEND ics_HELP_MESSAGE
  "'is_compiler_supported' takes the following arguments:"
  "\n - (REQUIRED) <COMPILER_ID>: The name of the compiler to check"
  "\n - (REQUIRED) <DESTINATION_VARIABLE>: The name of the destination "
  "variable, to place the result in"
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

 #Validate compiler name
 is_empty(ics_COMPILER_EMPTY "${ics_COMPILER}")
 if(ics_COMPILER_EMPTY)
  message("${ics_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "is_compiler_supported: The 'COMPILER' argument must not be empty!"
  )
 endif()
 unset(ics_COMPILER_EMPTY)

 #Validate destination variable name
 is_empty(ics_DESTINATION_VARIABLE_EMPTY "${ics_DESTINATION_VARIABLE}")
 if(ics_DESTINATION_VARIABLE_EMPTY)
  message("${ics_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "is_compiler_supported: The 'DESTINATION_VARIABLE' argument must not be "
   "empty!"
  )
 endif()
 unset(ics_DESTINATION_VARIABLE_EMPTY)

 #Check if compiler is supported
 set(
  ics_SUPPORTED_COMPILER_LIST_VARIABLE
  "${ics_COMPILER_DETAILS_PREFIX}_SUPPORTED_COMPILERS"
 )
 if(ics_COMPILER IN_LIST "${ics_SUPPORTED_COMPILER_LIST_VARIABLE}")
  set(ics_COMPILER_SUPPORTED TRUE)
 else()
  set(ics_COMPILER_SUPPORTED FALSE)
 endif()
 unset(ics_SUPPORTED_COMPILER_LIST_VARIABLE)

 #Set result on destination variable in parent scope
 set("${ics_DESTINATION_VARIABLE}" "${ics_COMPILER_SUPPORTED}" PARENT_SCOPE)
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
 #Compiler details prefix
 get_project_compiler_details_prefix(acdf_COMPILER_DETAILS_PREFIX)

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
  message(FATAL_ERROR "The <COMPILER> argument must not be empty!")
 endif()
 unset(acdf_COMPILER_EMPTY)

 #Validate formatter function name
 is_empty(acdf_FORMATTER_FUNCTION_EMPTY "${acdf_FORMATTER_FUNCTION}")
 if(acdf_FORMATTER_FUNCTION_EMPTY)
  message("${acdf_HELP_MESSAGE}")
  message(FATAL_ERROR "The <FORMATTER_FUNCTION> argument must not be empty!")
 endif()
 unset(acdf_FORMATTER_FUNCTION_EMPTY)

 if(NOT COMMAND "${acdf_FORMATTER_FUNCTION}")
  message("${acdf_HELP_MESSAGE}")
  message(
   FATAL_ERROR
   "The formatter function '${acdf_FORMATTER_FUNCTION}' is not defined!"
  )
 endif()

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
   "The compiler '${acdf_COMPILER}' already has a define formatter specified! "
   "(formatter: '${${acdf_DEFINE_FORMATTER_NAME_VAR}}')"
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

#TODO Add formatters for default set of supported compilers

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
 #Compiler details prefix
 get_project_compiler_details_prefix(gcdf_COMPILER_DETAILS_PREFIX)

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
  message(FATAL_ERROR "The <COMPILER> argument must not be empty!")
 endif()
 unset(gcdf_COMPILER_EMPTY)

 #Validate destination variable name
 is_empty(gcdf_DESTINATION_VARIABLE_EMPTY "${gcdf_DESTINATION_VARIABLE}")
 if(gcdf_DESTINATION_VARIABLE_EMPTY)
  message("${gcdf_HELP_MESSAGE}")
  message(FATAL_ERROR "The <DESTINATION_VARIABLE> argument must not be empty!")
 endif()
 unset(gcdf_DESTINATION_VARIABLE_EMPTY)

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
 #Compiler details prefix
 get_project_compiler_details_prefix(rcdf_COMPILER_DETAILS_PREFIX)

 string(
  APPEND rcdf_HELP_MESSAGE
  "'remoce_compiler_define_formatter' takes the following arguments:"
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
  message(FATAL_ERROR "The <COMPILER> argument must not be empty!")
 endif()
 unset(rcdf_COMPILER_EMPTY)

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
 add_cc_define
 COMMAND
 "Name collision: Function 'add_cc_define' is already defined elsewhere!"
)
function(add_cc_define acd_ARG acd_VALUE)
 #Compiler details prefix
 get_project_compiler_details_prefix(acd_COMPILER_DETAILS_PREFIX)

 #Help message
 string(
  APPEND acd_HELP_MESSAGE
  "'add_cc_define' takes the following arguments:"
  "\n - (REQUIRED) <DEFINE_NAME>: The name of the cc define"
  "\n - (REQUIRED) <VALUE>: The value of the cc define"
  "\n\nExample:"
  "\n detect_compiler("
  "\n  unused"
  "\n  COMPILER_ID CMAKE_C_CMPILER_ID"
  "\n  SUPPORTED_COMPILERS Clang"
  "\n )"
  "\n add_cc_define(\"FIRST\" \"123\")"
  "\n add_cc_define(\"SECOND\" \"456\")"
  "\n "
  "\n #Get the list of cc defines"
  "\n get_cc_defines(cc_defines)"
  "\n message(\"\${cc_defines}\") #Prints \"FIRST;SECOND\""
  "\n "
  "\n #Get the value for a given cc define"
  "\n get_cc_define_value(FIRST FIRST_value)"
  "\n message(\"\${FIRST_value}\") #Prints \"123\""
  "\n "
  "\n #Get the formatted string that will be passed to the compiler"
  "\n get_formatted_cc_define(SECOND SECOND_formatted)"
  "\n message(\"\${SECOND_formatted}\") #Prints '-DSECOND=456'"
 )

 #Validate cc define argument name
 is_empty(acd_ARG_EMPTY "${acd_ARG}")
 if(acd_ARG_EMPTY)
  message("${acd_HELP_MESSAGE}")
  message("The <DEFINE_NAME> argument must not be empty!")
 endif()
 unset(acd_ARG_EMPTY)

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
   "Missing formatter for compiler '${acd_DETECTED_COMPILER_ID}'! You must "
   "specify a define formatter using `add_compiler_define_formatter()` for "
   "the compiler '${acd_DETECTED_COMPILER_ID}'!"
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
   "The define formatter for the compiler '${acd_DETECTED_COMPILER_ID}' did "
   "not return a value! (function: '${acd_COMPILER_DEFINE_FORMATTER}')"
  )
 endif()
 unset(acd_FORMATTED_DEFINE_EMPTY)

 #Add arg to list of cc defines
 list(
  APPEND "${acd_DEFINE_LIST_VAR}"
  "${acd_ARG}"
 )
 set("${acd_DEFINE_LIST_VAR}" "${${acd_DEFINE_LIST_VAR}}" PARENT_SCOPE)

 #Associate value with cc define
 set("${acd_DEFINE_VALUE_VAR}" "${acd_VALUE}" PARENT_SCOPE)

 #Associate formatted argument with cc define
 set("${acd_DEFINE_FORMATTED_VAR}" "${acd_FORMATTED_DEFINE}" PARENT_SCOPE)
endfunction()

#[[
 TODO Retrieves the list of cc defines and places it in the destination
 variable, in the parent scope
]]
assert_name_unique(
 get_cc_defines
 COMMAND
 "Name collision: Function 'get_cc_defines' is already defined elsewhere!"
)
function(get_cc_defines gcd_DESTINATION_VARIABLE)
endfunction()

##TODO Retrieves the value for a given cc define
function(get_cc_define_value gcdv_ARG gcdv_DESTINATION_VARIABLE)
endfunction()

##TODO Retrieves the formatted string for a cc define
function(get_formatted_cc_define gfcd_ARG gfcd_DESTINATION_VARIABLE)
endfunction()

#TODO Add compiler or linker flags, segmented by compiler
# Maybe should be `add_raw_compiler_argument`
assert_name_unique(
 add_cc_or_ld_argument
 COMMAND
 "Name collision: Function 'add_cc_or_ld_argument' is already defined "
 "elsewhere!"
)
function(add_cc_or_ld_argument)
endfunction()

#[[
 TODO Retrieves the list of cc and ld arguments and places it in the
 destination variable, in the parent scope
]]
assert_name_unique(
 get_cc_or_ld_arguments
 COMMAND
 "Name collision: Function 'get_cc_or_ld_arguments' is already defined "
 "elsewhere!"
)
function(get_cc_and_ld_arguments gcala_DESTINATION_VARIABLE)
endfunction()
