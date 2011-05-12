find_path(MYSQLCONNECTORCPP_INCLUDE_DIR cppconn/connection.h
    HINTS
        $ENV{MysqlConnectorCpp_ROOT}
    PATH_SUFFIXES include
    PATHS
        ${MysqlConnectorCpp_ROOT}
        ${MysqlConnectorCpp_INCLUDEDIR}
)

find_path(MYSQLCONNECTORCPP_DRIVER_INCLUDE_DIR mysql_driver.h
    HINTS
        $ENV{MysqlConnectorCpp_ROOT}
    PATH_SUFFIXES include include/driver driver
    PATHS
        ${MysqlConnectorCpp_ROOT}
        ${MysqlConnectorCpp_INCLUDEDIR}
)

find_library(MYSQLCONNECTORCPP_LIBRARY 
    NAMES mysqlcppconn
    PATH_SUFFIXES lib driver driver/Debug driver/Release lib/Debug lib/Release
    HINTS
        $ENV{MysqlConnectorCpp_ROOT}
        ${MysqlConnectorCpp_ROOT}
        ${MysqlConnectorCpp_LIBRARYDIR}
)

# handle the QUIETLY and REQUIRED arguments and set OPENAL_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MysqlConnectorCpp DEFAULT_MSG MYSQLCONNECTORCPP_LIBRARY MYSQLCONNECTORCPP_INCLUDE_DIR MYSQLCONNECTORCPP_DRIVER_INCLUDE_DIR)

mark_as_advanced(MYSQLCONNECTORCPP_LIBRARY MYSQLCONNECTORCPP_INCLUDE_DIR MYSQLCONNECTORCPP_DRIVER_INCLUDE_DIR)

string(COMPARE NOTEQUAL MYSQLCONNECTORCPP_INCLUDE_DIR MYSQLCONNECTORCPP_DRIVER_INCLUDE_DIR MYSQLCONNECTORCPP_INCLUDE_DIR_MISMATCH)
if(MYSQLCONNECTORCPP_INCLUDE_DIR_MISMATCH)
    SET(MYSQLCONNECTORCPP_INCLUDE_DIRS ${MYSQLCONNECTORCPP_INCLUDE_DIR} ${MYSQLCONNECTORCPP_DRIVER_INCLUDE_DIR})
else()
    SET(MYSQLCONNECTORCPP_INCLUDE_DIRS ${MYSQLCONNECTORCPP_INCLUDE_DIR})
endif()

