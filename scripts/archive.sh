# Copyright 2020 - 2022, Catherine Kelly
# SPDX-License-Identifier: CC0-1.0 OR Unlicense

cd "$(dirname "$0")/.."
. scripts/_init.sh

arcdir="archives/$(ls -1 archives | tail -n 1)/archives/$(date +%s%3N)"
archive
