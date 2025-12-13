cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES C CXX)

set(BINARY_NAME "mi_crm")
set(APPLICATION_ID "com.example.mi_crm")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "${ORIGIN}/lib")
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(flutter)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "my_application.h"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)
apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter PkgConfig::GTK)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

auto_assign_icu_data(${BINARY_NAME})

add_dependencies(${BINARY_NAME} flutter_assemble)

install(TARGETS ${BINARY_NAME} BUNDLE DESTINATION "." LIBRARY DESTINATION "lib")
flutter_install_all(${BINARY_NAME})
