cmake_minimum_required(VERSION 3.19)

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/util.cmake)

#[[TODO:
 - Set up global cache variable for prefixing all definitions in this library
 - Add unique name assertions to all function declarations
 - Remove internal `print_help` variants in favour of manual `message`
   invocations
 - Add help messages to all functions
]]

#[[
 Generates a variable name to store build flags in for the current `project()`
 scope and places it in a destination variable
]]
function(get_project_flags_variable gpfv_DESTINATION_VARIABLE)
 #Get project prefix
 get_project_prefix("${gpfv_DESTINATION_VARIABLE}")

 #Create unique variable name for storing build flags
 string(APPEND "${gpfv_DESTINATION_VARIABLE}" "_BUILD_FLAGS")

 #Set destination variable in parent scope
 set(
  "${gpfv_DESTINATION_VARIABLE}" "${${gpfv_DESTINATION_VARIABLE}}"
  PARENT_SCOPE
 )
endfunction()

#Checks if a flag exists. Places result in desintation variable
function(does_build_flag_exist dbfe_FLAG dbfe_DESTINATION_VARIABLE)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(dbfe_BUILD_FLAGS_LIST_VAR)

 #Validate flag name
 is_empty(dbfe_FLAG_EMPTY "${dbfe_FLAG}")
 if(dbfe_FLAG_EMPTY)
  message(
   FATAL_ERROR
   "does_build_flag_exist: Flag name cannot be empty!"
  )
 endif()
 unset(dbfe_FLAG_EMPTY)

 #Validate destination variable name
 is_empty(dbfe_DESTINATION_VARIABLE_EMPTY "${dbfe_DESTINATION_VARIABLE}")
 if(dbfe_DESTINATION_VARIABLE_EMPTY)
  message(
   FATAL_ERROR
   "does_build_flag_exist: Destination variable name cannot be empty!"
  )
 endif()
 unset(dbfe_DESTINATION_VARIABLE_EMPTY)

 #TODO Swap out for IN_LIST
 #Search for flag
 set(dbfe_FLAG_EXISTS FALSE)
 foreach(FLAG ${${dbfe_BUILD_FLAGS_LIST_VAR}})
  if(FLAG STREQUAL dbfe_FLAG)
   set(dbfe_FLAG_EXISTS TRUE)
   break()
  endif()
 endforeach()

 #Set result on destination variable in parent scope
 set("${dbfe_DESTINATION_VARIABLE}" "${dbfe_FLAG_EXISTS}" PARENT_SCOPE)
 unset(dbfe_FLAG_EXISTS)
endfunction()

#[[
 Add build flag to project build flag list, set up parent scope flag and store
 flag description
]]
function(add_build_flag abf_FLAG)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(abf_BUILD_FLAGS_LIST_VAR)

 #Validate flag name
 is_empty(abf_FLAG_EMPTY "${abf_FLAG}")
 if(abf_FLAG_EMPTY)
  message(
   FATAL_ERROR
   "add_build_flag: Flag name cannot be empty!"
  )
 endif()
 unset(abf_FLAG_EMPTY)

 #Ensure flag does not already exist
 does_build_flag_exist("${abf_FLAG}" abf_FLAG_EXISTS)
 if(abf_FLAG_EXISTS)
  message(
   FATAL_ERROR
   "add_build_flag: Flag '${abf_FLAG}' already exists!"
  )
 endif()
 unset(abf_FLAG_EXISTS)

 #Help message utility function
 function(abf_print_help abf_ph_LEVEL)
  #Print help
  message(
   "'add_build_flag' takes the following arguments:"
   "\n - (REQUIRED) <FLAG_NAME>: The name of the flag. Must be the first "
   "argument, always."
   "\n - (OPTIONAL) 'VALUE': The default value for the flag. If no value is "
   "specified, then the flag will be unset like so: "
   "`unset(\${<FLAG_NAME>})`. If multiple values are specified, then they "
   "will be appended to the variable `\${<FLAG_NAME>}`, as a "
   "semicolon-separated list."
   "\n - (OPTIONAL) 'CACHE': Set up flag as a cache variable. Possible "
   "arguemnts are: [BOOL, FILEPATH, PATH, STRING, INTERNAL]. These values are "
   "the same as those for the CMake builtin in `set(CACHE <type>)`. For more "
   "information, see https://cmake.org/cmake/help/v3.19/command/set.html"
   "\n - (OPTIONAL) 'DESCRIPTION': The description of the flag."
   "\n"
  )

  #Print diagnostic
  list(LENGTH ARGN abf_ph_DYNAMIC_ARGUMENT_LENGTH)
  if(abf_ph_DYNAMIC_ARGUMENT_LENGTH GREATER 0)
   message(${abf_ph_LEVEL} ${ARGN})
  else()
   message(${abf_ph_LEVEL} "Illegal arguments supplied to 'add_build_flag'!")
  endif()
  unset(abf_ph_DYNAMIC_ARGUMENT_LENGTH)
 endfunction()

 #Parse arguments
 cmake_parse_arguments(
  abf
  "FORCE"
  "DESCRIPTION;CACHE"
  "VALUE"
  ${ARGN}
 )

 #Sanitize arguments
 if(abf_FORCE AND NOT DEFINED abf_CACHE)
  abf_print_help(FATAL_ERROR "'FORCE' can only be set alongside 'CACHE'!")
 endif()

 #Append argument to `project()` scope of build arguments
 list(APPEND "${abf_BUILD_FLAGS_LIST_VAR}" "${abf_FLAG}")
 set(
  "${abf_BUILD_FLAGS_LIST_VAR}" "${${abf_BUILD_FLAGS_LIST_VAR}}"
  PARENT_SCOPE
 )

 #Store variable description
 set(
  abf_FLAG_DESCRIPTION_VARIABLE
  "${abf_BUILD_FLAGS_LIST_VAR}_${abf_FLAG}_DESCRIPTION"
 )
 if(DEFINED abf_DESCRIPTION)
  #Set description to user-specified description
  set(abf_FLAG_DESCRIPTION "${abf_DESCRIPTION}")
 else()
  #Indicate that no description was no specified by the user
  set(abf_FLAG_DESCRIPTION "[no description provided]")
 endif()
 set("${abf_FLAG_DESCRIPTION_VARIABLE}" "${abf_FLAG_DESCRIPTION}" PARENT_SCOPE)
 unset(abf_FLAG_DESCRIPTION_VARIABLE)

 #Set flag value and description
 if(DEFINED abf_CACHE)
  if(DEFINED abf_FORCE)
   set(
    ${abf_FLAG} ${abf_VALUE}
    CACHE ${abf_CACHE}
    "${abf_FLAG_DESCRIPTION}"
    FORCE
   )
  else()
   set(
    ${abf_FLAG} ${abf_VALUE}
    CACHE ${abf_CACHE}
    "${abf_FLAG_DESCRIPTION}"
   )
  endif()
 else()
  set(${abf_FLAG} ${abf_VALUE} PARENT_SCOPE)
 endif()
 unset(abf_FLAG_DESCRIPTION)
endfunction()

#Adds a non-configurable build flag with a fixed value
function(add_fixed_build_flag afbf_FLAG)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(afbf_BUILD_FLAGS_LIST_VAR)

 #Validate flag argument
 is_empty(afbf_FLAG_EMPTY "${afbf_FLAG}")
 if(afbf_FLAG_EMPTY)
  message(
   FATAL_ERROR
   "add_fixed_build_flag: Flag name cannot be empty!"
  )
 endif()
 unset(afbf_FLAG_EMPTY)

 #Prefix for flag settings
 set(afbf_FLAG_SETTING_PREFIX "${afbf_BUILD_FLAGS_LIST_VAR}_${afbf_FLAG}")

 #Check if user specified a `CACHE` flag, so we know if we need to propagate
 #the variable parent scope
 cmake_parse_arguments(
  afbf
  ""
  "CACHE"
  ""
  ${ARGN}
 )

 #Reuse `add_build_flag`
 #Note: Must propagate all variables set by `add_build_flag` to parent scope
 add_build_flag("${afbf_FLAG}" ${ARGN})
 set(
  "${afbf_BUILD_FLAGS_LIST_VAR}" "${${afbf_BUILD_FLAGS_LIST_VAR}}"
  PARENT_SCOPE
 )
 set(afbf_FLAG_DESCRIPTION_VARIABLE "${afbf_FLAG_SETTING_PREFIX}_DESCRIPTION")
 set(
  "${afbf_FLAG_DESCRIPTION_VARIABLE}" "${${afbf_FLAG_DESCRIPTION_VARIABLE}}"
  PARENT_SCOPE
 )
 #Only need to propagate flag value to parent scope if it was not a `CACHE`
 #flag
 if(NOT DEFINED afbf_CACHE)
  set(${afbf_FLAG} ${${afbf_FLAG}} PARENT_SCOPE)
 endif()
 unset(afbf_FLAG_DESCRIPTION_VARIABLE)
 unset(afbf_CACHE)

 #Set unconfigurable flag in parent scope so this flag can be differentiated
 set(
  afbf_FLAG_CONFIGURABLE_VARIABLE
  "${afbf_FLAG_SETTING_PREFIX}_CONFIGURABLE"
 )
 set("${afbf_FLAG_CONFIGURABLE_VARIABLE}" FALSE PARENT_SCOPE)
 unset(afbf_FLAG_CONFIGURABLE_VARIABLE)
endfunction()

#Check whether a build flag is configurable. Places result in desination
#variable.
function(is_build_flag_configurable ibfc_FLAG ibfc_DESTINATION_VARIABLE)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(ibfc_BUILD_FLAGS_LIST_VAR)

 #Validate flag name
 is_empty(ibfc_FLAG_EMPTY "${ibfc_FLAG}")
 if(ibfc_FLAG_EMPTY)
  message(
   FATAL_ERROR
   "is_build_flag_configurable: Flag name cannot be empty!"
  )
 endif()
 unset(ibfc_FLAG_EMPTY)

 #Validate destination variable name
 is_empty(ibfc_DESTINATION_VARIABLE_EMPTY "${ibfc_DESTINATION_VARIABLE}")
 if(ibfc_DESTINATION_VARIABLE_EMPTY)
  message(
   FATAL_ERROR
   "is_build_flag_configurable: Destination variable name must not be empty!"
  )
 endif()
 unset(ibfc_DESTINATION_VARIABLE_EMPTY)

 #Ensure flag exists
 does_build_flag_exist("${ibfc_FLAG}" ibfc_FLAG_EXISTS)
 if(NOT ibfc_FLAG_EXISTS)
  message(
   FATAL_ERROR
   "is_build_flag_configurable: Flag '${ibfc_FLAG}' does not exist!"
  )
 endif()
 unset(ibfc_FLAG_EXISTS)

 #Check if flag is configurable
 set(
  ibfc_FLAG_CONFIGURABLE_VARIABLE_NAME
  "${ibfc_BUILD_FLAGS_LIST_VAR}_${ibfc_FLAG}_CONFIGURABLE"
 )
 if(NOT DEFINED "${ibfc_FLAG_CONFIGURABLE_VARIABLE_NAME}")
  set(ibfc_FLAG_CONFIGURABLE TRUE)
 else()
  set(ibfc_FLAG_CONFIGURABLE FALSE)
 endif()
 unset(ibfc_FLAG_CONFIGURABLE_VARIABLE_NAME)

 #Set result on destination variable in parent scope
 set("${ibfc_DESTINATION_VARIABLE}" "${ibfc_FLAG_CONFIGURABLE}" PARENT_SCOPE)
 unset(ibfc_FLAG_CONFIGURABLE)
endfunction()

#Get a list of build flags and place it in a destination variable
function(get_build_flag_list gbfl_DESTINATION_VARIABLE)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(gbfl_BUILD_FLAGS_LIST_VAR)

 #Validate destination variable name
 is_empty(gbfl_DESTINATION_VARIABLE_EMPTY "${gbfl_DESTINATION_VARIABLE}")
 if(gbfl_DESTINATION_VARIABLE_EMPTY)
  message(
   FATAL_ERROR
   "get_build_flag_list: Destination variable name cannot be empty!"
  )
 endif()
 unset(gbfl_DESTINATION_VARIABLE_EMPTY)

 #Set destination variable to current build flags list
 set(
  "${gbfl_DESTINATION_VARIABLE}" "${${gbfl_BUILD_FLAGS_LIST_VAR}}"
  PARENT_SCOPE
 )
endfunction()

#Get the value of a specific build flag and place it in a destination variable
function(get_build_flag gbf_FLAG gbf_DESTINATION_VARIABLE)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(gbf_BUILD_FLAGS_LIST_VAR)

 #Validate flag name
 does_build_flag_exist("${gbf_FLAG}" gbf_FLAG_EXISTS)

 #Emit diagnostic if flag does not exist
 if(NOT gbf_FLAG_EXISTS)
  message(
   FATAL_ERROR
   "get_build_flag: Flag '${gbf_FLAG}' does not exist!"
  )
 endif()
 unset(gbf_FLAG_EXISTS)

 #Validate destination variable name
 is_empty(gbf_DESTINATION_VARIABLE_EMPTY "${gbf_DESTINATION_VARIABLE}")
 if(gbf_DESTINATION_VARIABLE_EMPTY)
  message(
   FATAL_ERROR
   "get_build_flag: Destination variable name cannot be empty!"
  )
 endif()
 unset(gbf_DESTINATION_VARIABLE_EMPTY)

 #Set flag value on destination variable name in the parent scope
 set("${gbf_DESTINATION_VARIABLE}" "${${gbf_FLAG}}" PARENT_SCOPE)
endfunction()

#Get the description of a build flag and place it in a destination variable
function(get_build_flag_description gbfd_FLAG gbfd_DESTINATION_VAR)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(gbfd_BUILD_FLAGS_LIST_VAR)

 #Reuse checks in `get_build_flag` and discard result
 get_build_flag("${gbfd_FLAG}" "${gbfd_DESTINATION_VAR}")

 #Set the flag description on the destination variable in the parent scope
 set(
  gbfd_FLAG_DESCRIPTION_VARIABLE
  "${gbfd_BUILD_FLAGS_LIST_VAR}_${gbfd_FLAG}_DESCRIPTION"
 )
 set(
  "${gbfd_DESTINATION_VAR}" "${${gbfd_FLAG_DESCRIPTION_VARIABLE}}"
  PARENT_SCOPE
 )
 unset(gbfd_FLAG_DESCRIPTION_VARIABLE)
endfunction()

#Assembles a pretty string for the build arguments and place it in a result
#variable
function(get_build_flags_pretty gbfp_DESTINATION_VARIABLE)
 #Get build flags list variable name for the current `project()` scope
 get_project_flags_variable(gbfp_BUILD_FLAGS_LIST_VAR)

 #Validate destination variable name
 is_empty(gbfp_DESTINATION_VARIABLE_EMPTY "${gbfp_DESTINATION_VARIABLE}")
 if(gbfp_DESTINATION_VARIABLE_EMPTY)
  message(
   FATAL_ERROR
   "get_build_flags_pretty: Destination variable name cannot be empty!"
  )
 endif()
 unset(gbfp_DESTINATION_VARIABLE_EMPTY)

 #Set up flag pretty identifiers
 set(gbfp_MAX_FLAG_LENGTH 0)
 foreach(FLAG ${${gbfp_BUILD_FLAGS_LIST_VAR}})
  #Determine pretty flag string
  is_build_flag_configurable("${FLAG}" gbfp_FLAG_CONFIGURABLE)
  if(gbfp_FLAG_CONFIGURABLE)
   set("gbfp_${FLAG}_PRETTY_NAME" "${FLAG}")
  else()
   set("gbfp_${FLAG}_PRETTY_NAME" "[${FLAG}]")
  endif()
  unset(gbfp_FLAG_CONFIGURABLE)

  #Find maximum pretty flag name length
  string(LENGTH "${gbfp_${FLAG}_PRETTY_NAME}" gbfp_FLAG_LENGTH)
  if(gbfp_FLAG_LENGTH GREATER gbfp_MAX_FLAG_LENGTH)
   set(gbfp_MAX_FLAG_LENGTH ${gbfp_FLAG_LENGTH})
  endif()
  unset(gbfp_FLAG_LENGTH)
 endforeach()

 #Substitute in spacing and append lines to result string
 string(APPEND gbfp_PRETTY_FLAGS "Build configuration:")
 foreach(FLAG ${${gbfp_BUILD_FLAGS_LIST_VAR}})
  #Create flag and value stub string
  set(
   gbfp_PRETTY_FLAG_LINE
   "\n - ${gbfp_${FLAG}_PRETTY_NAME}:__SPACING__${${FLAG}}"
  )

  #Replace `__SPACING__` with correct spacing
  string(LENGTH "${gbfp_${FLAG}_PRETTY_NAME}" gbfp_FLAG_PRETTY_NAME_LENGTH)
  math(
   EXPR gbfp_PRETTY_FLAG_LINE_SPACING
   "1 + (${gbfp_MAX_FLAG_LENGTH} - ${gbfp_FLAG_PRETTY_NAME_LENGTH})"
  )
  unset(gbfp_FLAG_PRETTY_NAME_LENGTH)
  string(REPEAT " " ${gbfp_PRETTY_FLAG_LINE_SPACING} gbfp_SPACING)
  string(
   REPLACE "__SPACING__" "${gbfp_SPACING}"
   gbfp_PRETTY_FLAG_LINE
   "${gbfp_PRETTY_FLAG_LINE}"
  )
  unset(gbfp_SPACING)

  #Append pretty flag line to result string
  string(APPEND gbfp_PRETTY_FLAGS "${gbfp_PRETTY_FLAG_LINE}")

  unset(gbfp_PRETTY_FLAG_LINE)
  unset("gbfp_${FLAG}_PRETTY_NAME")
 endforeach()
 unset(gbfp_MAX_FLAG_LENGTH)

 #Set pretty string on destination variable name in parent scope
 set("${gbfp_DESTINATION_VARIABLE}" "${gbfp_PRETTY_FLAGS}" PARENT_SCOPE)
 unset(gbfp_PRETTY_FLAGS)
endfunction()
