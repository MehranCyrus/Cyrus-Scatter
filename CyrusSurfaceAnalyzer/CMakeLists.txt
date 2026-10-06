cmake_minimum_required(VERSION 3.24)
project(CyrusSurfaceAnalyzer VERSION 0.5 LANGUAGES CXX)
option(CYRUS_ANALYZER_BUILD_MAX "Build the 3ds Max extension" ON)
if(CYRUS_ANALYZER_BUILD_MAX)
  include("${CMAKE_CURRENT_LIST_DIR}/../cmake/CyrusMaxSDK.cmake")
endif()
add_library(analyzer STATIC src/analyzer.cpp src/elements.cpp)
target_compile_features(analyzer PUBLIC cxx_std_17)
target_include_directories(analyzer PUBLIC src)
enable_testing()
add_executable(analyzer_tests tests/test.cpp)
target_link_libraries(analyzer_tests PRIVATE analyzer)
add_test(NAME analyzer_core COMMAND analyzer_tests)
if(CYRUS_ANALYZER_BUILD_MAX)
add_library(CyrusSurfaceAnalyzer MODULE src/bridge.cpp ../AminScatter/src/input_validity.cpp)
# The same Max-thread validity query is compiled with a distinct primitive name;
# Analyzer remains usable on its own, without loading Scatter's DLL.
target_compile_definitions(CyrusSurfaceAnalyzer PRIVATE CYRUS_ANALYZER_INPUT_VALIDITY=1)
target_link_libraries(CyrusSurfaceAnalyzer PRIVATE analyzer core geom mesh maxutil Maxscrpt paramblk2)
cyrus_max_target(CyrusSurfaceAnalyzer)
set_target_properties(CyrusSurfaceAnalyzer PROPERTIES SUFFIX ".dlx")
endif()



