set(BUILDENGINE_ENV_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(BUILDENGINE_SCRIPTS_ENV_DIR "${BUILDENGINE_BIN_DIR}/scripts/env")
if(WIN32)
	# store as a list: interpreter and its first arg, then the script path
	set(ENV_RUNNER cmd "/C" "${BUILDENGINE_SCRIPTS_ENV_DIR}/runner.bat")
	set(ENV_RUNNER_SILENT cmd "/C" "${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.bat")
	# Strings for configure_file substitution (space-separated, portable)
	set(ENV_RUNNER_CMD "cmd /C ${BUILDENGINE_SCRIPTS_ENV_DIR}/runner.bat")
	set(ENV_RUNNER_SILENT_CMD "cmd /C ${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.bat")
	# Create silent runner
	configure_file(
		"${BUILDENGINE_ENV_DIR}/runner_windows_silent.bat.in"
		"${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.bat"
		@ONLY
	)
else()
	# store as a list so that when expanded in COMMAND the interpreter and
	# script become separate tokens instead of a single quoted string.
	set(ENV_RUNNER /bin/sh "${BUILDENGINE_SCRIPTS_ENV_DIR}/runner.sh")
	set(ENV_RUNNER_SILENT /bin/sh "${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.sh")
	# Strings for configure_file substitution (space-separated, portable)
	set(ENV_RUNNER_CMD "/bin/sh ${BUILDENGINE_SCRIPTS_ENV_DIR}/runner.sh")
	set(ENV_RUNNER_SILENT_CMD "/bin/sh ${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.sh")
	# Create silent runner
	configure_file(
		"${BUILDENGINE_ENV_DIR}/runner_linux_silent.sh.in"
		"${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.sh"
		@ONLY
	)
	# Ensure the generated silent runner has execute permissions so it can be
	# invoked directly by execute_process(). Some platforms require the
	# executable bit even when a shebang is present.
	execute_process(
		COMMAND ${CMAKE_COMMAND} -E chmod 0755 "${BUILDENGINE_SCRIPTS_ENV_DIR}/runner_silent.sh"
		RESULT_VARIABLE _chmod_result
		OUTPUT_QUIET
		ERROR_QUIET
	)
endif()

# Prepare ENV_RUNNER for propagation
prepare_command(ENV_RUNNER "${ENV_RUNNER}")

# We create a basic env runner
update_env_runner()