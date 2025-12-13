cmake_minimum_required(VERSION 3.10)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

if(NOT EXISTS "${EPHEMERAL_DIR}/generated_config.cmake")
  message(FATAL_ERROR "The Flutter tooling was not detected. Run `flutter build linux` or `flutter run` to generate the platform files.")
endif()

include("${EPHEMERAL_DIR}/generated_config.cmake")

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
include("${FLUTTER_MANAGED_DIR}/generated_plugins.cmake")

add_custom_target(flutter_assemble DEPENDS ${FLUTTER_ASSEMBLY_OUTPUTS})
add_custom_command(OUTPUT ${FLUTTER_ASSEMBLY_OUTPUTS}
  COMMAND ${CMAKE_COMMAND} -E env ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh" linux-x64 ${FLUTTER_TOOL_ARGS}
  VERBATIM)

add_library(flutter INTERFACE)
add_dependencies(flutter flutter_assemble)

target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)

target_link_libraries(flutter INTERFACE
  "${FLUTTER_EPHEMERAL_LIB_DIR}/libflutter_linux_gtk.so"
)
