#!/usr/bin/env bash
# Utility functions

# Retrieve the names of the applications in the repo by listing the directories
# in the "infra" directory and filtering out the directories that are not
# applications.
# Returns: A list of application names.
function get_app_names() {
  find "infra" \
    -maxdepth 1 \
    -type d \
    -not -name "infra" \
    -not -name "accounts" \
    -not -name "modules" \
    -not -name "networks" \
    -not -name "project-config" \
    -not -name "test" \
    -exec basename {} \;
}

# Return the names of Terraform backend configuration files in (without the
# ".<backend type>.tfbackend" suffix) for the root module given by
# "infra/${root_module_subdir}".
#
# Parameters:
#   - root_module_subdir: The subdirectory of the root module where the backend
#                         configuration files are located.
#
# Returns:
#   - The names of the backend configuration files, separated by newlines
function get_backend_config_names_in_root_module() {
  # for convenience, support getting passed a project path including `infra/`,
  # but the general intention is the function is called directly with the subdir
  local root_module_subdir="${1#infra/}"
  local root_module="infra/${root_module_subdir}"
  if [ -d "${root_module}" ]; then
    find "${root_module}" -name "*.tfbackend" -exec bash -c '
        for file; do
            basename "${file%.*.tfbackend}"
        done
    ' _ {} +
  fi
}

# Base 62 decode a string.
# Returns: String as base 10 number.
function base62_decode() {
  local digits="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  local s=$1
  local n=0

  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    pos=${digits%%"$c"*}
    n=$((n * 62 + ${#pos}))
  done

  echo $n
}
