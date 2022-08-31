# Copyright 2020 - 2022, Catherine Kelly
# SPDX-License-Identifier: CC0-1.0 OR Unlicense

cd "$(dirname "$0")/.."
. scripts/_init.sh

while true; do
	echo -n "Security drives: " >&2
	read secdrv
	echo -n "Password: " >&2
	read -s password
	echo >&2
	if decprivkey; then break; fi
	echo "Wrong password or corrupt security drives. Try again." >&2
done

currprivkey1="$privkey1"
currprivkey2="$privkey2"

for ii in "$@"; do
	privkey1="$currprivkey1"
	privkey2="$currprivkey2"

	keyts="$(ls "archives/"*"/archives/$ii/key1" 2>/dev/null | cut -d '/' -f 2)"
	if [ -z "$keyts" ]; then
		echo "Decryption failed: archive $ii not found." >&2
		continue
	fi

	if ! decoldkey "$keyts"; then
		echo "Decryption failed." >&2
		continue
	fi

	arcdir="archives/$keyts/archives/$ii"
	decrypt
done
