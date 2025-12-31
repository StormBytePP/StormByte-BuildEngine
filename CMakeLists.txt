message(STATUS "Bootstrapping StormByte-BuildEngine (https://github.com/StormBytePP/StormByte-BuildEngine)")

# Initialize directory variables
include(init_vars.cmake)

# Include helpers
include(${CMAKE_CURRENT_LIST_DIR}/helpers.cmake)

# Configure environment components and propagate variables
add_subdirectory(env)
set(ENV_RUNNER ${ENV_RUNNER} PARENT_SCOPE)
set(ENV_RUNNER_SILENT ${ENV_RUNNER_SILENT} PARENT_SCOPE)

# Configure build tools and propagate variables
add_subdirectory(tools)
set(ENV_CMAKE_COMMAND ${ENV_CMAKE_COMMAND} PARENT_SCOPE)
set(ENV_GIT_COMMAND ${ENV_GIT_COMMAND} PARENT_SCOPE)
set(ENV_MESON_COMMAND ${ENV_MESON_COMMAND} PARENT_SCOPE)
set(ENV_NINJA_COMMAND ${ENV_NINJA_COMMAND} PARENT_SCOPE)
if(DEFINED PKG_CONFIG)
	set(PKG_CONFIG ${PKG_CONFIG} PARENT_SCOPE)
endif()

# Propagate env variables to parent scope
include(propagate_vars.cmake)
