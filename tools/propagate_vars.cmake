set(BUILDSYSTEM_TOOLS_SRC_DIR "${BUILDSYSTEM_TOOLS_SRC_DIR}" PARENT_SCOPE)
set(BUILDSYSTEM_TOOLS_BIN_DIR "${BUILDSYSTEM_TOOLS_BIN_DIR}" PARENT_SCOPE)

include("${CMAKE_CURRENT_LIST_DIR}/cmake/propagate_vars.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/git/propagate_vars.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/meson/propagate_vars.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ninja/propagate_vars.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/pkgconf/propagate_vars.cmake")