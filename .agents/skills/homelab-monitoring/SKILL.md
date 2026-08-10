---
name: homelab-monitoring
description: Use when troubleshooting homelab uptime, Gatus checks, Grafana dashboards, Prometheus metrics, Loki or Caddy logs, Dozzle container logs, ntfy alerts, or monitoring services on the engineering host.
---

# Homelab Monitoring

Use this skill to investigate service availability and performance with the monitoring stack on `engineering`. Start read-only and correlate evidence across Gatus, Prometheus, Loki, and Dozzle before changing configuration or host state.

## Environment

| Service | Address | Access |
| --- | --- | --- |
| Gatus | `https://gatus.rileymathews.com` | Read-only status APIs require no authentication |
| Grafana | `https://grafana.rileymathews.com` | `/api/health` is public; dashboard, search, and datasource APIs require login |
| Prometheus | `http://engineering:9001` | Direct read-only HTTP API over Tailscale |
| Loki | `http://engineering:3100` | Direct read-only HTTP API over Tailscale; authentication is disabled |
| Dozzle | `https://dozzle.rileymathews.com` | Internal read-only APIs require no authentication |
| ntfy | `https://ntfy.rileymathews.com` | Health API requires no authentication |

These names are available on the Tailnet. Public-looking monitoring names resolve to the `engineering` Tailscale address. If direct access fails, check `tailscale status`, DNS resolution, and SSH access to `engineering` before concluding that the monitoring service is down.

Important repository sources:

- `hosts/vms/engineering/configuration.nix` defines Grafana, Prometheus, Loki, scrape targets, ports, datasources, and dashboards.
- `modules/gatus/config.yml` defines Gatus checks, backup heartbeats, intervals, and alerting.
- `modules/gatus/default.nix` defines Gatus service exposure and secrets.
- `modules/caddy-multi-proxy/default.nix` defines Caddy metrics and Alloy shipping of Caddy access logs to Loki.
- `modules/dozzle/default.nix` defines Dozzle and its remote agents.
- `hosts/vms/engineering/*dashboard.json` contains proven PromQL and LogQL used by provisioned dashboards.

## Safety

- Default to `GET` requests and read-only SSH commands.
- Never send a Gatus external heartbeat during investigation. `POST /api/v1/endpoints/<id>/external` changes monitoring state and can suppress or resolve alerts.
- Never publish to ntfy during investigation.
- Port `2019` on Caddy is both a metrics endpoint and an administrative API. Do not query or call Caddy admin routes other than the read-only `/metrics` endpoint, and normally use Prometheus instead.
- Do not invoke Dozzle container actions, shell, attach, or exec routes. Actions and shell are disabled in the current configuration, but do not rely on that protection.
- Do not try default Grafana passwords or inspect its user database. Ask for a service-account token only if the user specifically needs Grafana-managed dashboards or resources queried through the Grafana API.
- Bound all log queries by time, host/service, and result count. Start with 15 minutes or one hour and at most 100-200 entries.
- Prefer aggregate Loki queries before retrieving raw access logs. URLs, query strings, headers, client addresses, and application logs may contain sensitive data; redact them in reports.
- Treat `worf`, `enterprise`, and production client services as especially sensitive. Read logs narrowly and never restart or reconfigure them merely to gather diagnostics.
- Prefer declarative fixes in this repository. Do not mutate a live host unless the user explicitly requests the operational action.

## Investigation Workflow

1. Establish the affected service, host, symptom, and UTC time window. If the user gives local time, preserve it in the report and convert it to UTC for queries.
2. Check Gatus to determine whether the service is currently failing, when state transitions occurred, and whether a backup heartbeat is stale.
3. Check Prometheus target health before trusting missing metrics. Then inspect CPU, memory, disk, networking, systemd, Podman, or Caddy metrics for the affected period.
4. Check Loki for HTTP status, request volume, latency clues, and Caddy routing behavior. Loki contains Caddy access logs, not general application or system logs.
5. Check bounded Dozzle logs for containerized applications. Prefer direct SSH `journalctl` or `podman logs` when Dozzle discovery is cumbersome or the host is not configured as a Dozzle agent.
6. Correlate timestamps. A Gatus failure plus Caddy `502` responses and an unhealthy Prometheus target means something different from a Gatus timeout with no request reaching Caddy.
7. Inspect repository configuration before proposing a fix. Distinguish configuration gaps from live incidents.

## Quick Health Check

Use these checks first:

```bash
curl -sS --max-time 10 https://gatus.rileymathews.com/api/v1/endpoints/statuses \
  | jq '[.[] | {group, name, key, latest: .results[-1]}]'

curl -sS --max-time 10 http://engineering:9001/-/ready

curl -sS --max-time 10 http://engineering:3100/ready

curl -sS --max-time 10 https://grafana.rileymathews.com/api/health | jq .

curl -sS --max-time 10 https://dozzle.rileymathews.com/healthcheck

curl -sS --max-time 10 https://ntfy.rileymathews.com/v1/health | jq .
```

If a direct backend request fails but SSH works, query it locally on engineering:

```bash
ssh engineering 'curl -sS http://127.0.0.1:9001/-/ready'
ssh engineering 'curl -sS http://127.0.0.1:3100/ready'
ssh engineering 'systemctl is-active gatus grafana prometheus loki'
```

## Gatus

### Current Status

Gatus currently checks ordinary service endpoints every 30 seconds and keeps the latest 50 results in its status response. Backup external endpoints receive approximately daily heartbeats. Do not infer long-term uptime solely from the 50 recent samples; use `events`, uptime endpoints, and the incident time window.

Summarize all endpoints without dumping every sample:

```bash
curl -sS --max-time 15 \
  https://gatus.rileymathews.com/api/v1/endpoints/statuses \
  | jq '[.[] | {
      group,
      name,
      key,
      samples: (.results | length),
      latest: (.results[-1] | {success, status, timestamp, duration, errors})
    }]'
```

Find endpoints with a failure in the returned sample window:

```bash
curl -sS --max-time 15 \
  https://gatus.rileymathews.com/api/v1/endpoints/statuses \
  | jq '[.[]
      | select(any(.results[]; .success == false))
      | {
          group,
          name,
          failures: ([.results[] | select(.success == false)] | length),
          latest_failure: ([.results[] | select(.success == false)][-1])
        }
    ]'
```

Endpoint keys use lowercased `<group>_<name>`, for example `services_grafana` and `backups_forgejo-backup`. Query one endpoint, including persisted health transitions:

```bash
curl -sS --max-time 15 \
  https://gatus.rileymathews.com/api/v1/endpoints/services_grafana/statuses \
  | jq '{
      name,
      group,
      key,
      latest: .results[-1],
      samples: (.results | length),
      recent_events: .events[-10:]
    }'
```

Validated uptime and response-time endpoints return scalar values:

```bash
curl -sS --max-time 15 \
  https://gatus.rileymathews.com/api/v1/endpoints/services_grafana/uptimes/24h

curl -sS --max-time 15 \
  https://gatus.rileymathews.com/api/v1/endpoints/services_grafana/response-times/24h
```

Common durations are `1h`, `24h`, `7d`, and `30d`. Verify unsupported durations rather than assuming newer Gatus API features exist on the deployed version.

### Interpreting Results

- `duration` in status JSON is nanoseconds. Divide by `1000000` for milliseconds.
- A normal HTTP check includes `status`, `hostname`, `conditionResults`, `success`, and `timestamp`.
- External backup heartbeats have duration `0` and may not contain an HTTP status.
- Inspect failed `conditionResults` to separate status-code, certificate-expiration, body, and latency failures.
- Compare stale backup heartbeat timestamps with the expected `25h` interval in `modules/gatus/config.yml`.
- Gatus checks public ingress. A successful check proves the configured URL returned expected conditions, not that every internal dependency is healthy.

## Prometheus

Grafana's provisioned Prometheus datasource points to the same backend at `http://127.0.0.1:9001`. Prefer the direct Prometheus API because Grafana API authentication is unavailable to CLI investigations.

### Query API

Run an instant PromQL query:

```bash
curl -sS --max-time 20 --get \
  --data-urlencode 'query=up' \
  http://engineering:9001/api/v1/query \
  | jq .
```

Run a bounded range query by supplying RFC3339 timestamps and a step:

```bash
curl -sS --max-time 30 --get \
  --data-urlencode 'query=100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))' \
  --data-urlencode 'start=2026-07-14T16:00:00Z' \
  --data-urlencode 'end=2026-07-14T17:00:00Z' \
  --data-urlencode 'step=60s' \
  http://engineering:9001/api/v1/query_range \
  | jq .
```

Use a coarser step for longer windows. Do not request high-resolution multi-day data unless needed.

### Target Health

Always check scrape health before interpreting absent data:

```bash
curl -sS --max-time 15 \
  http://engineering:9001/api/v1/targets \
  | jq '[.data.activeTargets[] | {
      job: .labels.job,
      instance: .labels.instance,
      health,
      lastError,
      lastScrape
    }]'
```

Show only unhealthy targets:

```bash
curl -sS --max-time 15 \
  http://engineering:9001/api/v1/targets \
  | jq '[.data.activeTargets[]
      | select(.health != "up")
      | {job: .labels.job, instance: .labels.instance, health, lastError}
    ]'
```

The scrape jobs are:

- `engineering_scrape` for node exporter on selected hosts, port `9002`.
- `caddy` for Caddy metrics on selected hosts, port `2019`.
- `podman` for Podman exporter on selected hosts, port `9882`.

Prometheus does not scrape every Tailnet host. Read the current `scrapeConfigs` before treating a missing series as an outage. The repository currently contains stale `borg` and `couchdb` targets that fail DNS; verify the configuration is still unchanged before dismissing or reporting them as known noise. The local engineering node-exporter instance appears as `127.0.0.1:9002` rather than `engineering:9002`.

### Useful PromQL

Healthy target count by job:

```promql
count by (job) (up == 1)
```

CPU usage percentage by host:

```promql
100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))
```

Memory usage percentage by host:

```promql
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

Root filesystem usage percentage:

```promql
100 * (1 - node_filesystem_avail_bytes{mountpoint="/",fstype!="rootfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!="rootfs"})
```

Failed systemd units:

```promql
node_systemd_unit_state{state="failed"} == 1
```

Podman container inventory:

```promql
podman_container_info
```

Podman containers not in running state `2`:

```promql
podman_container_info * on(instance, id) group_left() (podman_container_state != 2)
```

Podman memory usage joined with names:

```promql
podman_container_info * on(instance, id) group_left() podman_container_mem_usage_bytes
```

Unhealthy Caddy reverse-proxy upstreams:

```promql
caddy_reverse_proxy_upstreams_healthy == 0
```

Caddy request rate by virtual host:

```promql
sum by (host) (rate(caddy_http_requests_total{job="caddy"}[5m]))
```

Caddy p95 request duration by virtual host:

```promql
histogram_quantile(0.95, sum by (le, host) (rate(caddy_http_request_duration_seconds_bucket{job="caddy"}[5m])))
```

Inspect available metric names and runtime information when uncertain:

```bash
curl -sS --max-time 15 \
  http://engineering:9001/api/v1/label/__name__/values \
  | jq '{count: (.data | length), metrics: .data}'

curl -sS --max-time 15 \
  http://engineering:9001/api/v1/status/runtimeinfo \
  | jq .
```

## Loki

Loki receives JSON Caddy access logs from Grafana Alloy on hosts using `modules/caddy-multi-proxy`. It does not receive application container logs, systemd journals, or general host logs. Retention is configured for 30 days.

Known labels include `job`, `instance`, `host`, `method`, `status`, `filename`, and `service_name`. Use label and series discovery instead of guessing:

```bash
curl -sS --max-time 15 \
  http://engineering:3100/loki/api/v1/labels \
  | jq .

curl -sS --max-time 15 \
  http://engineering:3100/loki/api/v1/label/instance/values \
  | jq .
```

The label-values endpoint defaults to a recent window. For historical coverage, query series with explicit nanosecond timestamps:

```bash
curl -sS --max-time 20 --get \
  --data-urlencode 'match[]={job="caddy"}' \
  --data-urlencode "start=$(date --date='30 days ago' +%s%N)" \
  http://engineering:3100/loki/api/v1/series \
  | jq '{
      status,
      instances: ([.data[].instance] | unique),
      hosts: ([.data[].host] | unique),
      series_count: (.data | length)
    }'
```

### Aggregate Before Raw Logs

Count HTTP statuses for one virtual host over the last hour:

```bash
curl -sS --max-time 20 --get \
  --data-urlencode 'query=sum by (status) (count_over_time({job="caddy",host="example.rileymathews.com"}[1h]))' \
  http://engineering:3100/loki/api/v1/query \
  | jq .
```

Count recent server errors by source and virtual host:

```bash
curl -sS --max-time 20 --get \
  --data-urlencode 'query=sum by (instance, host, status) (count_over_time({job="caddy",status=~"5.."}[1h]))' \
  http://engineering:3100/loki/api/v1/query \
  | jq .
```

Compare traffic volume over time with a bounded range query:

```bash
curl -sS --max-time 30 --get \
  --data-urlencode 'query=sum(count_over_time({job="caddy",host="example.rileymathews.com"}[5m]))' \
  --data-urlencode 'start=2026-07-14T16:00:00Z' \
  --data-urlencode 'end=2026-07-14T17:00:00Z' \
  --data-urlencode 'step=5m' \
  http://engineering:3100/loki/api/v1/query_range \
  | jq .
```

### Bounded Raw Logs

Retrieve at most 100 error requests for one host in a precise UTC window:

```bash
curl -sS --max-time 30 --get \
  --data-urlencode 'query={job="caddy",host="example.rileymathews.com",status=~"5.."} | json' \
  --data-urlencode 'start=2026-07-14T16:00:00Z' \
  --data-urlencode 'end=2026-07-14T17:00:00Z' \
  --data-urlencode 'limit=100' \
  --data-urlencode 'direction=backward' \
  http://engineering:3100/loki/api/v1/query_range \
  | jq '{
      status,
      entries: [
        .data.result[] as $result
        | $result.values[]
        | {
            timestamp_ns: .[0],
            labels: ($result.stream | {instance, host, method, status}),
            log: (.[1] | fromjson? | {
              status,
              request: {host: .request.host, method: .request.method, uri: .request.uri},
              duration
            })
          }
      ]
    }'
```

Before reporting raw entries, strip query strings and redact credentials, tokens, cookies, authorization headers, personal information, and client IP addresses. Report patterns and representative timestamps instead of reproducing complete requests.

Loki `/ready` can briefly return `503` while an ingester transitions. Retry once after several seconds and test a small label or query API before declaring Loki unavailable.

## Grafana

Grafana is useful interactively but is not the preferred automation interface in this environment.

- The public health endpoint is `GET /api/health`.
- `/api/user`, `/api/search`, `/api/datasources`, dashboard APIs, and frontend settings require authentication and return `401` without a session or token.
- The provisioned Prometheus datasource UID is `PBFA97CFB590B2093`.
- The provisioned Loki datasource UID is `Loki`.
- Provisioned dashboards cover node exporter, Podman exporter, and Caddy observability.
- Grafana provisions a disk-usage alert from `hosts/vms/engineering/configuration.nix`. It notifies the `home-server-alerts` ntfy topic after a writable filesystem remains above 85% usage for five minutes.
- There is no configured Tempo tracing backend, external Alertmanager, or Prometheus rule set in this repository.

Query Prometheus and Loki directly unless the task specifically concerns Grafana dashboard definitions, users, folders, or Grafana-managed resources. For dashboard behavior, inspect the JSON files in `hosts/vms/engineering` before requesting credentials.

## Dozzle

Dozzle supplements Loki with application container logs. It connects to remote agents listed in `modules/dozzle/default.nix`. Agent membership is configuration-specific; do not assume every host or container appears there.

Check health and version:

```bash
curl -sS --max-time 10 https://dozzle.rileymathews.com/healthcheck
curl -sS --max-time 10 https://dozzle.rileymathews.com/api/version
```

Dozzle does not provide a stable, documented container-list endpoint in the deployed version. Its UI discovers dynamic host IDs and container IDs from the SSE event stream. Sample the stream briefly and filter container events rather than printing all live statistics:

```bash
curl -sS --no-buffer --max-time 1 \
  https://dozzle.rileymathews.com/api/events/stream \
  | jq -Rr '
      select(startswith("data: "))
      | ltrimstr("data: ")
      | fromjson?
      | if type == "array" then .[] else . end
      | select(type == "object" and has("host") and has("id") and has("name"))
      | [.host, .id, .name, .state]
      | @tsv
    '
```

The timeout after this one-second SSE sample is expected.

The `host` and `id` values are dynamic identifiers. Do not hardcode identifiers observed in a previous investigation.

Fetch logs only after discovering the current host and container IDs. Always provide `from`, `to`, stdout/stderr, and levels. The response is JSONL and is capped by Dozzle; do not use the unbounded `everything` option.

```bash
curl -sS --max-time 30 --get \
  --data-urlencode 'stdout=1' \
  --data-urlencode 'stderr=1' \
  --data-urlencode 'from=2026-07-14T16:00:00Z' \
  --data-urlencode 'to=2026-07-14T17:00:00Z' \
  --data-urlencode 'levels=error' \
  --data-urlencode 'levels=warn' \
  --data-urlencode 'levels=info' \
  --data-urlencode 'levels=debug' \
  --data-urlencode 'levels=trace' \
  --data-urlencode 'levels=fatal' \
  --data-urlencode 'levels=unknown' \
  'https://dozzle.rileymathews.com/api/hosts/<host-id>/containers/<container-id>/logs'
```

Dozzle is an internal UI API and may change between versions. If discovery or log parsing becomes unreliable, use direct host diagnostics rather than reverse-engineering mutating routes.

## Direct Host Diagnostics

Use SSH when metrics and ingress logs identify the host but not the root cause. Root SSH is available on NixOS VMs, but a normal `ssh <host>` may be enough for read-only commands depending on access.

```bash
ssh root@<host> 'systemctl --failed --no-pager'
ssh root@<host> 'systemctl status <unit> --no-pager'
ssh root@<host> 'journalctl -u <unit> --since "1 hour ago" --no-pager -n 200'
ssh root@<host> 'podman ps --all --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
ssh root@<host> 'podman logs --since 1h --tail 200 <container>'
```

Do not restart units or containers as a diagnostic shortcut. If logs suggest a configuration problem, inspect the matching Nix module and host configuration and make the smallest declarative correction.

## Common Interpretations

- Gatus failure plus Caddy `502`/`503`: inspect Caddy upstream health, container state, and application logs.
- Gatus timeout with no matching Loki request: investigate DNS, TLS, wormhole/relay routing, Tailnet connectivity, or an upstream path before the destination Caddy host.
- Gatus success plus user-visible failure: the health check may be too shallow or the failure may affect a route/dependency not covered by its conditions.
- Prometheus target down with DNS error: inspect `scrapeConfigs` for a renamed or retired host before treating it as a live outage.
- Prometheus target down with connection refused: verify exporter service state and firewall on the target host.
- Missing Loki logs with healthy Caddy metrics: verify the host uses the Caddy module, Alloy is active, matching access log files exist, and traffic actually reached that virtual host.
- Loki has HTTP errors but the container is healthy: inspect upstream routing, application response logs, dependency health, and whether Caddy is targeting the correct port.
- Backup heartbeat stale: verify the configured Gatus external endpoint exists, then inspect the backup timer/service and its logs. Do not manually send a successful heartbeat to hide the stale state.

## Reporting

Report evidence in UTC and include:

- Affected service and investigation window.
- Gatus current state, latest result time, and relevant health transitions.
- Prometheus scrape health and the metrics that support the conclusion.
- Loki request counts/statuses and representative timestamps, without sensitive raw request data.
- Container or systemd log findings, bounded to the relevant period.
- Whether the issue is live, recovered, intermittent, a monitoring-coverage gap, or stale configuration.
- Any repository change proposed or made, and any remaining verification needed.

Do not report an endpoint as healthy solely because its process is active. Prefer an end-to-end conclusion backed by Gatus plus the relevant metrics and logs.
