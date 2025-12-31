message(STATUS "\tSetting up environment...")

# Set up environment runner scripts
include(init_vars.cmake)

# Propagate environment variables to parent scope
include(propagate_vars.cmake)