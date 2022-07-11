cmake_minimum_required(VERSION 3.19)

project(
 cakemake
 VERSION 0.1.0
 LANGUAGES NONE
)

#Enable CTest
include(CTest)
enable_testing()

#Set up tests
message(STATUS "Setting up tests:")
file(GLOB_RECURSE CMAKE_TEST_SUITES "test/**.cmake")
set(SUITE_ID 0)
foreach(TEST_SUITE_PATH ${CMAKE_TEST_SUITES})
 #Bump suite ID and generate a unique target for it
 math(EXPR SUITE_ID "${SUITE_ID} + 1")
 set(SUITE_TARGET "suite_${SUITE_ID}")

 #Get relative path of test
 file(
  RELATIVE_PATH TEST_SUITE_RELATIVE_PATH
  "${CMAKE_CURRENT_LIST_DIR}"
  "${TEST_SUITE_PATH}"
 )

 #[[
  TODO Move the `include` invocation into a separate function so that variables
  and other properties from the included files do not affect the global scope.
  This function should yield the `SUITE_NAME` and `ALL_TESTS` variables back
  to the caller, so that executors can be generated, targets can be set up, etc
 ]]
 #Include CMake test file
 message("Setting up suite '${TEST_SUITE_RELATIVE_PATH}'...")
 include(${TEST_SUITE_PATH})

 #Validate test name
 string(LENGTH "${SUITE_NAME}" SUITE_NAME_LENGTH)
 if(SUITE_NAME_LENGTH EQUAL 0)
  message(
   FATAL_ERROR
   "Test file '${TEST_SUITE_RELATIVE_PATH}' is missing a suite name! To "
   "provide a suite name, add the following line to the top of your file:"
   "\n set(SUITE_NAME \"My test suite name here\")"
  )
 endif()
 unset(SUITE_NAME_LENGTH)

 #Skip test runner generation if suite did not define any tests
 string(LENGTH "${ALL_TESTS}" ALL_TESTS_LENGTH)
 if(ALL_TESTS_LENGTH EQUAL 0)
  message("No tests defined for suite '${SUITE_NAME}'!")
  continue()
 endif()
 unset(ALL_TESTS_LENGTH)

 #Get test suite relative path and file name, without extension
 string(
  REPLACE
  "\.cmake" ""
  TEST_SUITE_PREFIX
  "${TEST_SUITE_RELATIVE_PATH}"
 )

 #Generate executor file for each test in the suite
 foreach(TEST_NAME ${ALL_TESTS})
  message(" - Added: ${TEST_NAME}")

  #[[
   TODO Replace the include file path with a relative path (from the test
   executor file to the actual test suite file)
  ]]
  #Create executor body
  string(
   APPEND TEST_EXECUTOR
   "include(${TEST_SUITE_PATH})"
   "\nset(CURRENT_SUITE \"${SUITE_NAME}\")"
   "\nset(CURRENT_TEST \"${TEST_NAME}\")"
   "\n${TEST_NAME}()"
   "\nunset(CURRENT_TEST)"
   "\nunset(CURRENT_SUITE)"
  )

  #Write out executor body to file
  set(TEST_EXECUTOR_PATH_VARIABLE "${TEST_NAME}_TEST_EXECUTOR_PATH")
  set(
   "${TEST_EXECUTOR_PATH_VARIABLE}"
   "${TEST_SUITE_PREFIX}__${TEST_NAME}.cmake"
  )
  file(
   GENERATE
   OUTPUT "${${TEST_EXECUTOR_PATH_VARIABLE}}"
   CONTENT "${TEST_EXECUTOR}"
   TARGET "${SUITE_TARGET}"
  )

  #Append executor file to list of dependencies for this test suite's target
  list(APPEND SUITE_EXECUTORS "${${TEST_EXECUTOR_PATH_VARIABLE}}")
  unset(TEST_EXECUTOR_PATH_VARIABLE)
  unset(TEST_EXECUTOR)
 endforeach()
 unset(TEST_SUITE_PREFIX)

 #[[
  Create custom target for this test suite and add all generated test executors
  as file dependencies
 ]]
 add_custom_target(
  "${SUITE_TARGET}" ALL
  DEPENDS ${SUITE_EXECUTORS}
 )
 unset(SUITE_TARGET)

 #Add CTest targets for each executor
 foreach(TEST_NAME ${ALL_TESTS})
  set(TEST_EXECUTOR_PATH_VARIABLE "${TEST_NAME}_TEST_EXECUTOR_PATH")

  #Add CTest target
  add_test(
   NAME "${SUITE_NAME}::${TEST_NAME}"
   COMMAND ${CMAKE_COMMAND} -P "${${TEST_EXECUTOR_PATH_VARIABLE}}"
  )

  #[[
   Set expected failure for test if `${TEST_NAME}_EXPECT_FAIL` is defined.

   Note: Do not specify the `WILL_FAIL` test property if an explicit
   PASS_REGEX is specified.
  ]]
  if(
   DEFINED "${TEST_NAME}_EXPECT_FAIL"
   AND NOT DEFINED "${TEST_NAME}_PASS_REGEX"
  )
   unset("${TEST_NAME}_EXPECT_FAIL")
   set_tests_properties(
    "${SUITE_NAME}::${TEST_NAME}"
    PROPERTIES
     WILL_FAIL TRUE
   )
  endif()

  #Set pass regex property for test, if defined
  if(DEFINED "${TEST_NAME}_PASS_REGEX")
   set_tests_properties(
    "${SUITE_NAME}::${TEST_NAME}"
    PROPERTIES
     PASS_REGULAR_EXPRESSION "${${TEST_NAME}_PASS_REGEX}"
   )
   unset("${TEST_NAME}_PASS_REGEX")
  endif()

  #Note: Do not currently have a need for supporting fail regex
  ##Set fail regex property for test, if defined
  #if(DEFINED "${TEST_NAME}_FAIL_REGEX")
  # set_tests_properties(
  #  "${SUITE_NAME}::${TEST_NAME}"
  #  PROPERTIES
  #   FAIL_REGULAR_EXPRESSION "${${TEST_NAME}_FAIL_REGEX}"
  # )
  # unset("${TEST_NAME}_FAIL_REGEX")
  #endif()

  #Clean up executor path variable
  unset("${TEST_EXECUTOR_PATH_VARIABLE}")
  unset(TEST_EXECUTOR_PATH_VARIABLE)
 endforeach()
 unset(SUITE_EXECUTORS)

 #Print suite information
 list(LENGTH ALL_TESTS ALL_TESTS_LENGTH)
 message(
  "Successfully added ${ALL_TESTS_LENGTH} tests from suite '${SUITE_NAME}'!"
 )
 unset(ALL_TESTS_LENGTH)

 #[[
  Remove `SUITE_NAME` and `ALL_TESTS` to avoid unintentional conflicts with
  other tests
 ]]
 unset(SUITE_NAME)
 unset(ALL_TESTS)

 unset(SUITE_TARGET)
endforeach()

#Clean up `CMAKE_TESTS`
unset(CMAKE_TESTS)
