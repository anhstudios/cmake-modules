# AddANHExecutable is a standardized way to build binary executables in
# the ANH project. Particularly on windows platforms this manages all the
# machinary to set up a default environment to make building and then running
# a simple task.
#
# Function Definition:
#
# AddANHExecutable(executable_name
#                        MMOSERVER_DEPS [ARGS] [args1...]           # Dependencies on other MMOServer projects
#                        ADDITIONAL_INCLUDE_DIRS [ARGS] [args1...]  # Additional directories to search for includes
#                        ADDITIONAL_SOURCE_DIRS [ARGS] [args1...]   # Additional directories to search for files to include in the project
#                        DEBUG_LIBRARIES [ARGS] [args1....]         # Additional debug libraries to link the project against
#                        OPTIMIZED_LIBRARIES [ARGS] [args1...])     # Additional optimized libraries to link the project against
#
#
########################
# Simple Example Usage:
########################
#
# include(ANHExecutable)
#
# AddANHExecutable(LoginServer)
#
#
#########################
# Complex Example Usage:
#########################
# include(ANHExecutable)
# 
# AddANHExecutable(ZoneServer
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
INCLUDE(ANHLibrary)
INCLUDE(ANHPythonBinding)

FUNCTION(AddANHExecutable name)
    PARSE_ARGUMENTS(ANHEXE "DEPENDS;SOURCES;TEST_SOURCES;ADDITIONAL_LIBRARY_DIRS;ADDITIONAL_INCLUDE_DIRS;ADDITIONAL_SOURCE_DIRS;DEBUG_LIBRARIES;OPTIMIZED_LIBRARIES" "" ${ARGN})
    
    # get information about the data passed in, helpful for checking if a value
    # has been set or not
    LIST(LENGTH ANHEXE_DEBUG_LIBRARIES _debug_list_length)
    LIST(LENGTH ANHEXE_OPTIMIZED_LIBRARIES _optimized_list_length)
    LIST(LENGTH ANHEXE_DEPENDS _project_deps_list_length)
    LIST(LENGTH ANHEXE_ADDITIONAL_INCLUDE_DIRS _includes_list_length)
	LIST(LENGTH ANHEXE_ADDITIONAL_LIBRARY_DIRS _librarydirs_list_length)
    LIST(LENGTH ANHEXE_ADDITIONAL_SOURCE_DIRS _sources_list_length)
    
    # load up all of the source and header files for the project
    FILE(GLOB_RECURSE SOURCES *.cc *.cpp *.h)   
    FILE(GLOB_RECURSE HEADERS *.h)
    FILE(GLOB_RECURSE TEST_SOURCES *_unittest.cc *_unittest.cpp mock_*.h)
    FILE(GLOB_RECURSE BINDINGS *_binding.cc *_binding.cpp)
        
    FOREACH(__source_file ${SOURCES})
        STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/)((.*/)*)(.*)" "\\2" __source_dir "${__source_file}")
        STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/${__source_dir})(.*)" "\\2" __source_filename "${__source_file}")
        
        STRING(REPLACE "/" "\\\\" __source_group "${__source_dir}")
        SOURCE_GROUP("${__source_group}" FILES ${__source_file})
        
        # check to see if this application specifies an explicit main file
        STRING(SUBSTRING ${__source_filename} 0 5 __main_check)
        STRING(COMPARE EQUAL "main." "${__main_check}" __is_main)
        IF(__is_main)
            SET(MAIN_EXISTS ${__source_file})
        ENDIF()      
    ENDFOREACH()
    
    # if python bindings have been specified generate a module
    LIST(LENGTH BINDINGS _bindings_list_length)
    IF(_bindings_list_length GREATER 0)
        list(REMOVE_ITEM SOURCES ${BINDINGS})
        
        AddANHPythonBinding(${name}_binding
            DEPENDS
                ${ANHEXE_DEPENDS}
            SOURCES
                ${BINDINGS}
            ADDITIONAL_INCLUDE_DIRS
                ${ANHEXE_ADDITIONAL_INCLUDE_DIRS}
            DEBUG_LIBRARIES
                ${ANHEXE_DEBUG_LIBRARIES}
            OPTIMIZED_LIBRARIES
                ${ANHEXE_OPTIMIZED_LIBRARIES}
        )
    ENDIF()
    
    # if unit tests have been specified break out the project into a library to make it testable
    LIST(LENGTH SOURCES _sources_list_length)    
    IF(_sources_list_length GREATER 1)        
        SET(__project_library "lib${name}")
        
        list(REMOVE_ITEM SOURCES ${MAIN_EXISTS})
    
        AddANHLibrary(${__project_library}
            DEPENDS
                ${ANHEXE_DEPENDS}
            SOURCES
                ${SOURCES}
            HEADERS
                ${HEADERS}
            TEST_SOURCES
                ${TEST_SOURCES}
            ADDITIONAL_INCLUDE_DIRS
                ${ANHEXE_ADDITIONAL_INCLUDE_DIRS}
            DEBUG_LIBRARIES
                ${ANHEXE_DEBUG_LIBRARIES}
            OPTIMIZED_LIBRARIES
                ${ANHEXE_OPTIMIZED_LIBRARIES}
        )
    
        set(SOURCES ${MAIN_EXISTS})
    ENDIF()
        
    IF(_includes_list_length GREATER 0)
        INCLUDE_DIRECTORIES(${ANHEXE_ADDITIONAL_INCLUDE_DIRS})
    ENDIF()
    
	IF(_librarydirs_list_length GREATER 0)
        LINK_DIRECTORIES(${ANHEXE_ADDITIONAL_LIBRARY_DIRS})
    ENDIF()
    
    # Create the executable and link to it's library
    ADD_EXECUTABLE(${name} ${SOURCES})
    
    # If a project library was created link to it
    IF(DEFINED __project_library)
        TARGET_LINK_LIBRARIES(${name}
            ${__project_library}
        )
    ENDIF()
    
    IF(_project_deps_list_length GREATER 0)
        TARGET_LINK_LIBRARIES(${name} ${ANHEXE_DEPENDS})
        ADD_DEPENDENCIES(${name} DEPS)
    ENDIF()
    
    IF(_debug_list_length GREATER 0)    
        FOREACH(__library ${ANHEXE_DEBUG_LIBRARIES})
            if (NOT ${__library} MATCHES ".*NOTFOUND")
                TARGET_LINK_LIBRARIES(${name} debug ${__library})
            endif()
        ENDFOREACH()
    ENDIF()
    
    IF(_optimized_list_length GREATER 0)
        FOREACH(__library ${ANHEXE_OPTIMIZED_LIBRARIES})
            if (NOT ${__library} MATCHES ".*NOTFOUND")
                TARGET_LINK_LIBRARIES(${name} optimized ${__library})
            endif()
        ENDFOREACH()
    ENDIF()
    
    IF(WIN32)
        # Set the default output directory for binaries for convenience.
        set(RUNTIME_OUTPUT_BASE_DIRECTORY "${PROJECT_BINARY_DIR}/../..")
            
        # Set the default output directory for binaries for convenience.
        SET_TARGET_PROPERTIES(${name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${RUNTIME_OUTPUT_BASE_DIRECTORY}/bin")
        
        # Mysql is built with the static runtime but all of our projects and deps
        # use the dynamic runtime, in this instance it's a non-issue so ignore
        # the problem lib.
        SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS "/NODEFAULTLIB:LIBCMT")
        
        # Link to some standard windows libs that all projects need.
    	TARGET_LINK_LIBRARIES(${name} "winmm.lib" "ws2_32.lib")
        
        # Create a custom built user configuration so that the "run in debug mode"
        # works without any issues.
    	CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/../tools/windows/user_project.vcxproj.in 
    	    ${CMAKE_CURRENT_BINARY_DIR}/${name}.vcxproj.user @ONLY)
    ELSE()
        # On unix platforms put the built runtimes in the /bin directory.
        INSTALL(TARGETS ${name} RUNTIME DESTINATION bin)
    ENDIF()
ENDFUNCTION()
