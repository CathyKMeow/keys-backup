# Copyright 2020 - 2022, Catherine Kelly
# SPDX-License-Identifier: CC0-1.0 OR Unlicense

slowhash() {
	echo "Slow-hashing." >&2
	printf "%s" "$2" | argon2 "$1" "${argon2opts[@]}"  -r
	echo "Done." >&2
}

hash() {
	printf "%s%s" "$1" "$2" | openssl dgst -sha3-256 -hex | cut -d ' ' -f 2
}

slowhashs() {
	slowhash "$1" "$(cat <(printf "%s" "$1") /dev/stdin | openssl dgst -sha3-256 -hex | cut -d ' ' -f 2)"
}

rand() {
	openssl rand 2100000000 | tr -dc "$1" | head -c "$2"
}

enc() {
	openssl enc -aes-256-ctr -iv "$1" -K "$2" 2>/dev/null
}

archive() {
	mkdir -p "$arcdir"

	key1="$(openssl rand -hex 64)"
	ntru=($(cat archives/-pubkey2 | rust-ntru-hps4096821/target/release/ntru-hps4096821 enc))
	key2="${ntru[0]}"

	printf "%s" "$key1" | openssl rsautl -encrypt -inkey archives/-pubkey1 -pubin >"$arcdir/key1"
	printf "%s" "${ntru[1]}" >"$arcdir/key2"

	key="$(hash "" "123123$key1$key2 321321")"
	iv="$(hash "" "456456$key2$key1 654654")"
	enc "$iv" "$key" >"$arcdir/data"
}

decrypt() {
	key1="$(cat $arcdir/key1 | openssl rsautl -decrypt -inkey <(printf "%s" "$privkey1"))"
	if [ "$?" != "0" ]; then
		echo "Decryption failed." >&2
		return 1
	fi
	key2="$(cat <(printf "%s\n" "$privkey2") $arcdir/key2 | rust-ntru-hps4096821/target/release/ntru-hps4096821 dec)"

	key="$(hash "" "123123$key1$key2 321321")"
	iv="$(hash "" "456456$key2$key1 654654")"
	cat "$arcdir/data" | enc "$iv" "$key"
}

decprivkey() {
	dir="archives/$(ls -1 archives | tail -n 1)"

	salt1="$(cat "$dir/salt1")"
	salt2="$(cat "$dir/salt2")"
	salt3="$(cat "$dir/salt3")"
	salt4="$(cat "$dir/salt4")"
	argon2opts=($(cat "$dir/argon2opts" | tr -dc '\-idtmkpl0-9 '))
	readsd() {
		for i in $secdrv "$dir/secstore"; do
			cat $i
		done
	}

	a="$(readsd | slowhashs "$salt1")"
	b="$(slowhash "$salt2" "$password")"
	c="$(hash "$salt3" "$a$b")"
	d="$(hash "$salt4" "$a$b")"

	privkey1="$(cat "$dir/privkey1" | enc "$c" "$d" | tr -d '\0')"
	privkey2="$(cat "$dir/privkey2" | enc "$d" "$c" | tr -d '\0')"

	[ ! -z "$(printf "%s" "$privkey1" | grep -F 'BEGIN RSA PRIVATE KEY')" ]
}

decoldkey() {
	for i in $(ls -1 archives | tac); do
		if [ "$i" == "$1" ]; then
			return 0
		fi

		arcdir="archives/$i/oldprivkey1"
		oprivkey1="$(decrypt)"
		arcdir="archives/$i/oldprivkey2"
		privkey2="$(decrypt)"
		privkey1="$oprivkey1"
		if [ -z "$(printf "%s" "$privkey1" | grep -F 'BEGIN RSA PRIVATE KEY')" ]; then
			echo "Decryption failed at $i" >&2
			return 1
		fi
	done
}
