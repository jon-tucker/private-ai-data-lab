# Encrypted secrets backup and recovery

The coordinated platform backup excludes `/srv/oracle-ai-secrets`. That
directory contains database and application passwords, signing keys, TLS
private keys, and certificate authorities. A data backup without the matching
secrets may not be sufficient to bring services back.

Keep an encrypted secrets archive on storage separate from the server. Keep
the OpenPGP private decryption key offline and separate from that archive. The
server needs only the validated public encryption key. Never put secret
values, private keys, decrypted archives, or recovery-key material in Git.

## Prepare the recovery key

On a trusted workstation, create or select an OpenPGP key that supports
encryption. Back up its private key and revocation certificate to separate
offline media. Record its full fingerprint in the operator's recovery record.
Export only its public key and import that public key on the server:

```bash
gpg --import private-ai-data-lab-recovery-public.asc
gpg --fingerprint RECOVERY_FINGERPRINT
```

Before using it, compare the displayed full fingerprint with the value recorded
out of band. The encryption recipient must be that full fingerprint, not an
email address or a short key ID.

## Create and verify an encrypted archive

Mount the separate recovery drive and confirm its mount point before running
this command. Replace the recipient fingerprint and destination with the
values recorded for the recovery setup:

```bash
set -o pipefail
umask 077
recipient='FULL_OPENPGP_FINGERPRINT'
destination='/mnt/private-ai-recovery/private-ai-secrets-YYYYMMDD.tar.gz.gpg'

sudo tar --numeric-owner --acls --xattrs --selinux \
  -C /srv -czf - oracle-ai-secrets |
  gpg --batch --trust-model always --encrypt \
    --recipient "${recipient}" --output "${destination}"
chmod 0600 "${destination}"
```

Check that the output is non-empty, has mode `0600`, and resides on the
intended separate drive. Test it on the trusted workstation with the offline
private key, discarding plaintext output:

```bash
gpg --output /dev/null --decrypt \
  /mnt/private-ai-recovery/private-ai-secrets-YYYYMMDD.tar.gz.gpg
```

Repeat after meaningful changes to secrets or certificates. Keep at least one
known-good encrypted copy and protect the private decryption key independently.
Do not rely on a backup stored only on this server.

## Restore to an isolated staging directory

Use a separate isolated recovery environment with the private key available
locally and the encrypted archive copied onto it. First decrypt into an
isolated directory, not the active secrets path. Import the private key only
for recovery and remove it from the environment after verification:

```bash
gpg --import private-ai-data-lab-recovery-private.asc
gpg --fingerprint RECOVERY_FINGERPRINT
set -o pipefail
sudo install -d -o root -g root -m 0700 /srv/restore-staging
gpg --output - --decrypt \
  /mnt/private-ai-recovery/private-ai-secrets-YYYYMMDD.tar.gz.gpg |
  sudo tar --numeric-owner --acls --xattrs --selinux \
    -xzpf - -C /srv/restore-staging
```

After checking the staged result, remove the imported private key from the
recovery environment's keyring with `gpg --delete-secret-keys RECOVERY_FINGERPRINT`.
Do not copy the private key into the restored secrets directory.

Review file names, ownership, permissions, and required secret presence without
printing file contents. The extracted directory is
`/srv/restore-staging/oracle-ai-secrets`. Preserve root ownership and the
