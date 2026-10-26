add_executable(fitter_tests test_fitter.cpp)
target_link_libraries(fitter_tests PRIVATE cyrus_vegetation_fitter)
target_compile_features(fitter_tests PRIVATE cxx_std_20)
foreach(fitter_case IN ITEMS
    clear_rest one_sphere positive_control root_inside segment_interior
    width_envelope generation multi_obstacle cancellation work_limits
    malformed_contacts local_conflict frames repeat_immutable away_geometry
    root_modes numeric_admission admission_order)
    add_test(NAME fitter_${fitter_case} COMMAND fitter_tests ${fitter_case})
endforeach()
add_executable(fitter_analytic_tests test_analytic_world.cpp)
target_link_libraries(fitter_analytic_tests PRIVATE cyrus_prototype_contract)
target_compile_features(fitter_analytic_tests PRIVATE cxx_std_20)
if(CYRUS_FITTER_SANITIZERS AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(fitter_analytic_tests PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(fitter_analytic_tests PRIVATE -fsanitize=address,undefined)
endif()
add_test(NAME fitter_analytic_oracle COMMAND fitter_analytic_tests)
