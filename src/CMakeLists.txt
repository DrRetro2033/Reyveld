cmake_minimum_required(VERSION 3.10)

project(duktape_dart VERSION 0.1 LANGUAGES C)

add_library(duktape_dart SHARED
    duktape-2.7.0/src/duktape.c  # Modify with the path to the Duktape source file
)

set_target_properties(duktape_dart PROPERTIES
    PUBLIC_HEADER duktape-2.7.0/src/duktape.h
    OUTPUT_NAME "duktape"
)

if(WIN32)
    set_target_properties(duktape_dart PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

target_compile_definitions(duktape_dart PUBLIC DART_SHARED_LIB)
