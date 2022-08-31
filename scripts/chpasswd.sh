# Copyright 2020 - 2022, Catherine Kelly
# SPDX-License-Identifier: CC0-1.0 OR Unlicense

cd "$(dirname "$0")/.."
. scripts/_init.sh

mkdir -p archives
old="$(ls -1 archives | tail -n 1)"
mkdir -p "archives/-new"
mkdir -p "archives/-new/archives"

if [ ! -z "$old" ]; then while true; do
	echo -n "Old security drives: "
	read secdrv
	echo -n "Old password: "
	read -s password
	echo
	if decprivkey; then
		oldprivkey1="$privkey1"
		oldprivkey2="$privkey2"
		break
	fi
	echo "Wrong password or corrupt security drives. Try again."
done; fi

echo -n "New security drives (DATA ON WHICH WILL BE WIPED) : "
read secdrv
echo -n "New password length: "
read passwdlen
password="$(rand 'a-zA-Z0-9+-={}<>()?!$@#&%*' "$passwdlen")"
echo "New password: $password"

echo "Generating pub/priv keys."
privkey1="$(openssl genrsa 6144 2>/dev/null)"
ntrukeys=($(rust-ntru-hps4096821/target/release/ntru-hps4096821 gen))
privkey2="${ntrukeys[1]}"
echo "Done."

salt1="$(rand '[:print:]' 30 | tee "archives/-new/salt1")"
salt2="$(rand '[:print:]' 30 | tee "archives/-new/salt2")"
salt3="$(rand '[:print:]' 30 | tee "archives/-new/salt3")"
salt4="$(rand '[:print:]' 30 | tee "archives/-new/salt4")"

argon2opts=(-id -t 15 -m 18 -p 1 -l 64)
printf "%s" "${argon2opts[*]}" >"archives/-new/argon2opts"

readsd() {
	for i in $secdrv; do
		openssl rand 10485760 | tee "$i"
	done
	openssl rand 1048576 | tee "archives/-new/secstore"
}

a="$(readsd | slowhashs "$salt1")"
b="$(slowhash "$salt2" "$password")"
c="$(hash "$salt3" "$a$b")"
d="$(hash "$salt4" "$a$b")"

printf "%s" "$privkey1" | enc "$c" "$d" >"archives/-new/privkey1"
printf "%s" "$privkey2" | enc "$d" "$c" >"archives/-new/privkey2"

printf "%s" "$privkey1" | openssl rsa -pubout >archives/-pubkey1 2>/dev/null
printf "%s" "${ntrukeys[0]}" >archives/-pubkey2

if [ ! -z "$old" ]; then
	arcdir="archives/-new/oldprivkey1"
	printf "%s" "$oldprivkey1" | archive
	arcdir="archives/-new/oldprivkey2"
	printf "%s" "$oldprivkey2" | archive
fi

mv "archives/-new" "archives/$(date +%s%3N)"

if [ ! -z "$old" ]; then
	rm -rf "archives/$old/"{argon2opts,privkey,salt1,salt2,salt3,salt4}
	shred -fzu -n 5 "archives/$old/secstore"
	rm -rf "archives/$old/secstore"
fi
