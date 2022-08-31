# Copyright 2021 - 2022, Catherine Kelly
# SPDX-License-Identifier: CC0-1.0 OR Unlicense

cd "$(dirname "$0")/.."

for i in $(ls -1 archives/*/archives 2>/dev/null | grep -v 'archives'); do
	echo -n "$i  "
	date -d "@$[i / 1000]"
done
