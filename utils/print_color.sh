#!/usr/bin/env bash

ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
WARNING='\033[0;33m'
INFO='\033[0;36m'
NC='\033[0m'

print_error() {
    printf "${ERROR}%s${NC}\n" "$*" >&2
}

print_success() {
    printf "${SUCCESS}%s${NC}\n" "$*"
}

print_warning() {
    printf "${WARNING}%s${NC}\n" "$*"
}

print_info() {
    printf "${INFO}%s${NC}\n" "$*"
}
