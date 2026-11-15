# Matrix switch-over: local stack → cloud cluster (FluxCD)

Everything in this directory is the local `apps/synapse_new/` stack with cloud
deltas applied. **Nothing here is committed or applied yet** — the Flux
Kustomization `matrix-databases` (ks.yaml) ships `suspend: true`.

## Deltas already applied vs. the local stack
| File | Change |
|---|---|
| pg-matrix.yaml | `endpointURL: http://10.53.255.254:9000` (rustfs over wg) — same instance as local `10.2.11.200` |
| pg-matrix.yaml | `storageClassName: longhorn-storage` (cloud SC; local used `openebs-hostpath`) |
| pg-matrix.yaml | `bootstrap.initdb` → `bootstrap.recovery.source: matrix-pg` (PITR from the shared barman archive `s3://backups/postgres/cluster-cloud/matrix/matrix-pg/`; externalClusters + plugin already declared) |
| external-secrets.yaml | DB creds keep `matrix-synapse-local/postgres-synapse-user` — `bootstrap.recovery` does NOT re-sync the `synapse` role password, so consumers must read the secret that matches the restored DB (sha 9f1e9a7306e1) |
| external-secrets.yaml | signing key → store `vault-backend-cross-namespaces-secret`, key `matrix-synapse-local/synapse-signing-key` (byte-identical copy of `clusters/local/applications/synapse-signing-key`, sha256 `0c1b9de8…`; `vault-backend-clusters-local` does not exist on cloud — **no rotation**) |
| external-secrets.yaml | media → Vault key `matrix-synapse-local/s3-media-secret-cloud` (same creds/bucket `nobackup`/prefix `matrix-s3-storage/synapse/`, endpoint `10.53.255.254`; media store is SHARED, zero migration) |
| external-secrets.yaml | dropped dead `minio-synapse-pg-backup-secrets` ES |
| ks.yaml | new; `dependsOn: external-secrets-vault-store, cloudnative-pg, longhorn-system-base`; `suspend: true` |
| ../kustomization.yaml | `matrix-synapse/ks.yaml` commented out, `matrix/ks.yaml` added |
| bridge-whatsapp.yaml | kept `matrix-synapse-local/*` Vault paths — the as/hs tokens are baked into the restored DB + live phone session; name is historical |

## Vault keys created for this (no rotation, copies only)
- `secret/matrix-synapse-local/synapse-signing-key` (copy of the clusters-mount key)
- `secret/matrix-synapse-local/s3-media-secret-cloud` (endpoint-only variant)

## Verified cloud facts
- Nodes all arm64 (`node-arch: arm64` label) and old prod ran `dock.mau.dev/mautrix/whatsapp:v26.10` + `matrixdotorg/synapse` there → images are fine.
- CNPG 0.29.1 + barman-cloud plugin v0.11.0 ≥ local versions.
- Gateway `network/traefik-gateway` listeners `web`(8000, no hostname) / `websecure`(8443, hostname `*.icylair.com`, TLS secret `icylair-com-all-prod`) — **`matrix-auth.local.icylair.com` is two labels deep and does NOT match `*.icylair.com`**. MAS hostname decision needed (see open items).
- ClusterSecretStores identical to local (same Vault `https://hashicorp-vault.icylair.com`, path `secret`).

## Runbook
1. **Right before shutting the local stack down**: take a final manual backup —
   `kubectl --context local -n apps-matrix annotate cnpg.io/cluster matrix-pg cnpg.io/backup=manual-cutover` (or a one-off Backup CR) — that WAL/backup is the restore point.
2. Delete/scale-down local stack (leave the barman archive alone).
3. Flip `suspend: false` in ks.yaml, commit + push this branch. Flux renders
   `matrix-databases`; CNPG restores `matrix-pg` via PITR to latest WAL.
4. `Database` CRs (`matrix-pg-mas`, `matrix-pg-whatsapp`) recreate the extra DBs (roles come with the restore).
5. ES `synapse-ext-new` keeps the local-era Vault path: the restored DB retains that role password (CNPG does not ALTER it on recovery); every consumer reads the same secret.
6. Synapse/MAS/bridge HelmReleases + plain bridge Deployment come up; media already in `nobackup/matrix-s3-storage/synapse/` — no copy needed.
7. Federation: gateway routes `/_matrix/federation/*` on 443 (`websecure`), client API via well-known delegation — port 8448 not needed; DNS already points `matrix.icylair.com` at the stack (currently local LB 10.39.21.8 → repoint to cloud traefik LB once local is down).

## Open decisions before commit
- MAS hostname: keep `matrix-auth.local.icylair.com` (needs an extra `websecure` listener w/ `*.local.icylair.com` or a dedicated listener on `network/traefik-gateway`) **or** move MAS to `matrix-auth.icylair.com` and update `http.public_base`/`issuer` + Synapse `issuer` + Keycloak redirect (Keycloak client must be updated too).
- Whether to also delete the old `matrix-synapse/` dir in this repo (prune already handles the live resources once its ks line is removed).
- `bootstrap.recovery` PITRs to *latest* WAL; pin `recoveryTarget.backupID` in pg-matrix.yaml if you want a fixed point.
