set(BUILDMASTER_ENV_DIR "${CMAKE_CURRENT_LIST_DIR}")
if(NOT BUILDMASTER_CONFIGURED)
	set(BUILDMASTER_SCRIPTS_ENV_DIR "${BUILDMASTER_BINDIR}/scripts/env")
	if(WIN32)
		# store as a list: interpreter and its first arg, then the script path
		set(ENV_RUNNER cmd "/C" "${BUILDMASTER_SCRIPTS_ENV_DIR}/runner.bat")
		set(ENV_RUNNER_SILENT cmd "/C" "${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.bat")
		# Strings for configure_file substitution (space-separated, portable)
		set(ENV_RUNNER_CMD "cmd /C ${BUILDMASTER_SCRIPTS_ENV_DIR}/runner.bat")
		set(ENV_RUNNER_SILENT_CMD "cmd /C ${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.bat")
		# Create silent runner
		configure_file(
			"${BUILDMASTER_ENV_DIR}/runner_windows_silent.bat.in"
			"${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.bat"
			@ONLY
		)
	else()
		# store as a list so that when expanded in COMMAND the interpreter and
		# script become separate tokens instead of a single quoted string.
		set(ENV_RUNNER /bin/sh "${BUILDMASTER_SCRIPTS_ENV_DIR}/runner.sh")
		set(ENV_RUNNER_SILENT /bin/sh "${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.sh")
		# Strings for configure_file substitution (space-separated, portable)
		set(ENV_RUNNER_CMD "/bin/sh ${BUILDMASTER_SCRIPTS_ENV_DIR}/runner.sh")
		set(ENV_RUNNER_SILENT_CMD "/bin/sh ${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.sh")
		# Create silent runner
		configure_file(
			"${BUILDMASTER_ENV_DIR}/runner_linux_silent.sh.in"
			"${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.sh"
			@ONLY
		)
		# Ensure the generated silent runner has execute permissions so it can be
		# invoked directly by execute_process(). Some platforms require the
		# executable bit even when a shebang is present.
		file(CHMOD "${BUILDMASTER_SCRIPTS_ENV_DIR}/runner_silent.sh" PERMISSIONS OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE)
	endif()

	# Detect number of processors
	include(ProcessorCount)
	ProcessorCount(NPROC)

	# Prepare ENV_RUNNER for propagation
	prepare_command(ENV_RUNNER "${ENV_RUNNER}")

	# We create a basic env runner
	update_env_runner()
endif()