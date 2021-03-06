cmake_minimum_required(VERSION 2.8)
project(MEX)

set(CMAKE_MODULE_PATH
  ${CMAKE_MODULE_PATH}
  ${PROJECT_SOURCE_DIR}/cmake)

if(CMAKE_VERSION VERSION_LESS "3.3") 
  message(WARNING "CMake version less than 3.3\n"
    "using local FindMatlab module extracted from v3.3")
  # Where we keep FindMatlab module
  set(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    ${PROJECT_SOURCE_DIR}/cmake-compat)
endif()

find_package(Matlab REQUIRED MAIN_PROGRAM)
if(NOT Matlab_FOUND)
  message(FATAL_ERROR "MATLAB not found.")
else()
  message("MATLAB found.")
endif()
include_directories(
  ${Matlab_INCLUDE_DIRS}
)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin/")

# Assuming gcc for now
# -ffast-math is for some reason not working with gcc
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -std=c99 -Wall -O3 -march=native -fopenmp")

# Add modules with MEX to be built
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_direct")
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_Stokes_direct/mex")
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_fast_gridding")
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_Stokes/mex")  
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_Stresslet/mex")
add_subdirectory("${PROJECT_SOURCE_DIR}/SE_Rotlet/mex")
add_subdirectory("${PROJECT_SOURCE_DIR}/SE2P_Stokes/mex")

# Enable running Matlab test suite through ctest
enable_testing()
matlab_add_unit_test(
  NAME matlab_test_suite
  UNITTEST_FILE "${PROJECT_SOURCE_DIR}/run_unit_tests.m"
  UNITTEST_PRECOMMAND "cd ${PROJECT_SOURCE_DIR}"
  NO_UNITTEST_FRAMEWORK
)
