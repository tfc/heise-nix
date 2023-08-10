cmake_minimum_required(VERSION 3.26)
project(hello-cpp VERSION 1.0 LANGUAGES CXX)

find_package(Boost 1.79)

add_executable(hello-cpp main.cpp)
target_link_libraries(hello-cpp PRIVATE Boost::boost)

install(TARGETS hello-cpp DESTINATION bin)
