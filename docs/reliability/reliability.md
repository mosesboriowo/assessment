# Reliability & Production Operations (Part 4)

How the system keeps operating safely under production conditions, the failure modes it survives, and the recovery objectives.

---

## Recovery objectives
- **RPO ≤ 15 minutes** — RDS automated backups + binlog PITR mean at most ~15 min of data loss in a worst-case restore. Reasoning: a payments workload cannot tolerate large data loss; PITR to a point just before an incident is the tightest practical objective without synchronous cross-site replication.
- **RTO ≤ 1 hour** — time to restore service via failover (multi-AZ) or restore-from-backup + redeploy. Most events (pod/node/AZ) recover in **minutes** automatically; the 1-hour RTO covers the worst case (full DB restore).

---

## Failure modes and how the design survives them

| Failure | What happens | Recovery |
|---|---|---|
| **Service (pod) failure** | Liveness probe fails | Kubernetes restarts the pod; readiness keeps traffic off it until healthy. No user impact with N replicas. |
| **Node failure** | Pods rescheduled | CCE reschedules pods to healthy nodes across AZs; cluster autoscaler replaces the node. |
| **AZ failure** | One AZ lost | Multi-AZ node pool + **RDS multi-AZ failover** + ELB across AZs → service continues from the surviving AZ. |
| **Database failure** | Primary unhealthy | RDS **automatic failover to standby** (prod). If data corruption: **PITR restore** to just before the event (RPO ≤ 15 m). |
| **Increased traffic** | Load rises | **HPA** scales pods (memory 75%); **cluster autoscaler** adds nodes; ELB spreads load. Stateless pods scale freely. |
| **Failed deployment** | New version unhealthy | Readiness-gated rolling update never shifts traffic to bad pods; **auto-rollback** (Helm) + smoke test catch it. |
| **Backup restoration** | Need to recover data | Restore RDS from automated backup/PITR into a new instance; repoint the app via its CSMS secret. Tested periodically (drill). |
| **Disaster recovery** | Loss beyond one AZ | Restore from in-region backups into a second **Nigerian** AZ/DC (residency preserved). Terraform re-provisions the stack from code; state is in OBS. |

---

## Incident detection & alerting
- **Cloud Eye/AOM** metrics with **SMN** alerts on: error rate, p95 latency, pod restart loops (CrashLoopBackOff), node CPU/memory/disk, RDS connections/replication lag.
- **LTS** structured logs (app logs to `stderr` → captured by CCE → LTS), so there are **no log files accumulating on disk** — the disk-saturation failure mode is designed out.
- Alerts route to **email + Teams**; sev-1s page on-call.

---

## Live incident exercise — my method (for the final interview)
The exact scenario isn't given in advance, so I go in with a **fixed investigation sequence** tied to this architecture:

1. **Confirm scope & communicate** — is it total or partial? Post an initial status; start an incident channel. **Mitigate before diagnosing** (restore service first).
2. **Top-down from the metrics** — Cloud Eye/AOM dashboard: error rate, latency, which tier (ELB, pods, RDS, DCS)?
3. **Narrow to the layer** — pods: `kubectl get pods` for **CrashLoopBackOff / OOMKilled / ImagePullBackOff** → `describe` + events; DB: connections, replication lag, disk; edge: ELB/ingress health.
4. **Correlate logs/traces** — LTS logs for the failing component; recent deploy? recent migration?
5. **Remediate** — roll back the release (Helm), scale out, fail over the DB, or restore from PITR — the smallest safe action that restores service.
6. **Restore & verify** — smoke test `/api/v1/health` + a real transaction path; confirm metrics normal.
7. **Communicate resolution**, then **corrective engineering** — blameless RCA, add the missing alert/guardrail so it can't recur (e.g. the log-rotation/alerting fix from a real disk-saturation incident I handled).

---

## What I'd add with more time
- Scheduled **restore drills** proving RPO/RTO for real, not on paper.
- Chaos testing (kill a node/AZ) to validate failover.
- Distributed tracing (OpenTelemetry) for faster root-cause on multi-service calls.
