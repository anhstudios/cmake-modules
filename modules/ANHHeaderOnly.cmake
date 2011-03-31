# AddANHHeaderOnlyLibrary is a standardized way to build libraries in the MMOServer
# project. Particularly on windows platforms this manages all the
# machinary to set up a default environment and creating/building/running unit
# unit tests an afterthought for developers.
#

INCLUDE(CMakeMacroParseArguments)

FUNCTION(AddANHHeaderOnly name)
    PARSE_ARGUMENTS(ANHHeader "SOURCES;ADDITIONAL_INCLUDE_DIRS" "" ${ARGN})
    
    LIST(LENGTH SOURCES __source_files_list_length)
	LIST(LENGTH ANHHeader_ADDITIONAL_INCLUDE_DIRS _includes_list_length)
	
	IF(_includes_list_length GREATER 0)
        INCLUDE_DIRECTORIES(${ANHHeader_ADDITIONAL_INCLUDE_DIRS})
    ENDIF()
            
    # Grab all of the source files and all of the unit test files.
    IF(__source_files_list_length EQUAL 0)    
        # load up all of the source and header files for the project
        FILE(GLOB_RECURSE SOURCES *.h)
                    
        FOREACH(__source_file ${SOURCES})
            STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/)((.*/)*)(.*)" "\\2" __source_dir "${__source_file}")
            STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/${__source_dir})(.*)" "\\2" __source_filename "${__source_file}")
            
            STRING(REPLACE "/" "\\\\" __source_group "${__source_dir}")
            SOURCE_GROUP("${__source_group}" FILES ${__source_file})
        ENDFOREACH()
    ELSE()
        FOREACH(__source_file ${SOURCES})
            STRING(REGEX REPLACE "(${CMAKE_CURRENT_SOURCE_DIR}/${__source_dir})(.*)" "\\2" __source_filename "${__source_file}")
        
            STRING(SUBSTRING ${__source_filename} 0 5 __main_check)
            STRING(COMPARE EQUAL "main." "${__main_check}" __is_main)
            IF(__is_main)
                LIST(REMOVE_ITEM SOURCES ${__source_file})
            ENDIF()    
        ENDFOREACH()
    ENDIF()
	# Create the Common library
    ADD_LIBRARY(${name} STATIC ${SOURCES})    
	SET_TARGET_PROPERTIES(${name} PROPERTIES LINKER_LANGUAGE CXX)
ENDFUNCTION()
