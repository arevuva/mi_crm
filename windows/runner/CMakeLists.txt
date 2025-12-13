cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "mi_crm")
set(APPLICATION_ID "com.example.mi_crm")

set(CMAKE_INSTALL_RPATH "${ORIGIN}/lib")

add_executable(${BINARY_NAME}
  "flutter_window.cpp"
  "flutter_window.h"
  "main.cpp"
  "utils.cpp"
  "utils.h"
  "win32_window.cpp"
  "win32_window.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/../flutter/generated_plugin_registrant.cc"
)

target_compile_definitions(${BINARY_NAME} PRIVATE "UNICODE" "_UNICODE" "NOMINMAX" "WIN32_LEAN_AND_MEAN")
set_target_properties(${BINARY_NAME} PROPERTIES
  WIN32_EXECUTABLE TRUE
  VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIG>")

apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../flutter")

add_dependencies(${BINARY_NAME} flutter_assemble)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION .)
