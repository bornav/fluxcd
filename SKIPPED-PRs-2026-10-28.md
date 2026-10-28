# Renovate batch merge — 2026-10-28

Branch `batch/renovate-2026-10-28` (based on `origin/main` @ 487ae6b7) merges **70 of 89** open Renovate PRs.
Each PR keeps its original commit (author = renovate[bot], `(cherry picked from commit ...)` trailer).
PRs whose stale branches carried outdated traefik hunks were cherry-picked with the traefik files restored to main, so **your traefik values (accessLog, trustedIPs, plugins) are untouched**; the traefik chart bump itself (#2698 → 42.1.3) was re-applied on top.

## Skipped PRs (19)

### Breaking AND you are affected (2)
| PR | Dependency | Reason |
|---|---|---|
| #2361 | chart postgresql 15.5.23 → 18.12.16 | Harbor's `harbor-database` PVC holds **PG15 data — PG18 cannot start in-place** (needs pg_dump/restore or pg_upgrade). Also: target chart version doesn't exist upstream (suspect catalog); verify Harbor's supported PG major before any bump. |
| #2687 | image mariadb 10.11 → 13.0 | Seafile DB (bare Deployment + PVC, shared with seafile container). 3-major jump (10.11→11→12→13) via `MARIADB_AUTO_UPGRADE` in one restart is unsupported-risky. Take mysqldump first; stage 10.11→11.4→13.0. |

### Breaking, needs operator action (1)
| PR | Dependency | Reason |
|---|---|---|
| #2627 | chart velero 11.1.1 → 12.2.1 | Chart 12.0 removed bitnami init-container deps; repo's values are all commented-out — re-verify BSL/persistence/plugins before switching. The safe in-series bump **11.4.0 (#2500) IS on this branch**. |

### Superseded by newer-series PRs that were merged (14) + abandoned (1)
Older Renovate branches for the same dependency:
| PR | Superseded by (merged) |
|---|---|
| #2510 nextcloud 8.9.1 | #2624 (9.4.1) — dormant app, staged-upgrade note below |
| #2557 pyroscope 1.21.0 | #2641 (2.4.2) |
| #2567 alertmanager 1.41.0 | #2688 (2.1.2) |
| #2576 authentik 2025.12.4 | #2618 (2026.8.5) |
| #2579 homepage v1.13.2 | #2686 (v2.7.0) |
| #2591 kube-prometheus-stack 81.6.9 | #2697 (92.14.0) |
| #2596 stork 25.6.1 | #2620 (26.4.2) — dead code, see notes |
| #2603 loki 6.55.0 | #2643 (7.5.0) |
| #2604 portainer 2.39.0 | #2691 (245.3.0) |
| #2625 grafana 11.6.1 | #2696 (14.1.0) |
| #2631 renovate 43.288.0 | #2678 (44.186.5) |
| #2647 tempo 2.4.0 | #2692 (3.2.1) — re-enable warning below |
| #2653 haproxy 2.9 | #2654 (3.4) |
| #2681 traefik 41.7.1 | #2698 (42.1.3) |
| #1089 bitnami postgresql 16.4 (title says "abandoned", 3331 commits stale) | nothing merged for it |

### Skipped for cluster-version safety (1)
| PR | Dependency | Reason |
|---|---|---|
| #2606 | image kube-scheduler v1.35.0 → v1.37.1 | Static kube-scheduler Deployment pinned to v1.35.0; cluster is k3s/RKE2 ~1.35. A scheduler 2 minors ahead violates the version-skew policy. Merge only if control plane is ≥1.37. |

## Merged with caveats (read before re-enabling those apps)
- **#2692 tempo 2.0.0→3.2.1 (dormant):** inline config template still emits Tempo-2-only keys (`ingester`, `compactor`, `traces_storage`, `local-blocks` processor). Tempo 3 rejects these at startup → **do not re-enable without rewriting the config** (live_store/backend_worker etc.) and removing port 55678 from the active `service-lb.yaml`.
- **#2696 grafana 11.3→14.1 (dormant):** renders fine with repo values, but new defaults `runAsNonRoot:472` + `readOnlyRootFilesystem` (distroless image, no shell) and Role/RoleBinding removed (Flux prune) — review on re-enable.
- **#2697 kube-prometheus-stack 81→92 (Flux ks suspend:true):** no values keys removed; Prometheus 2→3 (removed feature-flag warnings only, PromQL `.` matches newlines); one-time restarts from nodeSelector default. Review before unsuspend.
- **#2688 alertmanager standalone 2.1.2 (file commented out in kustomization):** tightened default securityContext (runAsNonRoot 65534, drop ALL caps, ro rootfs) — verify against LoadBalancer/Longhorn setup if re-enabled.
- **#2691 portainer 245.3.0 (release.yaml commented out):** server = CE 2.45.3; Portainer requires agent == server version; agent here is 2.44.0 (#2592). **Bump agent to 2.45.x before re-enabling the server.**
- **#2624 nextcloud 9.4.1 (dormant/suspended):** chart keys OK, but appVersion jumps NC 32→35 = 3 server majors; if ever re-enabled, stage 32→33→34→35 (start from #2510's 8.9.1 / NC 32.0.6).
- **#2695 seafile-mc 14.0 (deployment not Flux-managed):** inert; if reactivated, backup PVC+DB first (13→14 not a blind tag swap; PVC is shared with mariadb).
- **#2694 onlyoffice 7.5→10.0 (filestash docker-compose, not deployed):** inert; if ever run, JWT is now on by default → set shared secret.
- **#2620 stork 26.4.2 (dead code):** Portworx not used anywhere, ks commented out, config uses removed `v1beta3` scheduler API. **Consider deleting `kubernetes/apps/kube-system/stork-scheduler/` instead.**
- **#2618 authentik 2026.8.5 (ks suspend:true):** inert on this branch; yearly major — run authentik's migration/preflight steps before unsuspending.
- **#2601 cilium 1.18.9→1.20.0:** all repo values keys still valid; `helmfile.yaml` bumped in lockstep; run cilium preflight before applying.
- **#2674 redis 7→8 (active):** traefik forward-auth session cache; plain redis-server + requirepass, no modules/eviction config, Redis 8 loads 7.x RDB — compatible.
- **#2670 checkout v7 (self-hosted runner):** only caveat — runner must be ≥2.329.0 (creds persisted via $RUNNER_TEMP since v6); workflow is workflow_dispatch-only so the fork-PR guard doesn't apply.

## Verified safe (no action)
#2698 traefik 42.1.3 (K8s≥1.30 req met, no Hub config), #2686 homepage v2.7.0 (opt-in auth only), #2643 loki 7.5.0 (Loki stays 3.6.x), #2641 pyroscope 2.4.2 (additive), #2654 haproxy 3.4 (all directives stable, 2.8 is EOL), #2678 renovate 44.186.5 (44.0.0 was a mislabeled major — config compatible), #2670 actions/checkout v7 (trivial workflow), plus all non-breaking bumps.
