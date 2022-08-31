# Backup your keys and passwords securely
(And other data too)

## Init
```
$ rm -rf archives
$ bash scripts/build-rust-ntru.sh
Compiling typenum v1.15.0
   Compiling version_check v0.9.4
   Compiling libc v0.2.126
   Compiling crunchy v0.2.2
   Compiling tiny-keccak v2.0.2
   Compiling opaque-debug v0.3.0
   Compiling ntrust-native v1.0.1
   Compiling cfg-if v1.0.0
   Compiling hex v0.4.3
   Compiling generic-array v0.14.5
   Compiling cpufeatures v0.2.2
   Compiling cipher v0.3.0
   Compiling aes v0.7.5
   Compiling ntru-hps4096821 v0.1.0 (/home/user/Documents/keys-backup/rust-ntru-hps4096821)
    Finished release [optimized] target(s) in 5.00s
$ newgrp disk
Password:
$ bash scripts/chpasswd.sh
New security drives (DATA ON WHICH WILL BE WIPED) : /dev/sdb /dev/sdc
New password length: 10
New password: StdpM)$6wY
Generating pub/priv keys.
Done.
Slow-hashing.
Done.
Slow-hashing.
Done.
```
## Backup
```
$ tar -c ~/Documents/keysbackup | bash scripts/archive.sh
```
## Restore
```
$ bash scripts/list.sh
1654883879529  Fri Jun 10 10:57:59 PDT 2022
$ bash scripts/decrypt.sh 1654883879529 | tar -x -C ~/Documents
Security drives: /dev/sdb /dev/sdc  # `sdc sdb` won't work
Password: 
Slow-hashing.
Done.
Slow-hashing.
Done.
```
## Change password & reset security drives
```
$ newgrp disk
Password:
$ bash scripts/chpasswd.sh
Old security drives: /dev/sdb /dev/sdc
Old password: 
Slow-hashing.
Done.
Slow-hashing.
Done.
New security drives (DATA ON WHICH WILL BE WIPED) : /dev/sdb /dev/sdd
New password length: 12
New password: (<Ri-c;HL!jO
Generating pub/priv keys.
Done.
Slow-hashing.
Done.
Slow-hashing.
Done.
$ # /dev/sdc is no longer being used, so you should erase it.
$ for i in {1..3}; do dd if=/dev/urandom bs=1M count=10 of=/dev/sdc; done
```

Your password and the disks used to setup the backup will be required to decrypt your data or change the password.

An attacker would be able to decrypt your data if he/she/per got your password and all of your security drives.

You should change the password immediately if someone else knows the password or gets a copy of one of your disks.

## Algorithms Used
||| 
|---|---|
| Hash						| SHA3-256					|
| Password Hash				| Argon2 (id)				|
| Asymmetric Encryption		| RSA6144 + NTRU-hps4096821	|
| Symmetric Encryption		| AES-256 (CTR mode)		|
