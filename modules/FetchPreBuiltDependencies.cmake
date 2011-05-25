set(VENDOR_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/vendor")
set(vendor_libraries vendor)

ExternalProject_Add(vendor
	DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}
	URL http://s3.amazonaws.com/github/downloads/anhstudios/swganh/swganh-deps-${swganh_VERSION_MAJOR}.${swganh_VERSION_MINOR}.${swganh_VERSION_PATCH}-win.tar.gz
	URL_MD5 d51d4ebb6b9cb0b53b7e0351d2cc5161
	SOURCE_DIR ${VENDOR_PREFIX}
	UPDATE_COMMAND ""
	PATCH_COMMAND ""
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ""
	INSTALL_COMMAND ""
)
