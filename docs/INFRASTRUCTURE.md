# Infrastructure — `baka.in.ua`

**Updated:** 2026-05-22 · Performance: [PERFORMANCE_AUDIT.md](PERFORMANCE_AUDIT.md)

---

## Layout

```text
Cloudflare → DO App Platform (FRA)
  tanooki (web)      1 Gi   Puma, Solid Cache, SOLID_QUEUE_IN_PUMA=false
  tanooki2 (worker)  1 Gi   bundle exec bin/jobs
  db-migrate (job)     PRE_DEPLOY → bundle exec rails db:migrate
  → DO Managed MySQL · DO Spaces
  → Elasticsearch on VPS (167.71.63.106) via ELASTICSEARCH_URL

VPS baka-v2 — ES + legacy cron until removed (Puma, nginx, local MySQL, Kibana: off)
```

| Component | Size |
|-----------|------|
| DO web / worker | 1 Gi each |
| db-migrate job | 512 Mi (shared CPU) |
| VPS | ~3.8 Gi until E2 + F |

---

## Deploy

| Change | Action |
|--------|--------|
| App code or migration | `git push main` → DO (`db-migrate` runs first, then `tanooki` + `tanooki2`) |
| VPS cron (legacy) | `cap production deploy` until crontab removed |

Skip **`cap`** for schema-only releases (avoids double-migrate on VPS). Optional later: disable `deploy:migrate` in Capistrano.

---

## Completed (2026-05-22)

- DO web + worker; Solid Cache + Solid Queue; `SOLID_QUEUE_IN_PUMA=false` (`e9cc6e4`)
- DNS → DO; VPS app stack stopped; local MySQL cleared (backup `/root/mysql-local-backup-20260522.tgz`)
- **E1:** `ELASTICSEARCH_URL` + `searchkick.rb` (`0813822`); search + worker reindex verified
- **G:** `db-migrate` PRE_DEPLOY; migrations on `git push` (verified `20260522200000`)

---

## Next

**F (finish on VPS):** parallel cron + recurring → remove crontab → delete `config/schedule.rb`. **E2** — ES off VPS. Then retire baka-v2.

### F — Cron on worker (code on `main` after push)

Recurring tasks in `config/recurring.yml` (Europe/Kiev). After deploy, `tanooki2` logs should list scheduler tasks on boot.

**Parallel check:** leave VPS crontab; compare `log/cron.log` vs worker `Performing …Job` for a week.

**Cutover (after parallel check):**

- [ ] VPS: `crontab -u deploy -l` then `crontab -r -u deploy`
- [ ] Repo: delete `config/schedule.rb` (schedules live in `config/recurring.yml` only)
- [ ] Optional: drop `whenever` from Gemfile if nothing else uses it
- [ ] Stop using `cap production deploy` for routine releases

### E2 — ES off VPS

- Reindex → update `ELASTICSEARCH_URL` → stop ES on baka-v2 → firewall DO egress `207.154.208.206`

---

## Checks

```sql
SELECT hostname, MAX(last_heartbeat_at) AS latest
FROM solid_queue_processes GROUP BY hostname;
-- tanooki2-* only

SELECT COUNT(*) FROM solid_queue_jobs WHERE finished_at IS NULL;
```

```bash
crontab -u deploy -l   # VPS until F done
```

---

## Troubleshooting

| Issue | Action |
|-------|--------|
| Deploy fails at migrate | Activity → `db-migrate` logs; check app-level `DB_*` |
| Jobs stuck | `tanooki2` logs; pending jobs SQL |
| Worker OOM | Worker needs 1 Gi |
| Search broken | `ELASTICSEARCH_URL` on DO |
| Cron code old | `cap production deploy` (until F cutover) |

**Key files:** `searchkick.rb`, `puma.rb`, `bin/jobs`, `bin/release`, `recurring.yml` (`schedule.rb` → remove after F)
