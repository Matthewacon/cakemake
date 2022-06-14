cmake_minimum_required(VERSION 3.19)

project(
 cakemake
 VERSION 0.1.0
 LANGUAGES NONE
)

#Enable CTest
include(CTest)
enable_testing()

#[[
 TODO For each invocation of `define_test`, generate a cmake script that can be
 run through CTest, so that tests are run in isolated CMake instances
]]

#Set up tests
message(STATUS "Setting up tests:")
file(GLOB_RECURSE CMAKE_TESTS "test/**.cmake")
message(FATAL_ERROR "FOUND TESTS: ${CMAKE_TESTS}")

foreach(TEST ${CMAKE_TESTS})
 #Include CMake test file
 include(${TEST})

 #Validate test name
 string(LENGTH "${SUITE_NAME}" SUITE_NAME_LENGTH)
 if(SUITE_NAME_LENGTH EQUAL 0)
  message(
   FATAL_ERROR
   "Test file '${}' missing suite name! To provide a suite name, add the "
   "following line to the top of your file:"
   "\n set(SUITE_NAME \"My test suite name here\")"
  )
 endif()
 unset(SUITE_NAME_LENGTH)

 #TODO Use name set by test
 message(STATUS "- ")

 #Remove `SUITE_NAME` to avoid unintentional conflicts with other tests
 unset(SUITE_NAME)
endforeach()

#Clean up `CMAKE_TESTS`
unset(CMAKE_TESTS)
