cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

set(BINARY_NAME "mi_crm")
set(APPLICATION_ID "com.example.mi_crm")

set(CMAKE_INSTALL_RPATH "${ORIGIN}/lib")

add_subdirectory(flutter)
add_subdirectory(runner)
