add_library(cyrus_vegetation_delivery STATIC
    src/evaluator.cpp
    src/validator.cpp
    src/diagnostic_obj.cpp
)
target_link_libraries(cyrus_vegetation_delivery PUBLIC cyrus_prototype_contract)
target_include_directories(cyrus_vegetation_delivery PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_compile_features(cyrus_vegetation_delivery PUBLIC cxx_std_20)
if(MSVC)
    target_compile_options(cyrus_vegetation_delivery PRIVATE /W4 /permissive-)
else()
    target_compile_options(cyrus_vegetation_delivery PRIVATE -Wall -Wextra -Wpedantic -Wconversion -Wshadow)
endif()

if(BUILD_TESTING)
    add_executable(cyrus_vegetation_delivery_tests
        tests/test_main.cpp
    )
    target_link_libraries(cyrus_vegetation_delivery_tests PRIVATE cyrus_vegetation_delivery)
    target_include_directories(cyrus_vegetation_delivery_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
    if(MSVC)
        target_compile_options(cyrus_vegetation_delivery_tests PRIVATE /W4 /permissive-)
    else()
        target_compile_options(cyrus_vegetation_delivery_tests PRIVATE -Wall -Wextra -Wpedantic -Wconversion -Wshadow)
    endif()
    add_test(NAME delivery_evaluator COMMAND cyrus_vegetation_delivery_tests evaluator)
    add_test(NAME delivery_validator COMMAND cyrus_vegetation_delivery_tests validator)
    add_test(NAME delivery_adversarial COMMAND cyrus_vegetation_delivery_tests adversarial)
    add_test(NAME delivery_contract COMMAND cyrus_vegetation_delivery_tests contract)
endif()
