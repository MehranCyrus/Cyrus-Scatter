# Owner A module. The coordinator's root scaffold and frozen header are unchanged.
cmake_minimum_required(VERSION 3.20)
if(NOT TARGET cyrus_prototype_contract)
    message(FATAL_ERROR "Configure the frozen starter directory; cyrus_prototype_contract is required.")
endif()
if(TARGET Jolt)
    message(FATAL_ERROR "Cyrus collision will not reuse an unverified pre-existing Jolt target. Use the isolated handoff scaffold for this standalone profile.")
endif()
set(CYRUS_COLLISION_JOLT_SOURCE_ROOT "" CACHE PATH
    "Offline unchanged Jolt source root from the exact 1b2e77e3 archive; empty fetches with SHA-256 enforcement")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/VerifyJoltSource.cmake")

if(CYRUS_COLLISION_JOLT_SOURCE_ROOT)
    get_filename_component(cyrus_collision_jolt_source "${CYRUS_COLLISION_JOLT_SOURCE_ROOT}" REALPATH)
else()
    include(FetchContent)
    if(POLICY CMP0135)
        cmake_policy(SET CMP0135 NEW)
    endif()
    # A deliberately absent SOURCE_SUBDIR prevents automatic configuration;
    # the verified source is added below with the explicit CPU profile.
    FetchContent_Declare(cyrus_collision_jolt
        URL "https://codeload.github.com/jrouwe/JoltPhysics/tar.gz/1b2e77e3c6c09709e5edc79dc208459b8ff32051"
        URL_HASH "SHA256=6bb6d626b7b70096cd07f1b25c0c223df035ab6386885f07f77baa88ae7d3998"
        SOURCE_SUBDIR "__cyrus_verified_source_only__")
    FetchContent_MakeAvailable(cyrus_collision_jolt)
    set(cyrus_collision_jolt_source "${cyrus_collision_jolt_SOURCE_DIR}")
endif()
cyrus_collision_verify_jolt_source("${cyrus_collision_jolt_source}"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/jolt-source.sha256")

# Function scope isolates upstream option variables from sibling modules.
# CMake >=3.20 sets CMP0077 NEW, so option() respects these normal variables.
function(cyrus_collision_add_jolt source_root)
    foreach(option_name IN ITEMS DOUBLE_PRECISION USE_ASSERTS CROSS_PLATFORM_DETERMINISTIC
            CPP_EXCEPTIONS_ENABLED CPP_RTTI_ENABLED)
        set(${option_name} ON)
    endforeach()
    foreach(option_name IN ITEMS JPH_BUILD_SHARED_LIBS INTERPROCEDURAL_OPTIMIZATION
            GENERATE_DEBUG_SYMBOLS OVERRIDE_CXX_FLAGS FLOATING_POINT_EXCEPTIONS_ENABLED
            ENABLE_ALL_WARNINGS ENABLE_INSTALL ENABLE_OBJECT_STREAM
            DEBUG_RENDERER_IN_DEBUG_AND_RELEASE DEBUG_RENDERER_IN_DISTRIBUTION
            PROFILER_IN_DEBUG_AND_RELEASE PROFILER_IN_DISTRIBUTION JPH_USE_EXTERNAL_PROFILE
            TRACK_BROADPHASE_STATS TRACK_NARROWPHASE_STATS JPH_TRACK_SIMULATION_STATS
            USE_SSE4_1 USE_SSE4_2 USE_AVX USE_AVX2 USE_AVX512 USE_LZCNT USE_TZCNT
            USE_F16C USE_FMADD USE_WASM_SIMD JPH_USE_WASM64
            JPH_USE_DX12 JPH_USE_VK JPH_USE_MTL JPH_USE_CPU_COMPUTE
            DISABLE_CUSTOM_ALLOCATOR USE_STATIC_MSVC_RUNTIME_LIBRARY)
        set(${option_name} OFF)
    endforeach()
    set(OBJECT_LAYER_BITS 16)
    add_subdirectory("${source_root}/Build" "${CMAKE_CURRENT_BINARY_DIR}/jolt" EXCLUDE_FROM_ALL)
    # Upstream Xcode sets SSE4.2 unconditionally. Override the target property
    # for this profile without patching upstream files.
    if(XCODE)
        set_property(TARGET Jolt PROPERTY XCODE_ATTRIBUTE_OTHER_CPLUSPLUSFLAGS[arch=x86_64] "$(inherited) -msse2 -mfpmath=sse")
    endif()
    # Keep this numeric profile explicit even if parent optimization flags
    # include fast-math. Higher inherited ISA flags are rejected by the private
    # generated header rather than silently claiming an SSE2 build.
    if(MSVC)
        target_compile_options(Jolt PRIVATE /fp:precise)
    else()
        target_compile_options(Jolt PRIVATE -fno-fast-math -ffp-contract=off)
    endif()
    set_property(TARGET Jolt PROPERTY CYRUS_COLLISION_VERIFIED_PIN "1b2e77e3c6c09709e5edc79dc208459b8ff32051")
endfunction()
cyrus_collision_add_jolt("${cyrus_collision_jolt_source}")

set(CYRUS_COLLISION_PROFILE_TEXT
    "DOUBLE_PRECISION=ON; USE_ASSERTS=ON; CROSS_PLATFORM_DETERMINISTIC=ON; CPP_EXCEPTIONS_ENABLED=ON; CPP_RTTI_ENABLED=ON; x86_SSE2_baseline=ON; SSE4/AVX/AVX2/AVX512/LZCNT/TZCNT/F16C/FMA=OFF; compute_DX12/Vulkan/Metal/CPU=OFF; OBJECT_LAYER_BITS=16; OBJECT_STREAM=OFF; CUSTOM_ALLOCATOR=ON; FLOATING_POINT_EXCEPTIONS_ENABLED=OFF; debug_renderer/profiler/IPO=OFF; static_Jolt=ON; FP_contraction=OFF; MSVC_fp=precise; MSVC_runtime=inherited")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/collision_build_profile.hpp.in"
    "${CMAKE_CURRENT_BINARY_DIR}/collision_build_profile.hpp.configured" @ONLY)
file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>/collision_build_profile.hpp"
    INPUT "${CMAKE_CURRENT_BINARY_DIR}/collision_build_profile.hpp.configured")

add_library(cyrus_vegetation_collision STATIC
    src/collision_world.cpp
    src/jolt_runtime.cpp
    src/primitive_geometry.cpp)
target_compile_features(cyrus_vegetation_collision PUBLIC cxx_std_20)
target_link_libraries(cyrus_vegetation_collision PUBLIC cyrus_prototype_contract PRIVATE Jolt)
target_include_directories(cyrus_vegetation_collision PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>")
if(MSVC)
    target_compile_options(cyrus_vegetation_collision PRIVATE /EHsc /fp:precise /W4)
else()
    target_compile_options(cyrus_vegetation_collision PRIVATE -fexceptions -fno-fast-math -ffp-contract=off -Wall -Wextra -Wpedantic)
endif()

file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/collision-build-options-$<CONFIG>.txt" CONTENT
    "Jolt commit: 1b2e77e3c6c09709e5edc79dc208459b8ff32051\nArchive SHA256: 6bb6d626b7b70096cd07f1b25c0c223df035ab6386885f07f77baa88ae7d3998\nCompiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}\nSystem: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}\nConfig: $<CONFIG>\nProfile: ${CYRUS_COLLISION_PROFILE_TEXT}\nInherited CXX flags: ${CMAKE_CXX_FLAGS}\nJolt direct compile options: $<TARGET_PROPERTY:Jolt,COMPILE_OPTIONS>\nJolt public compile options: $<TARGET_PROPERTY:Jolt,INTERFACE_COMPILE_OPTIONS>\nJolt public definitions: $<TARGET_PROPERTY:Jolt,INTERFACE_COMPILE_DEFINITIONS>\nAdapter direct options: $<TARGET_PROPERTY:cyrus_vegetation_collision,COMPILE_OPTIONS>\n")

if(BUILD_TESTING)
    add_executable(cyrus_collision_tests tests/collision_tests.cpp)
    target_compile_features(cyrus_collision_tests PRIVATE cxx_std_20)
    target_link_libraries(cyrus_collision_tests PRIVATE cyrus_vegetation_collision)
    target_include_directories(cyrus_collision_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
    foreach(case IN ITEMS identity_empty point_sphere point_box capsule_sphere capsule_box
            capsule_axes two_obstacles invalid_inputs limits cancellation snapshot lifetime
            scale_profile repeatability native_observations)
        add_test(NAME "collision_${case}" COMMAND cyrus_collision_tests "${case}")
        set_tests_properties("collision_${case}" PROPERTIES TIMEOUT 30)
    endforeach()
endif()
