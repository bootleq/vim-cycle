#!/usr/bin/env bash

THEMIS_BIN=test/vim-themis/bin/themis


# Helper functions: {{{
# User provided args ($@) were delegated to themis, which uses bash array expansion to correctly handle strings.
# However we want to display the command before execution, where the args might lose their initial quotes.
# This function wraps those string arguments with quotes (might be different from what user provided.)
special_chars='[][:space:]$!#%^&*(){}\\\[<>|;"`]'
_quote_args_for_display() {
  local arg="$1"

  # For args not contain single quote, wrap with double quotes
  if [[ "$arg" == *"'"* ]]; then
    local escaped_arg
    escaped_arg=$(echo "$arg" | sed 's/\\/\\\\/g; s/"/\\"/g') # escape \ and "
    echo "\"$escaped_arg\""
  elif [[ "$arg" =~ $special_chars ]] || [[ -z "$arg" ]]; then
    # Wrap with single quote
    echo "'$arg'"
  else
    # No wrapping for simple case
    echo "$arg"
  fi
}
_format_args_for_display() {
  local formatted_string=""
  local arg
  for arg in "$@"; do
    formatted_string+="$(_quote_args_for_display "$arg") "
  done
  echo "$formatted_string" | sed 's/[[:space:]]*$//'
}
# }}}


# Ensure working directory is repo root
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$(dirname $SCRIPT_DIR)"

if [[ ! -x $THEMIS_BIN ]]; then
  echo 'Error: vim-themis not installed, clone it now? (y/N)'
  read choice
  if [[ $choice == 'y' ]]; then
    git clone https://github.com/thinca/vim-themis.git test/vim-themis
  else
    echo 'Aborted.'
    exit 1
  fi
fi


cmd_env=("env")
[[ -v THEMIS_VIM ]] && cmd_env+=("THEMIS_VIM=$THEMIS_VIM")
[[ -v THEMIS_ARGS ]] && cmd_env+=("THEMIS_ARGS=$THEMIS_ARGS")

cmd_array=("$THEMIS_BIN")
cmd_array+=("$@")

display_env=$(_format_args_for_display "${cmd_env[@]}")
display_args=$(_format_args_for_display "$@")

# Print command before run (note that arguments display may have quotes different to user input)
# echo "${cmd_env[*]} $THEMIS_BIN $display_args"
echo "$display_env $THEMIS_BIN $display_args"
echo

"${cmd_env[@]}" "${cmd_array[@]}"
