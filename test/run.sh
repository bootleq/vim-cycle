#!/usr/bin/env bash

if [[ ! -x test/vim-themis/bin/themis ]]; then
  echo 'Error: vim-themis not installed, clone it now? (y/N)'
  read choice
  if [[ $choice == 'y' ]]; then
    git clone https://github.com/thinca/vim-themis.git test/vim-themis
  else
    echo 'Aborted.'
    exit 1
  fi
fi

: "${THEMIS_VIM:=vim}"
: "${THEMIS_ARGS:=-e -s}"

if [[ "${THEMIS_VIM}" == *nvim ]]; then # add --headless to nvim
  THEMIS_ARGS="$THEMIS_ARGS --headless"
fi

cmd="THEMIS_VIM=$THEMIS_VIM THEMIS_ARGS='$THEMIS_ARGS' ./test/vim-themis/bin/themis $@"
echo $cmd
echo
eval $cmd
