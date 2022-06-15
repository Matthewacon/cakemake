cmake_minimum_required(VERSION 3.19)

#Ensure the suite including this script has defined a name
string(LENGTH "${SUITE_NAME}" SUITE_NAME_LENGTH)
if(SUITE_NAME_LENGTH EQUAL 0)
 message(
  FATAL_ERROR
  "test.cmake: No name has been defined for this test suite! Add the "
  "following line to your test suite, before including `test.cmake`:"
  "\n set(SUITE_NAME \"Your test suite name here\")"
 )
endif()
unset(SUITE_NAME_LENGTH)

#Adds a function to the test suite
function(define_test dt_TEST_NAME)
 #Validate test name
 string(LENGTH "${dt_TEST_NAME}" dt_TEST_NAME_LENGTH)
 if(dt_TEST_NAME_LENGTH EQUAL 0)
  message(
   FATAL_ERROR
   "test.cmake (define_test): Test name must not be empty!"
  )
 endif()
 unset(dt_TEST_NAME_LENGTH)

 #TODO Fix regex
 #Ensure test name does not contain whitespace
 string(
  REGEX
  MATCH "[^A-Za-z_][^A-Za-z0-9_]*"
  dt_TEST_NAME_INVALID
  "${dt_TEST_NAME}"
 )
 if(dt_TEST_NAME_INVALID)
  message(
   FATAL_ERROR
   "test.cmake (define_test): Test name '${dt_TEST_NAME}' contains illegal "
   "characters and/or begins with an illegal character! Valid characters "
   "include: [A-Za-z0-9_]. Identifiers must start with only characters in the "
   "set: [A-Za-z_]"
  )
 endif()
 unset(dt_TEST_NAME_INVALID)

 #Append test to suite
 list(APPEND ALL_TESTS "${dt_TEST_NAME}")

 #Propagate changes to parent scope
 set(ALL_TESTS "${ALL_TESTS}" PARENT_SCOPE)
endfunction()

#[[
 TODO Internal utility function to print helpful information about failed
 assertions
]]
function(__fail_assertion fa_MESSAGE)
endfunction()

#TODO Simple string-wise equality assertion for tests
function(assert_equals ae_EXPECTED ae_VALUE)
endfunction()

#TODO
function(assert_true at_VALUE)
endfunction()

#TODO
function(assert_false af_VALUE)
endfunction()
