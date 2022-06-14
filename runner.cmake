#This script is responsible for running a given CMake test suite file
cmake_minimum_required(VERSION 3.19)

#Validate supplied path
string(LENGTH "${TEST_PATH}" TEST_PATH_LENGTH)
if(TEST_PATH_LENGTH EQUAL 0)
 message(
  FATAL_ERROR
  "runner.cmake: The 'TEST_PATH' argument must not be empty!"
 )
endif()
unset(TEST_PATH_LENGTH)

#Ensure path exists
if(NOT EXISTS "${TEST_PATH}")
 message(
  FATAL_ERROR
  "runner.cmake: The supplied path '${TEST_PATH}' for the 'TEST_PATH' "
  "argument does not exist!"
 )
endif()

#Include test file and execute tests
include("${TEST_PATH}")

#Validate test suite name
string(LENGTH "${SUITE_NAME}" SUITE_NAME_LENGTH)
if(SUITE_NAME_LENGTH EQUAL 0)
 message(
  FATAL_ERROR
  "runner.cmake: The test suite '${SUITE_NAME}' did not define a name! Add "
  "the following line in '${TEST_PATH}':"
  "\n set(SUITE_NAME \"Your suite name here\")"
 )
endif()
unset(SUITE_NAME_LENGTH)

#Ensure that `test.cmake` was included in the target suite
if(NOT COMMAND run_test_suite)
 #Get the path of the `test.cmake` file relative to the test suite path
 get_filename_component(
  TEST_PATH_DIR
  "${CMAKE_CURRENT_LIST_DIR}/${TEST_PATH}"
  DIRECTORY
 )
 file(
  RELATIVE_PATH TEST_CMAKE_RELATIVE_PATH
  "${TEST_PATH_DIR}"
  "${CMAKE_CURRENT_LIST_DIR}/test.cmake"
 )
 unset(TEST_PATH_DIR)

 #Print error and fix
 message(
  FATAL_ERROR
  "runner.cmake: The test suite '${SUITE_NAME}' did not include the "
  "'test.cmake' script! Add the following line to the '${TEST_PATH}' file, "
  "after your `set(SUITE_NAME \"...\")` line:"
  "\n include(${TEST_CMAKE_RELATIVE_PATH})"
 )
 unset(TEST_CMAKE_RELATIVE_PATH)
endif()

#Run suite
run_test_suite()
