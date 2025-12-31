# Initialize variables
include("${CMAKE_CURRENT_LIST_DIR}/init_vars.cmake")

# Include our helpers
include("${CMAKE_CURRENT_LIST_DIR}/helpers.cmake")

add_tool(cmake)
add_tool(git)
add_tool(meson)
add_tool(ninja)
add_tool(pkgconf)

include("${CMAKE_CURRENT_LIST_DIR}/propagate_vars.cmake")