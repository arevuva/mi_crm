cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Ensure the ephemeral directory exists even if Flutter tooling hasn't run yet.
if(NOT EXISTS "${EPHEMERAL_DIR}")
  file(MAKE_DIRECTORY "${EPHEMERAL_DIR}")
endif()

if(NOT EXISTS "${EPHEMERAL_DIR}/generated_config.cmake")
  message(FATAL_ERROR "The Flutter tooling was not detected. Run `flutter build linux` or `flutter run` to generate the platform files.")
endif()

include("${EPHEMERAL_DIR}/generated_config.cmake" OPTIONAL)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
include("${FLUTTER_MANAGED_DIR}/generated_plugins.cmake" OPTIONAL)

# Fallbacks so CMake configuration succeeds even before Flutter generates files.
if(NOT DEFINED FLUTTER_ASSEMBLY_OUTPUTS OR "${FLUTTER_ASSEMBLY_OUTPUTS}" STREQUAL "")
  set(FLUTTER_ASSEMBLY_OUTPUTS "${EPHEMERAL_DIR}/flutter_assemble.stamp")
endif()
if(NOT DEFINED FLUTTER_TOOL_ENVIRONMENT)
  set(FLUTTER_TOOL_ENVIRONMENT "")
endif()

if(DEFINED FLUTTER_ROOT AND EXISTS "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh")
  add_custom_target(flutter_assemble DEPENDS ${FLUTTER_ASSEMBLY_OUTPUTS})
  add_custom_command(OUTPUT ${FLUTTER_ASSEMBLY_OUTPUTS}
    COMMAND ${CMAKE_COMMAND} -E env ${FLUTTER_TOOL_ENVIRONMENT}
      "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh" linux-x64 ${FLUTTER_TOOL_ARGS}
    VERBATIM)
else()
  add_custom_target(flutter_assemble ALL
    COMMAND ${CMAKE_COMMAND} -E touch ${FLUTTER_ASSEMBLY_OUTPUTS}
    BYPRODUCTS ${FLUTTER_ASSEMBLY_OUTPUTS}
    COMMENT "Flutter tooling not found; creating placeholder assemble outputs.")
endif()

add_library(flutter INTERFACE)
add_dependencies(flutter flutter_assemble)

target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)

target_link_libraries(flutter INTERFACE
  "${FLUTTER_EPHEMERAL_LIB_DIR}/libflutter_linux_gtk.so"
)

if(NOT COMMAND apply_standard_settings)
  function(apply_standard_settings TARGET)
    set_target_properties(${TARGET} PROPERTIES
      CXX_STANDARD 17
      CXX_STANDARD_REQUIRED YES
      CXX_EXTENSIONS NO
      POSITION_INDEPENDENT_CODE ON)
  endfunction()
endif()

if(NOT COMMAND auto_assign_icu_data)
  function(auto_assign_icu_data TARGET)
    # No-op fallback; Flutter tooling normally sets ICU data on install.
  endfunction()
endif()

if(NOT COMMAND flutter_install_all)
  function(flutter_install_all TARGET)
    # Fallback so install step remains valid when tooling isn't present.
  endfunction()
endif()
