# StormByte BuildMaster

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20windows%20%7C%20macos-blue)
![CMake](https://img.shields.io/badge/cmake-%3E%3D3.20-blue)
![CMake DSL](https://img.shields.io/badge/CMake-DSL-blueviolet)
![Meson](https://img.shields.io/badge/build-meson%20supported-orange)
![Ninja](https://img.shields.io/badge/build-ninja%20supported-0f4c81)
![Status](https://img.shields.io/badge/status-active-success)
![Type](https://img.shields.io/badge/type-build%20engine-lightgrey)

## Table of Contents

- [Overview](#overview)
- [Why Build Master exists](#why-build-master-exists)
- [Why this matters](#why-this-matters)
- [Design goals (brief)](#design-goals-brief)
- [How to use (quick start)](#how-to-use-quick-start)
 - [Output verbosity](#output-verbosity)
 - [Recursive configurations](#recursive-configurations)
- [Two usage modes](#two-usage-modes)
  - [Simple mode — high level](#simple-mode---high-level)
  - [Advanced mode — explicit stages](#advanced-mode---explicit-stages)
- [Targets and naming](#targets-and-naming)
- [Important functions (where to look)](#important-functions-where-to-look)
- [Helpers and utilities](#helpers-and-utilities)
- [Templates and implementation notes](#templates-and-implementation-notes)
- [Git handling](#git-handling)
- [Examples](#examples)
  - [Dependent components](#dependent-components)
- [Next steps / where to inspect](#next-steps--where-to-inspect)
- [License](#license)

---

## Overview

Build Master is a small DSL extension for CMake that makes it simple and reliable to build, install and consume external CMake and Meson projects from a parent CMake tree. It was created to work around a common limitation of `ExternalProject_Add`: external projects are typically configured at build time, which prevents the parent CMake from observing and reacting to configure-time results.

Build Master generates configure / compile / install stages **during CMake configure time**, allowing the parent project to inspect artifacts, create import targets, and adjust environment variables deterministically.

---

## Why Build Master exists

When a CMake project needs to build external dependencies as part of its own build, the usual tool — `ExternalProject_Add` — has several structural limitations:

- External projects are configured **at build time**, not at configure time.  
  This prevents the parent CMake project from inspecting results, generating import targets, or adjusting logic based on the external project's configuration.

- It does not provide **full, explicit targets** for each stage.  
  You cannot attach `POST_BUILD` commands to a clean `<component>_build` or `<component>_install` target because those targets simply do not exist.

- Environment propagation is inconsistent and must be manually handled.

- Integration with Meson projects requires custom glue and is not deterministic.

Additionally, unlike `FetchContent`, Build Master does not merely download sources — it orchestrates **full configure/build/install stages** with environment propagation and explicit targets.

Build Master solves these issues by generating deterministic stages during configure time, exposing targets such as:

```
<component>_build
<component>_install
```

This makes it trivial to attach post-build actions, inspect installed artifacts, and integrate external projects as if they were native parts of the parent build.

---

# Why this matters

Managing external dependencies in CMake has traditionally required a patchwork of ad‑hoc scripts, late‑executed logic, and build‑time orchestration that prevents the parent project from making informed decisions during the configuration phase. Tools like `FetchContent` and `ExternalProject_Add` each solve part of the problem, but neither provides a complete, deterministic, configure‑time model for building and integrating external components.

`FetchContent` focuses on retrieving sources, but delegates all configuration to the external project. `ExternalProject_Add` performs configuration and build steps only at **build time**, when it is already too late for the parent project to inspect results, generate import targets, or adjust its own configuration based on the external dependency’s capabilities.

This leaves a structural gap:

**How can a CMake project reason about external dependencies during configure time, before the build begins, and without reinventing orchestration logic for each component?**

Build Master exists to close that gap.

By generating configure/build/install stages **during CMake’s configure phase**, Build Master allows the parent project to:

- inspect artifacts before compilation begins  
- generate deterministic imported targets  
- propagate environment variables coherently  
- unify CMake and Meson projects under a single orchestration model  
- share a consistent installation layout across recursive dependency trees  
- version and reproduce all external steps in CI and local builds  

The result is a dependency model that is deterministic, inspectable, and reproducible — turning external integration from a fragile afterthought into a first‑class, declarative part of the build system.

## Comparison: CMake mechanisms vs Build Master

Build Master does not replace CMake’s existing tools. Instead, it extends them by providing deterministic configure‑time orchestration where CMake traditionally defers work to the build phase.

### Conceptual comparison

| Capability | FetchContent | ExternalProject_Add | Build Master |
|-----------|--------------|---------------------|--------------|
| Retrieve sources | ✔️ | ✔️ | ✔️ (via Git helpers) |
| Configure external projects | ❌ | ✔️ (build time) | ✔️ configure time |
| Inspect artifacts before build | ❌ | ❌ | ✔️ |
| Deterministic imported targets | ❌ | Partial | ✔️ |
| Meson integration | ❌ | Manual | ✔️ native |
| Environment propagation | ❌ | Manual | ✔️ coherent |
| Recursive usage without conflicts | ❌ | Fragile | ✔️ designed for it |
| Reproducibility | Medium | Low | High |

### Technical comparison

| Feature | FetchContent | ExternalProject_Add | Build Master |
|---------|--------------|---------------------|--------------|
| When configuration happens | N/A | Build time | Configure time |
| Explicit `<component>_build` / `<component>_install` targets | ❌ | ❌ | ✔️ |
| Ability to attach post‑build steps to external components | ❌ | ❌ | ✔️ |
| Unified installation layout | ❌ | Partial | ✔️ |
| Multi‑build‑system support (CMake + Meson) | ❌ | Manual | ✔️ |
| Versioned, generated scripts | ❌ | ❌ | ✔️ |
| CI determinism | Medium | Low | High |
| Inspect configuration results | ❌ | ❌ | ✔️ |
| Stability in deep dependency trees | Low | Fragile | ✔️ robust |

## Design goals (brief)

- Deterministic configure-time behavior.
- Coherent environment propagation (`PKG_CONFIG_PATH`, `PATH`, `LIB`, `INCLUDE`, etc.).
- Cross-platform support (Windows, Linux, macOS).
- Modular helpers and templates for CMake and Meson.
- Reproducible builds: all external steps are scripted and version-controlled.

---

## How to use (quick start)

Using Build Master in a project is intentionally simple — three steps:

```cmake
# optional: enable extra tools (e.g. pkgconf)
set(BUILDMASTER_INITIALIZE_EXTRA_TOOLS "pkgconf")

# add the Build Master tree to your project
add_subdirectory(buildmaster)

# import the helper DSL
include(buildmaster/helpers.cmake)
```

What these lines do:

- `BUILDMASTER_INITIALIZE_EXTRA_TOOLS`: optional list of extra tools that are not initialized by default.
- `add_subdirectory(buildmaster)`: configures and initializes Build Master.
- `include(buildmaster/helpers.cmake)`: imports helper functions such as `create_component()`, `create_cmake_component()`, `create_meson_component()` and other utilities.

After this you can declare components:

```cmake
set(options "-DENABLE_FOO=ON")
create_cmake_component(OUT_FILE
                       opus
                       "Opus Audio Codec"
                       ${CMAKE_SOURCE_DIR}/thirdparty/opus
                       ${CMAKE_BINARY_DIR}/thirdparty/opus_build
                       "${options}"
                       shared
                       "")
include(${OUT_FILE})
```

Notes:

- The first argument (`OUT_FILE`) receives the generated fragment path.
- After `include(${OUT_FILE})`, the imported targets and stage targets (`<component>_build`, `<component>_install`) become available.

---

## Output verbosity

By default Build Master produces minimal, concise output: a single brief line for each stage — configure, build and install — so that CMake output remains compact when managing many components. To enable full, verbose output for the configure and build stages set the environment variable `BUILDMASTER_DEBUG` to `1`. When `BUILDMASTER_DEBUG` is `1` Build Master will show the underlying configure and build tool output (stdout/stderr) to help diagnose configure-time or build-time problems.

## Recursive configurations

Build Master is designed to support recursive usage: an external CMake project may itself use Build Master to orchestrate its dependencies, and those dependencies may also use Build Master, recursively. This is possible because Build Master is initialized only once (for example by `add_subdirectory(buildmaster)`) and all recursive instances share the same installation location (the unified `BUILDMASTER_INSTALL_DIR`). Nested projects therefore reuse the same initialization state and installation layout, avoiding duplicate initializations and conflicting install paths while ensuring deterministic behavior across parent and subproject boundaries.

## Two usage modes

### Simple mode — high level

- Call `create_component()` or the wrappers `create_cmake_component()` / `create_meson_component()`.
- A per-component CMake fragment is generated and returned.
- The fragment declares imported targets and wires build/install stages.

### Advanced mode — explicit stages

- Call `create_cmake_stages()` or `create_meson_stages()` directly.
- Three scripts are generated: configure, build, install.
- Include them manually to customize ordering or attach `POST_BUILD` steps.

---

## Targets and naming

- All components define stage targets:

```
<component>_build
<component>_install
```

- Install commands declare their produced files as `OUTPUT`, so other targets can depend on them.

---

## Important functions (where to look)

- `create_component(_out_var _component _component_title _srcdir _builddir _options _library_mode _build_system _subcomponents _dependency)`
- `create_cmake_stages(_file_configure _file_compile _file_install _component _component_title _srcdir _builddir _options _library_mode _output_libraries)`
- `create_meson_stages(...)`

---

## Helpers and utilities

- `library_import_hint()`
- `library_import_static_hint()`
- `library_dll_hint()`
- `sanitize_for_filename()`
- `list_join()`
- `prepare_command()`

These helpers are used internally by templates but can also be used by the user.

---

## Templates and implementation notes

CMake templates:

- `tools/cmake/configure.cmake.in`
- `tools/cmake/build.cmake.in`
- `tools/cmake/install.cmake.in`

Meson templates:

- `tools/meson/setup.cmake.in`
- `tools/meson/compile.cmake.in`
- `tools/meson/install.cmake.in`

Templates are versioned and can be customized if needed.

---

## Git handling

Build Master includes helpers that generate Git-related scripts under the generated scripts tree.

Examples:

```cmake
create_git_fetch(GIT_FETCH_FILE
                 myrepo
                 ${CMAKE_SOURCE_DIR}/thirdparty/myrepo)
include(${GIT_FETCH_FILE})
```

```cmake
create_git_patch_file(GIT_PATCH_FILE
                      myrepo
                      ${CMAKE_SOURCE_DIR}/thirdparty/myrepo
                      "${CMAKE_SOURCE_DIR}/patches/patch1.diff;${CMAKE_SOURCE_DIR}/patches/patch2.diff}")
include(${GIT_PATCH_FILE})
```

Scripts are generated under `BUILDMASTER_SCRIPTS_GIT_DIR`.

---

## Examples

### Simple mode

```cmake
add_subdirectory(path/to/buildmaster)
include(buildmaster/helpers.cmake)

set(options "-DENABLE_FEATURE=ON")
create_cmake_component(LIB_CREATE_FILE
                       mylib
                       "My Library"
                       ${CMAKE_SOURCE_DIR}/third_party/mylib
                       ${CMAKE_BINARY_DIR}/third_party/mylib_build
                       "${options}"
                       shared
                       "")
include(${LIB_CREATE_FILE})
```

### Advanced mode

```cmake
create_cmake_stages(cfg_script build_script install_script
                    mylib "My Library"
                    ${CMAKE_SOURCE_DIR}/third_party/mylib
                    ${CMAKE_BINARY_DIR}/third_party/mylib_build
                    "-DENABLE_FEATURE=ON"
                    shared "/path/to/output/libmylib.so")

include(${cfg_script})
include(${build_script})
include(${install_script})
```

---

## Dependent components

```cmake
create_cmake_component(B_FILE
                       libb
                       "LibB"
                       ${CMAKE_SOURCE_DIR}/thirdparty/libb
                       ${CMAKE_BINARY_DIR}/thirdparty/libb_build
                       "${options}"
                       shared
                       "")
include(${B_FILE})

create_cmake_dependant_component(A_FILE
                                 liba
                                 "LibA"
                                 ${CMAKE_SOURCE_DIR}/thirdparty/liba
                                 ${CMAKE_BINARY_DIR}/thirdparty/liba_build
                                 "${options}"
                                 shared
                                 ""
                                 "libb_install")
include(${A_FILE})
```

---

## Next steps / where to inspect

- High-level helpers: `component/helpers.cmake`
- CMake stage generator: `tools/cmake/helpers.cmake`
- Meson stage generator: `tools/meson/helpers.cmake`
- Git helpers: `tools/git`

---

## License

Build Master is distributed under the MIT License.  
See the `LICENSE` file for full details.
