project(lighttpd C)

cmake_minimum_required(VERSION 3.7.0 FATAL_ERROR)

# use C11 with CMake >= 3.1
set(CMAKE_C_STANDARD 11)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/scripts/cmake)

include(CTest)

enable_testing()

set(CPACK_PACKAGE_VERSION_MAJOR 1)
set(CPACK_PACKAGE_VERSION_MINOR 4)
set(CPACK_PACKAGE_VERSION_PATCH 65)
set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/COPYING")
set(CPACK_RESOURCE_FILE_README "${CMAKE_SOURCE_DIR}/README")
set(CPACK_PACKAGE_VENDOR "jan@kneschke.de")

set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_IGNORE_FILES "/\\\\.;~$;/_;build/;CMakeFiles/;CMakeCache;gz$;Makefile\\\\.;trace;Testing/;foo;autom4te;cmake_install;CPack;\\\\.pem;ltmain.sh;configure;libtool;/config\\\\.;missing;autogen.sh;install-sh;Dart;aclocal;log$;Makefile$")

set(CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

add_subdirectory(src build)
#add_subdirectory(doc)
add_subdirectory(tests)
