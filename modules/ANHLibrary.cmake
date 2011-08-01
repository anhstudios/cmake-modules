# AddMMOServerLibrary is a standardized way to build libraries in the MMOServer
# project. Particularly on windows platforms this manages all the
# machinary to set up a default environment and creating/building/running unit
# unit tests an afterthought for developers.
#
# Function Definition:
#
# AddANHLibrary(library_name
#     DEPENDS [ARGS] [args1...]           	     # Dependencies on other MMOServer projects
#     ADDITIONAL_INCLUDE_DIRS [ARGS] [args1...]  # Additional directories to search for includes
#     ADDITIONAL_SOURCE_DIRS [ARGS] [args1...]   # Additional directories to search for files to include in the project
#
#
########################
# Simple Example Usage:
########################
#
# include(ANHLibrary)
# 
# AddANHLibrary(Common
#     MMOSERVER_DEPS 
#         Utils 
# )
#
#
#########################
# Complex Example Usage:
#########################
# include(ANHLibrary)
#
# AddANHLibrary(ScriptEngine
#     DEPENDS 
#         Utils
#         Common
#     SOURCES # disables source lookup and uses this list
#         ${SOURCES}
#     TEST_SOURCES # when source lookups are disabled use these tests
#         ${TEST_SOURCES}
#     ADDITIONAL_SOURCE_DIRS
#         ${CMAKE_CURRENT_SOURCE_DIR}/glue_files
#     ADDITIONAL_INCLUDE_DIRS
#         ${LUA_INCLUDE_DIR} 
#         ${NOISE_INCLUDE_DIR} 
#         ${TOLUAPP_INCLUDE_DIR}
#     DEBUG_LIBRARIES
#         ${LUA_LIBRARY_DEBUG}
#         ${NOISE_LIBRARY_DEBUG}
#         ${TOLUAPP_LIBRARY_DEBUG}
#     OPTIMIZED_LIBRARIES
#         ${LUA_LIBRARY_RELEASE}
#         ${NOISE_LIBRARY_RELEASE}
#         ${TOLUAPP_LIBRARY_RELEASE}
# )
#

INCLUDE(CMakeMacroParseArguments)

FUNCTION(AddANHLibrary name)
    PARSE_ARGUMENTS(ANHLIB "DEPENDS;SOURCES;HEADERS;TEST_SOURCES;ADDITIONAL_LINK_DIRS;ADDITIONAL_INCLUDE_DIRS;ADDITIONAL_LIBRARY_DIRS;ADDITIONAL_SOURCE_DIRS;DEBUG_LIBRARIES;OPTIMIZED_LIBRARIES" "" ${ARGN})
    
    LIST(LENGTH ANHLIB_SOURCES __source_files_list_length)
    LIST(LENGTH ANHLIB_DEBUG_LIBRARIES _debug_list_length)
    LIST(LENGTH ANHLIB_OPTIMIZED_LIBRARIES _optimized_list_length)
    LIST(LENGTH ANHLIB_DEPENDS _project_deps_list_length)
    LIST(LENGTH ANHLIB_ADDITIONAL_INCLUDE_DIRS _includes_list_length)
    LIST(LENGTH ANHLIB_ADDITIONAL_LIBRARY_DIRS _librarydirs_list_length)
    LIST(LENGTH ANHLIB_ADDITIONAL_SOURCE_DIRS _sources_list_length)
            
    # Grab all of the source files and all of the unit test files.
    IF(__source_files_list_length EQUAL 0)    
        # load up all of the source and header files for the project
        FILE(GLOB_RECURSE SOURCES *.cc *.cpp *.h)
        FILE(GLOB_RECURSE HEADERS *.h)
        FILE(GLOB_RECURSE TEST_SOURCES *_unittest.cc *_unittest.cpp mock_*.h)
            
        FOREACH(__source_file ${SOURCES})
            STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/)((.*/)*)(.*)" "\\2" __source_dir "${__source_file}")
            STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/${__source_dir})(.*)" "\\2" __source_filename "${__source_file}")
            
            STRING(REPLACE "/" "\\\\" __source_group "${__source_dir}")
            SOURCE_GROUP("${__source_group}" FILES ${__source_file})
        ENDFOREACH()
    ELSE()
        set(SOURCES ${ANHLIB_SOURCES})
        set(TEST_SOURCES ${ANHLIB_TEST_SOURCES})
        set(HEADERS ${ANHLIB_HEADERS})
    ENDIF()
    
    FOREACH(__source_file ${SOURCES})
        STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/)((.*/)*)(.*)" "\\2" __source_dir "${__source_file}")
        STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/${__source_dir})(.*)" "\\2" __source_filename "${__source_file}")
        
        STRING(REPLACE "/" "\\\\" __source_group "${__source_dir}")
        SOURCE_GROUP("${__source_group}" FILES ${__source_file})
    ENDFOREACH()
        
    LIST(LENGTH TEST_SOURCES _tests_list_length)    
    IF(_tests_list_length GREATER 0)
        LIST(REMOVE_ITEM SOURCES ${TEST_SOURCES}) # Remove the unit tests from the sources list. 
    ENDIF()
    
    # get the number of .cc .cpp files
    set(_tmp ${SOURCES})
    LIST(REMOVE_ITEM _tmp ${HEADERS})
    LIST(LENGTH _tmp _sources_list_length)
        
    IF(_includes_list_length GREATER 0)
        INCLUDE_DIRECTORIES(${ANHLIB_ADDITIONAL_INCLUDE_DIRS})
    ENDIF()
        
    IF(_librarydirs_list_length GREATER 0)
        LINK_DIRECTORIES(${ANHLIB_ADDITIONAL_LIBRARY_DIRS})
    ENDIF()
    
    # Create the Common library
    ADD_LIBRARY(${name} STATIC ${SOURCES})    
	SET_TARGET_PROPERTIES(${name} PROPERTIES LINKER_LANGUAGE CXX)
    
    IF(_project_deps_list_length GREATER 0)
        ADD_DEPENDENCIES(${name} ${ANHLIB_DEPENDS})
    ENDIF()

    IF(_tests_list_length GREATER 0)
        # Create an executable for the test and link it to gtest and anh
        INCLUDE_DIRECTORIES(${GTEST_INCLUDE_DIRS} ${GMOCK_INCLUDE_DIR})
    
        ADD_EXECUTABLE(${name}_tests ${TEST_SOURCES})
        
        # only link to the library if their are sources (header only libs 
        # don't generate binaries)
        if(_sources_list_length GREATER 0)
            TARGET_LINK_LIBRARIES(${name}_tests
                ${name}
            )
        endif()
        
        TARGET_LINK_LIBRARIES(${name}_tests 
            ${ANHLIB_DEPENDS}
            ${GTEST_BOTH_LIBRARIES}
            ${GMOCK_LIBRARIES})
        add_dependencies(${name}_tests DEPS)
                            
        IF(_project_deps_list_length GREATER 0)
            ADD_DEPENDENCIES(${name}_tests ${ANHLIB_DEPENDS})
            ADD_DEPENDENCIES(${name}_tests DEPS)
        ENDIF()
    
        IF(_debug_list_length GREATER 0)
            FOREACH(debug_library ${ANHLIB_DEBUG_LIBRARIES})
                if (NOT ${debug_library} MATCHES ".*NOTFOUND")
                    TARGET_LINK_LIBRARIES(${name}_tests debug ${debug_library})                    
                endif()
            ENDFOREACH()
        ENDIF()
    
        IF(_optimized_list_length GREATER 0)
            FOREACH(optimized_library ${ANHLIB_OPTIMIZED_LIBRARIES})
                if (NOT ${optimized_library} MATCHES ".*NOTFOUND")
                    TARGET_LINK_LIBRARIES(${name}_tests optimized ${optimized_library})                    
                endif()
            ENDFOREACH()
        ENDIF()
        
        IF(WIN32)
            # Set the default output directory for binaries for convenience.
            set(RUNTIME_OUTPUT_BASE_DIRECTORY "${PROJECT_BINARY_DIR}/../..")
            
            SET_TARGET_PROPERTIES(${name}_tests PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${RUNTIME_OUTPUT_BASE_DIRECTORY}/bin")
               
            # Mysql is built with the static runtime but all of our projects and deps
            # use the dynamic runtime, in this instance it's a non-issue so ignore
            # the problem lib.
            SET_TARGET_PROPERTIES(${name}_tests PROPERTIES LINK_FLAGS "/NODEFAULTLIB:LIBCMT")
            SET_TARGET_PROPERTIES(${name}_tests PROPERTIES LINK_FLAGS_RELEASE "/NODEFAULTLIB:LIBCMT /LTCG")
            
            # Create a custom built user configuration so that the "run in debug mode"
            # works without any issues.
    	    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/../tools/windows/user_project.vcxproj.in 
    	        ${CMAKE_CURRENT_BINARY_DIR}/${name}_tests.vcxproj.user @ONLY)
        ENDIF()
        
        IF(ENABLE_TEST_REPORT)
            foreach(configuration Debug Release MinSizeRel RelWithDebInfo)
                ADD_TEST(
                    NAME all_${name}_tests_${configuration}
                    CONFIGURATIONS ${configuration}
                    COMMAND ${name}_tests "--gtest_output=xml:${PROJECT_BINARY_DIR}/reports/$<CONFIGURATION>/"
                    WORKING_DIRECTORY ${RUNTIME_OUTPUT_BASE_DIRECTORY}/bin/${configuration}
                )
            endforeach()
        ENDIF()
    ENDIF()
ENDFUNCTION()
