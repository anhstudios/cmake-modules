list(APPEND vendor_libraries vendor)

ExternalProject_Add(vendor
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL http://localhost/swganh-deps-win.tar.gz
	URL_MD5 d51d4ebb6b9cb0b53b7e0351d2cc5161
	SOURCE_DIR ${VENDOR_PREFIX}
	UPDATE_COMMAND ""
	PATCH_COMMAND ""
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ""
	INSTALL_COMMAND ""
)

list(APPEND vendor_args
	"-DBOOST_ROOT:PATH=${VENDOR_PREFIX}/boost")
list(APPEND vendor_args
	"-DGlm_ROOT:PATH=${VENDOR_PREFIX}/glm")
list(APPEND vendor_args
	"-DGLog_ROOT:PATH=${VENDOR_PREFIX}/glog")
list(APPEND vendor_args
	"-DGMock_ROOT:PATH=${VENDOR_PREFIX}/gmock")
list(APPEND vendor_args
	"-DGTest_ROOT:PATH=${VENDOR_PREFIX}/gtest")
list(APPEND vendor_args
	"-DMysqlConnectorC_ROOT:PATH=${VENDOR_PREFIX}/mysql-connector-c")
list(APPEND vendor_args
	"-DMysqlConnectorCpp_ROOT:PATH=${VENDOR_PREFIX}/mysql-connector-cpp")
list(APPEND vendor_args
	"-DTBB_INSTALL_DIR:PATH=${VENDOR_PREFIX}/tbb")
list(APPEND vendor_args
	"-DZLib_ROOT:PATH=${VENDOR_PREFIX}/zlib")
