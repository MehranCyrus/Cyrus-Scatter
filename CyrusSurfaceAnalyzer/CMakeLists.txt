cmake_minimum_required(VERSION 3.24)
project(CyrusSurfaceAnalyzer VERSION 0.5 LANGUAGES CXX)
add_library(analyzer STATIC src/analyzer.cpp src/elements.cpp)
target_compile_features(analyzer PUBLIC cxx_std_17)
target_include_directories(analyzer PUBLIC src)
enable_testing()
add_executable(analyzer_tests tests/test.cpp)
target_link_libraries(analyzer_tests PRIVATE analyzer)
add_test(NAME analyzer_core COMMAND analyzer_tests)
set(MAXSDK_ROOT "C:/Program Files/Autodesk/3ds Max 2026 SDK/maxsdk" CACHE PATH "SDK")
add_library(CyrusSurfaceAnalyzer MODULE src/bridge.cpp)
target_link_libraries(CyrusSurfaceAnalyzer PRIVATE analyzer core geom mesh maxutil Maxscrpt)
target_link_directories(CyrusSurfaceAnalyzer PRIVATE "${MAXSDK_ROOT}/lib/x64/Release")
target_include_directories(CyrusSurfaceAnalyzer SYSTEM PRIVATE "${MAXSDK_ROOT}/include")
target_compile_definitions(CyrusSurfaceAnalyzer PRIVATE UNICODE _UNICODE NOMINMAX)
set_target_properties(CyrusSurfaceAnalyzer PROPERTIES SUFFIX ".dlx")



