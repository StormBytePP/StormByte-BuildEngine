
## add_tool(srcdir)
# Description:
#   Add and configure a build subdirectory for a third-party tool.
#
# Parameters:
#   srcdir - Relative path to the tool's source directory (relative to
#            this helpers.cmake file's directory).
#
# Behavior:
#   - Prints a status message: "Configuring <srcdir>".
#   - Calls `add_subdirectory(<srcdir>)` to include the tool in the build.
#   - Includes "${CMAKE_CURRENT_LIST_DIR}/${srcdir}/propagate_vars.cmake"
#     to import or propagate variables that the tool defines for the
#     surrounding bootstrap build.
#
# Notes:
#   - `srcdir` should contain a `CMakeLists.txt` and a
#     `propagate_vars.cmake` file; this macro does not verify their
#     existence before calling `add_subdirectory` and `include`.
#   - Intended for use in the ffmpeg bootstrap helpers to register
#     bundled plugin/tool directories.
#
# Example:
#   add_tool(myplugin)  # configures the 'myplugin' folder located at
#                      # ${CMAKE_CURRENT_LIST_DIR}/myplugin
macro(add_tool srcdir)
	message(STATUS "Configuring ${srcdir}")
	add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/${srcdir}")
	include("${CMAKE_CURRENT_LIST_DIR}/${srcdir}/propagate_vars.cmake")
endmacro()