cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")
if(NOT EXISTS "${EPHEMERAL_DIR}")
  file(MAKE_DIRECTORY "${EPHEMERAL_DIR}")
endif()

include("${EPHEMERAL_DIR}/generated_config.cmake" OPTIONAL)
include("${CMAKE_CURRENT_SOURCE_DIR}/generated_plugins.cmake" OPTIONAL)

if(NOT DEFINED FLUTTER_ASSEMBLY_OUTPUTS OR "${FLUTTER_ASSEMBLY_OUTPUTS}" STREQUAL "")
  set(FLUTTER_ASSEMBLY_OUTPUTS "${EPHEMERAL_DIR}/flutter_assemble.stamp")
endif()
if(NOT DEFINED FLUTTER_TOOL_ENVIRONMENT)
  set(FLUTTER_TOOL_ENVIRONMENT "")
endif()

if(DEFINED FLUTTER_ROOT AND EXISTS "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat")
  add_custom_target(flutter_assemble DEPENDS ${FLUTTER_ASSEMBLY_OUTPUTS})
  add_custom_command(OUTPUT ${FLUTTER_ASSEMBLY_OUTPUTS}
    COMMAND ${CMAKE_COMMAND} -E env ${FLUTTER_TOOL_ENVIRONMENT}
      "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.bat" windows-x64 ${FLUTTER_TOOL_ARGS}
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
  "${EPHEMERAL_DIR}/cpp_client_wrapper/include"
  "${EPHEMERAL_DIR}"
)

target_link_libraries(flutter INTERFACE
  "${FLUTTER_EPHEMERAL_DIR}/flutter_windows.dll"
  shlwapi
  version
)

if(NOT COMMAND apply_standard_settings)
  function(apply_standard_settings TARGET)
    set_target_properties(${TARGET} PROPERTIES
      CXX_STANDARD 17
      CXX_STANDARD_REQUIRED YES
      CXX_EXTENSIONS NO)
  endfunction()
endif()
