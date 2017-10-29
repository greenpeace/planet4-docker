#!/usr/bin/env bash

# https://unix.stackexchange.com/questions/26676/how-to-check-if-a-shell-is-login-interactive-batch
if [[ $- == *i* ]]
then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  CYAN='\033[0;36m'
  YELLOW='\033[1;33m'
  LIGHTCYAN='\033[1;36m'
  NC='\033[0m'
else
  RED=
  GREEN=
  CYAN=
  YELLOW=
  LIGHTCYAN=
  NC=
fi

_title() {
    printf "${CYAN}*** ${LIGHTCYAN}" "$@" "${NC}\n"
}

_good() {
    printf "${GREEN}  * ${NC}" "$@" "\n"
}

_error() {
    2>&1 printf "  ${RED}* [ERROR]${NC} " "$@" "\n\n"
    exit 1;
}

_warning() {
    2>&1 printf "  ${YELLOW}* [WARNING]${NC} " "$@" "\n"
}

export -f _title
export -f _good
export -f _error
export -f _warning
