#!/bin/bash

function norm() {
    local major_minor_patch
    local minor_patch
    local patch
    local major
    local minor
    major_minor_patch=$1
    minor_patch=${major_minor_patch#*.}
    patch=${minor_patch#*.}
    major=${major_minor_patch::-${#minor_patch}-1}
    minor=${minor_patch::-${#patch}-1}
    printf "%d%04d%04d\n" "$major" "$minor" "$patch"
}

first=$(norm "$1")
second=$(norm "$2")

[[ "$first" -lt "$second" ]]
