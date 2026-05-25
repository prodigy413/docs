```
Dockerfile

FROM registry.access.redhat.com/ubi10/python-314-minimal:10.2-1777970431

USER root

ARG OC_VERSION=4.18.42

RUN microdnf install -y tar gzip \
    && curl -L -o /tmp/openshift-client-linux.tar.gz \
       https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz \
    && tar -xzf /tmp/openshift-client-linux.tar.gz -C /tmp \
    && install -o root -g root -m 0755 /tmp/oc /usr/local/bin/oc \
    && rm -f /tmp/* \
    && microdnf remove -y tar gzip \
    && microdnf clean all \
    && mkdir -p /data \
    && chown 1001:1001 /data

COPY ./status_checker.py /app/

USER 1001

CMD ["python3", "/app/status_checker.py"]









status_checker.py

#!/usr/bin/env python3
"""
oc (OpenShift CLI) の実行結果から HTML レポートを生成するスクリプト

実行する内容:
  # Worker Nodes
  oc get nodes

  # Calico Pods
  oc get deploy,pod -n calico-apiserver
  oc get deploy,ds,pod -n calico-system

  # Application Pods
  oc get deploymentconfig -n application-prd-1
  oc get pod              -n application-prd-1
  oc get deploymentconfig -n sorry-prd-1
  oc get pod              -n sorry-prd-1

  # Batch Pods
  oc get pod -n batch-prd-1

出力:
  ./YYYY/MM/DD/YYYY_MMDD_HHMM_k8s_check_report.html

使い方:
  python3 k8s_report.py
"""

from __future__ import annotations

import html
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Callable


# Batch namespace で Running 状態が「長すぎる」と判定する閾値 (秒)
BATCH_RUNNING_TOO_LONG_SEC = 3600  # 1 時間


# ----------------------------------------------------------------------------
# kubectl 実行
# ----------------------------------------------------------------------------

@dataclass
class CommandResult:
    """kubectl コマンドの実行結果"""
    label: str
    command: list[str]
    stdout: str
    stderr: str
    returncode: int
    parsed: dict[str, Any] | None = None

    @property
    def ok(self) -> bool:
        return self.returncode == 0 and self.parsed is not None

    def items_of_kind(self, kind: str) -> list[dict]:
        if not self.parsed:
            return []
        return [it for it in self.parsed.get("items", []) if it.get("kind") == kind]


def run_oc(args: list[str], label: str) -> CommandResult:
    """oc を JSON 出力で実行して結果を返す"""
    cmd = ["oc"] + args + ["-o", "json"]

    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, check=False, timeout=60,
        )
    except FileNotFoundError:
        return CommandResult(label, cmd, "", "oc コマンドが見つかりません", 127)
    except subprocess.TimeoutExpired:
        return CommandResult(label, cmd, "", "oc がタイムアウトしました (60s)", 124)

    parsed: dict[str, Any] | None = None
    if proc.returncode == 0 and proc.stdout.strip():
        try:
            parsed = json.loads(proc.stdout)
        except json.JSONDecodeError as e:
            return CommandResult(label, cmd, proc.stdout, f"JSON parse error: {e}", 1)

    return CommandResult(label, cmd, proc.stdout, proc.stderr, proc.returncode, parsed)


# ----------------------------------------------------------------------------
# データ抽出
# ----------------------------------------------------------------------------

def _parse_ts(ts: str | None) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None


def _age_str(created: datetime | None) -> str:
    """kubectl と同じ s/m/h/d 表記"""
    if not created:
        return "-"
    now = datetime.now(created.tzinfo)
    secs = int((now - created).total_seconds())
    if secs < 60:
        return f"{secs}s"
    mins = secs // 60
    if mins < 60:
        return f"{mins}m"
    hours = mins // 60
    if hours < 48:
        return f"{hours}h"
    days = hours // 24
    return f"{days}d"


def _age_seconds(created: datetime | None) -> int:
    if not created:
        return 0
    return int((datetime.now(created.tzinfo) - created).total_seconds())


def _restart_age_str(last_restart: datetime | None) -> str:
    """
    kubectl/oc の RESTARTS 列で使われる経過時間表記。
    通常の AGE より細かく、最大 2 単位の複合表記:
      45s / 3m43s / 1h12m / 2d3h
    """
    if not last_restart:
        return ""
    now = datetime.now(last_restart.tzinfo)
    secs = int((now - last_restart).total_seconds())
    if secs < 0:
        secs = 0
    if secs < 60:
        return f"{secs}s"
    mins, s = divmod(secs, 60)
    if mins < 60:
        return f"{mins}m{s}s" if s else f"{mins}m"
    hours, m = divmod(mins, 60)
    if hours < 48:
        return f"{hours}h{m}m" if m else f"{hours}h"
    days, h = divmod(hours, 24)
    return f"{days}d{h}h" if h else f"{days}d"


def extract_nodes(items: list[dict]) -> list[dict[str, Any]]:
    rows = []
    for item in items:
        meta = item.get("metadata", {}) or {}
        status = item.get("status", {}) or {}
        spec = item.get("spec", {}) or {}

        ready = "Unknown"
        for cond in status.get("conditions", []) or []:
            if cond.get("type") == "Ready":
                ready = "Ready" if cond.get("status") == "True" else "NotReady"
                break
        if spec.get("unschedulable"):
            ready += ",SchedulingDisabled"

        labels = meta.get("labels", {}) or {}
        roles = [
            (k.split("/", 1)[1] or "master")
            for k in labels
            if k.startswith("node-role.kubernetes.io/")
        ]
        role_str = ",".join(roles) if roles else "<none>"

        node_info = status.get("nodeInfo", {}) or {}
        created = _parse_ts(meta.get("creationTimestamp"))

        rows.append({
            "name": meta.get("name", ""),
            "status": ready,
            "roles": role_str,
            "age": _age_str(created),
            "version": node_info.get("kubeletVersion", ""),
            "healthy": ready.startswith("Ready") and "SchedulingDisabled" not in ready,
        })
    return rows


def extract_deployments(items: list[dict]) -> list[dict[str, Any]]:
    rows = []
    for item in items:
        meta = item.get("metadata", {}) or {}
        spec = item.get("spec", {}) or {}
        status = item.get("status", {}) or {}
        desired = spec.get("replicas", 0) or 0
        ready = status.get("readyReplicas", 0) or 0
        up_to_date = status.get("updatedReplicas", 0) or 0
        available = status.get("availableReplicas", 0) or 0
        rows.append({
            "name": meta.get("name", ""),
            "ready": f"{ready}/{desired}",
            "up_to_date": str(up_to_date),
            "available": str(available),
            "age": _age_str(_parse_ts(meta.get("creationTimestamp"))),
            "healthy": ready == desired and desired > 0,
        })
    return rows


def extract_deploymentconfigs(items: list[dict]) -> list[dict[str, Any]]:
    """
    OpenShift DeploymentConfig (DC) を抽出。
    `oc get dc` の表示列は: NAME / REVISION / DESIRED / CURRENT / TRIGGERED BY
    Trigger は spec.triggers[].type をカンマ区切りで表示する。
    """
    rows = []
    for item in items:
        meta = item.get("metadata", {}) or {}
        spec = item.get("spec", {}) or {}
        status = item.get("status", {}) or {}

        desired = spec.get("replicas", 0) or 0
        # DC では replicas (current) と readyReplicas を区別する
        current = status.get("replicas", 0) or 0
        ready = status.get("readyReplicas", 0) or 0
        revision = status.get("latestVersion", 0) or 0

        triggers = spec.get("triggers", []) or []
        trigger_str = ",".join(
            t.get("type", "") for t in triggers if t.get("type")
        ) or "<none>"

        rows.append({
            "name": meta.get("name", ""),
            "revision": str(revision),
            "desired": str(desired),
            "current": str(current),
            "ready": f"{ready}/{desired}",
            "triggered_by": trigger_str,
            "age": _age_str(_parse_ts(meta.get("creationTimestamp"))),
            "healthy": ready == desired and desired > 0,
        })
    return rows


def extract_daemonsets(items: list[dict]) -> list[dict[str, Any]]:
    rows = []
    for item in items:
        meta = item.get("metadata", {}) or {}
        status = item.get("status", {}) or {}
        desired = status.get("desiredNumberScheduled", 0) or 0
        current = status.get("currentNumberScheduled", 0) or 0
        ready = status.get("numberReady", 0) or 0
        up_to_date = status.get("updatedNumberScheduled", 0) or 0
        available = status.get("numberAvailable", 0) or 0
        rows.append({
            "name": meta.get("name", ""),
            "desired": str(desired),
            "current": str(current),
            "ready": str(ready),
            "up_to_date": str(up_to_date),
            "available": str(available),
            "age": _age_str(_parse_ts(meta.get("creationTimestamp"))),
            "healthy": ready == desired and desired > 0,
        })
    return rows


def extract_pods(items: list[dict],
                 exclude_completed: bool = False,
                 mode: str = "default") -> list[dict[str, Any]]:
    """
    Pod 情報を抽出。
    - exclude_completed=True: phase == 'Succeeded' を除外
      (元コマンド: awk 'NR==1 || $3!="Completed"')
    - mode="batch": Running 状態で 1h 以上経過した Pod を異常扱い (long_running=True)
    """
    rows = []
    for item in items:
        meta = item.get("metadata", {}) or {}
        status = item.get("status", {}) or {}
        spec = item.get("spec", {}) or {}

        if exclude_completed and status.get("phase") == "Succeeded":
            continue

        containers = spec.get("containers", []) or []
        container_statuses = status.get("containerStatuses", []) or []

        total = len(containers)
        ready_count = sum(1 for cs in container_statuses if cs.get("ready"))
        restarts = sum(cs.get("restartCount", 0) for cs in container_statuses)

        # 最新の再起動時刻 (各コンテナの lastState.terminated.finishedAt の最大値)
        # kubectl/oc が "8 (3m43s ago)" のように表示するための時刻情報
        last_restart_at: datetime | None = None
        for cs in container_statuses:
            last_state = cs.get("lastState", {}) or {}
            terminated = last_state.get("terminated") or {}
            finished_at = _parse_ts(terminated.get("finishedAt"))
            if finished_at and (last_restart_at is None or finished_at > last_restart_at):
                last_restart_at = finished_at

        phase = status.get("phase", "Unknown")
        display_status = phase
        for cs in container_statuses:
            state = cs.get("state", {}) or {}
            waiting = state.get("waiting") or {}
            terminated = state.get("terminated") or {}
            if waiting.get("reason"):
                display_status = waiting["reason"]
                break
            if terminated.get("reason") and terminated["reason"] != "Completed":
                display_status = terminated["reason"]
                break
        if phase == "Succeeded":
            display_status = "Completed"

        created = _parse_ts(meta.get("creationTimestamp"))
        age_sec = _age_seconds(created)

        # 通常の健全性判定: Running で全コンテナ Ready、または Completed (Job 正常終了)
        is_completed = display_status == "Completed"
        healthy = is_completed or (
            display_status == "Running" and ready_count == total
        )

        # Batch モード: Running で 1h 以上経過したら長時間 Running として赤判定
        long_running = (
            mode == "batch"
            and display_status == "Running"
            and age_sec >= BATCH_RUNNING_TOO_LONG_SEC
        )
        if long_running:
            healthy = False

        rows.append({
            "name": meta.get("name", ""),
            "ready": f"{ready_count}/{total}",
            "status": display_status,
            "restarts": restarts,
            "last_restart_str": _restart_age_str(last_restart_at) if restarts > 0 else "",
            "age": _age_str(created),
            "age_sec": age_sec,
            "healthy": healthy,
            "long_running": long_running,
            "is_completed": is_completed,
        })
    return rows


# ----------------------------------------------------------------------------
# HTML 生成
# ----------------------------------------------------------------------------

CSS = """
:root {
  --bg: #0f1419;
  --panel: #1a1f29;
  --panel-2: #232a36;
  --border: #2d3543;
  --text: #e6edf3;
  --muted: #8b949e;
  --accent: #58a6ff;
  --ok: #3fb950;
  --warn: #d29922;
  --err: #f85149;
  --mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Hiragino Sans",
               "Yu Gothic UI", Meiryo, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.5;
}
.container { max-width: 1400px; margin: 0 auto; padding: 32px 24px; }
header { border-bottom: 1px solid var(--border); padding-bottom: 20px; margin-bottom: 28px; }
h1 { font-size: 24px; margin: 0 0 8px; font-weight: 600; letter-spacing: -0.01em; }
.meta { color: var(--muted); font-size: 13px; font-family: var(--mono); }
.summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  margin-bottom: 32px;
}
.card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 14px 18px; }
.card .label { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; }
.card .value { font-size: 26px; font-weight: 600; margin-top: 4px; font-family: var(--mono); }
.card.ok .value { color: var(--ok); }
.card.warn .value { color: var(--warn); }
.card.err .value { color: var(--err); }

.section-group { margin-bottom: 40px; }
.section-group > h2.group {
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--accent);
  border-bottom: 1px solid var(--accent);
  padding-bottom: 6px;
  margin: 24px 0 16px;
  font-weight: 600;
}
section.block { margin-bottom: 20px; }
section.block h3 {
  font-size: 14px;
  font-weight: 600;
  margin: 0 0 10px;
  padding-bottom: 6px;
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 8px;
}
section.block h3 .cmd {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
  font-weight: 400;
  margin-left: auto;
  background: var(--panel-2);
  padding: 2px 8px;
  border-radius: 4px;
  border: 1px solid var(--border);
}
.table-wrap { overflow-x: auto; background: var(--panel); border: 1px solid var(--border); border-radius: 8px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
th, td { text-align: left; padding: 9px 14px; white-space: nowrap; border-bottom: 1px solid var(--border); }
th {
  background: var(--panel-2);
  font-weight: 600;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--muted);
}
tr:last-child td { border-bottom: none; }
tr:hover td { background: rgba(255,255,255,0.02); }
tr.row-alert td { background: rgba(248,81,73,0.06); }
tr.row-alert:hover td { background: rgba(248,81,73,0.1); }
td.mono { font-family: var(--mono); }
.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  font-family: var(--mono);
}
.badge.ok { background: rgba(63,185,80,0.15); color: var(--ok); }
.badge.warn { background: rgba(210,153,34,0.15); color: var(--warn); }
.badge.err { background: rgba(248,81,73,0.15); color: var(--err); }
.badge.muted { background: rgba(139,148,158,0.15); color: var(--muted); }
.muted-inline { color: var(--muted); font-family: var(--mono); font-size: 11px; }
.empty { padding: 18px; color: var(--muted); text-align: center; font-size: 13px; }
.error {
  background: rgba(248,81,73,0.1);
  border: 1px solid var(--err);
  color: var(--err);
  padding: 12px 16px;
  border-radius: 8px;
  font-family: var(--mono);
  font-size: 12px;
  white-space: pre-wrap;
}
.note { font-size: 11px; color: var(--muted); margin-top: 6px; font-family: var(--mono); }
footer {
  margin-top: 48px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-size: 12px;
  text-align: center;
}
"""


def _h(s: Any) -> str:
    return html.escape(str(s) if s is not None else "")


def _status_badge(text: str, healthy: bool | None = None) -> str:
    t = text.lower()
    if healthy is True:
        cls = "ok"
    elif healthy is False:
        cls = "err"
    elif t in ("ready", "running", "active", "bound"):
        cls = "ok"
    elif t in ("notready", "failed", "error", "crashloopbackoff",
               "imagepullbackoff", "errimagepull", "evicted", "oomkilled"):
        cls = "err"
    elif t in ("pending", "containercreating", "podinitializing",
               "terminating", "init", "unknown"):
        cls = "warn"
    elif t == "completed":
        cls = "muted"
    else:
        cls = "ok"
    return f'<span class="badge {cls}">{_h(text)}</span>'


def render_nodes_table(rows: list[dict]) -> str:
    if not rows:
        return '<div class="empty">No nodes found.</div>'
    body = []
    for r in rows:
        row_cls = "" if r["healthy"] else ' class="row-alert"'
        body.append(
            f"<tr{row_cls}>"
            f'<td class="mono">{_h(r["name"])}</td>'
            f'<td>{_status_badge(r["status"], r["healthy"])}</td>'
            f'<td class="mono">{_h(r["roles"])}</td>'
            f'<td class="mono">{_h(r["age"])}</td>'
            f'<td class="mono">{_h(r["version"])}</td>'
            "</tr>"
        )
    return (
        '<div class="table-wrap"><table>'
        "<thead><tr>"
        "<th>NAME</th><th>STATUS</th><th>ROLES</th><th>AGE</th><th>VERSION</th>"
        "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div>"
    )


def render_deploy_table(rows: list[dict]) -> str:
    if not rows:
        return '<div class="empty">No deployments found.</div>'
    body = []
    for r in rows:
        row_cls = "" if r["healthy"] else ' class="row-alert"'
        body.append(
            f"<tr{row_cls}>"
            f'<td class="mono">{_h(r["name"])}</td>'
            f'<td>{_status_badge(r["ready"], r["healthy"])}</td>'
            f'<td class="mono">{_h(r["up_to_date"])}</td>'
            f'<td class="mono">{_h(r["available"])}</td>'
            f'<td class="mono">{_h(r["age"])}</td>'
            "</tr>"
        )
    return (
        '<div class="table-wrap"><table>'
        "<thead><tr>"
        "<th>NAME</th><th>READY</th><th>UP-TO-DATE</th><th>AVAILABLE</th><th>AGE</th>"
        "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div>"
    )


def render_dc_table(rows: list[dict]) -> str:
    """OpenShift DeploymentConfig 用テーブル"""
    if not rows:
        return '<div class="empty">No deploymentconfigs found.</div>'
    body = []
    for r in rows:
        row_cls = "" if r["healthy"] else ' class="row-alert"'
        body.append(
            f"<tr{row_cls}>"
            f'<td class="mono">{_h(r["name"])}</td>'
            f'<td class="mono">{_h(r["revision"])}</td>'
            f'<td>{_status_badge(r["ready"], r["healthy"])}</td>'
            f'<td class="mono">{_h(r["current"])}</td>'
            f'<td class="mono">{_h(r["triggered_by"])}</td>'
            f'<td class="mono">{_h(r["age"])}</td>'
            "</tr>"
        )
    return (
        '<div class="table-wrap"><table>'
        "<thead><tr>"
        "<th>NAME</th><th>REVISION</th><th>READY</th><th>CURRENT</th>"
        "<th>TRIGGERED BY</th><th>AGE</th>"
        "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div>"
    )


def render_ds_table(rows: list[dict]) -> str:
    if not rows:
        return '<div class="empty">No daemonsets found.</div>'
    body = []
    for r in rows:
        row_cls = "" if r["healthy"] else ' class="row-alert"'
        body.append(
            f"<tr{row_cls}>"
            f'<td class="mono">{_h(r["name"])}</td>'
            f'<td class="mono">{_h(r["desired"])}</td>'
            f'<td class="mono">{_h(r["current"])}</td>'
            f'<td>{_status_badge(r["ready"], r["healthy"])}</td>'
            f'<td class="mono">{_h(r["up_to_date"])}</td>'
            f'<td class="mono">{_h(r["available"])}</td>'
            f'<td class="mono">{_h(r["age"])}</td>'
            "</tr>"
        )
    return (
        '<div class="table-wrap"><table>'
        "<thead><tr>"
        "<th>NAME</th><th>DESIRED</th><th>CURRENT</th><th>READY</th>"
        "<th>UP-TO-DATE</th><th>AVAILABLE</th><th>AGE</th>"
        "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div>"
    )


def render_pod_table(rows: list[dict], highlight_long_running: bool = False) -> str:
    if not rows:
        return '<div class="empty">No pods found.</div>'
    body = []
    for r in rows:
        restarts = r["restarts"] if isinstance(r["restarts"], int) else 0
        last_restart_str = r.get("last_restart_str", "")

        # "8 (3m43s ago)" 形式: restart 回数 + 直近の再起動経過時間
        if restarts > 0:
            if last_restart_str:
                restart_html = (
                    f'<span class="badge warn">{_h(restarts)}</span>'
                    f' <span class="muted-inline">({_h(last_restart_str)} ago)</span>'
                )
            else:
                restart_html = f'<span class="badge warn">{_h(restarts)}</span>'
        else:
            restart_html = f'<span class="mono">{_h(restarts)}</span>'
        # Batch モードで long_running の場合は行と AGE を強調
        long_running = r.get("long_running", False)
        row_cls = ""
        if (highlight_long_running and long_running) or (not r["healthy"]):
            row_cls = ' class="row-alert"'
        age_html = (
            f'<span class="badge err">{_h(r["age"])}</span>'
            if highlight_long_running and long_running
            else f'<span class="mono">{_h(r["age"])}</span>'
        )
        # ステータス: long_running の場合は「Running」をエラー色で表示
        if highlight_long_running and long_running:
            status_html = f'<span class="badge err">{_h(r["status"])}</span>'
        else:
            status_html = _status_badge(r["status"], r["healthy"])

        body.append(
            f"<tr{row_cls}>"
            f'<td class="mono">{_h(r["name"])}</td>'
            f'<td>{_status_badge(r["ready"], None if long_running else r["healthy"])}</td>'
            f'<td>{status_html}</td>'
            f"<td>{restart_html}</td>"
            f"<td>{age_html}</td>"
            "</tr>"
        )
    return (
        '<div class="table-wrap"><table>'
        "<thead><tr>"
        "<th>NAME</th><th>READY</th><th>STATUS</th><th>RESTARTS</th><th>AGE</th>"
        "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div>"
    )


def render_error(result: CommandResult) -> str:
    msg = result.stderr.strip() or f"exit code: {result.returncode}"
    cmd_str = " ".join(result.command)
    return (
        f'<div class="error"><strong>Command failed:</strong> {_h(cmd_str)}\n\n{_h(msg)}</div>'
    )


# ----------------------------------------------------------------------------
# レポートビルダー
# ----------------------------------------------------------------------------

@dataclass
class Block:
    title: str
    result: CommandResult
    renderer: Callable[[CommandResult], str]


def build_html(groups: list[tuple[str, list[Block]]],
               summary_cards_html: str) -> str:
    parts: list[str] = []
    for group_title, blocks in groups:
        parts.append('<div class="section-group">')
        parts.append(f'<h2 class="group">{_h(group_title)}</h2>')
        for b in blocks:
            inner = render_error(b.result) if not b.result.ok else b.renderer(b.result)
            parts.append(
                f'<section class="block">'
                f'<h3>{_h(b.title)}<span class="cmd">{_h(b.result.label)}</span></h3>'
                f"{inner}"
                "</section>"
            )
        parts.append("</div>")

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    return f"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Openshift Status Check Report</title>
<style>{CSS}</style>
</head>
<body>
<div class="container">
<header>
<h1>Openshift Status Check Report</h1>
<div class="meta">Generated at {_h(now)}</div>
</header>

<div class="summary">
{summary_cards_html}
</div>

{"".join(parts)}

<footer>Generated by k8s_report.py</footer>
</div>
</body>
</html>
"""


# ----------------------------------------------------------------------------
# レンダラー
# ----------------------------------------------------------------------------

def render_nodes(res: CommandResult) -> str:
    return render_nodes_table(extract_nodes(res.items_of_kind("Node")))


def render_deploys(res: CommandResult) -> str:
    return render_deploy_table(extract_deployments(res.items_of_kind("Deployment")))


def render_dcs(res: CommandResult) -> str:
    return render_dc_table(extract_deploymentconfigs(res.items_of_kind("DeploymentConfig")))


def render_dsets(res: CommandResult) -> str:
    return render_ds_table(extract_daemonsets(res.items_of_kind("DaemonSet")))


def render_pods(res: CommandResult) -> str:
    return render_pod_table(extract_pods(res.items_of_kind("Pod")))


def render_pods_no_completed(res: CommandResult) -> str:
    rows = extract_pods(res.items_of_kind("Pod"), exclude_completed=True)
    return render_pod_table(rows)


def render_pods_batch(res: CommandResult) -> str:
    """Batch namespace 用: Running で 1h 以上経過した Pod を赤強調"""
    rows = extract_pods(res.items_of_kind("Pod"), mode="batch")
    return render_pod_table(rows, highlight_long_running=True)


# ----------------------------------------------------------------------------
# 全コマンド実行
# ----------------------------------------------------------------------------

def collect_all() -> list[tuple[str, list[Block]]]:
    """全 oc コマンドを実行し、グループ化された Block 一覧を返す"""

    # --- Worker Nodes ---
    nodes_res = run_oc(["get", "nodes"], "oc get nodes")
    worker_nodes = [Block("Worker Nodes", nodes_res, render_nodes)]

    # --- Calico Pods ---
    calico_api = run_oc(
        ["get", "deploy,pod", "-n", "calico-apiserver"],
        "oc get deploy,pod -n calico-apiserver",
    )
    calico_sys = run_oc(
        ["get", "deploy,ds,pod", "-n", "calico-system"],
        "oc get deploy,ds,pod -n calico-system",
    )
    calico_blocks = [
        Block("calico-apiserver: Deployments", calico_api, render_deploys),
        Block("calico-apiserver: Pods", calico_api, render_pods),
        Block("calico-system: Deployments", calico_sys, render_deploys),
        Block("calico-system: DaemonSets", calico_sys, render_dsets),
        Block("calico-system: Pods", calico_sys, render_pods),
    ]

    # --- Application Pods (DeploymentConfig + Pod) ---
    app_dc = run_oc(
        ["get", "deploymentconfig", "-n", "application-prd-1"],
        "oc get deploymentconfig -n application-prd-1",
    )
    app_pod = run_oc(
        ["get", "pod", "-n", "application-prd-1"],
        "oc get pod -n application-prd-1",
    )
    sorry_dc = run_oc(
        ["get", "deploymentconfig", "-n", "sorry-prd-1"],
        "oc get deploymentconfig -n sorry-prd-1",
    )
    sorry_pod = run_oc(
        ["get", "pod", "-n", "sorry-prd-1"],
        "oc get pod -n sorry-prd-1",
    )
    app_blocks = [
        Block("application-prd-1: DeploymentConfigs", app_dc, render_dcs),
        Block("application-prd-1: Pods", app_pod, render_pods_no_completed),
        Block("sorry-prd-1: DeploymentConfigs", sorry_dc, render_dcs),
        Block("sorry-prd-1: Pods", sorry_pod, render_pods_no_completed),
    ]

    # --- Batch Pods (Running で 1h 以上経過したものを赤強調) ---
    batch_pod = run_oc(
        ["get", "pod", "-n", "batch-prd-1"],
        "oc get pod -n batch-prd-1",
    )
    batch_blocks = [Block("batch-prd-1: Pods (Running > 1h を異常表示)",
                          batch_pod, render_pods_batch)]

    return [
        ("Worker Nodes", worker_nodes),
        ("Calico Pods", calico_blocks),
        ("Application Pods", app_blocks),
        ("Batch Pods", batch_blocks),
    ]


def build_summary(groups: list[tuple[str, list[Block]]]) -> str:
    nodes_ready = nodes_total = 0
    deploys_healthy = deploys_total = 0
    pods_healthy = pods_total = 0
    batch_long_running = 0
    seen_node: set[str] = set()
    seen_deploy: set[tuple[str, str, str]] = set()
    seen_pod: set[tuple[str, str]] = set()

    for group_title, blocks in groups:
        for b in blocks:
            if not b.result.ok:
                continue
            for item in b.result.items_of_kind("Node"):
                meta = item.get("metadata", {}) or {}
                name = meta.get("name", "")
                if name in seen_node:
                    continue
                seen_node.add(name)
                n = extract_nodes([item])[0]
                nodes_total += 1
                if n["healthy"]:
                    nodes_ready += 1
            for item in b.result.items_of_kind("Deployment"):
                meta = item.get("metadata", {}) or {}
                key = ("Deployment", meta.get("namespace", ""), meta.get("name", ""))
                if key in seen_deploy:
                    continue
                seen_deploy.add(key)
                d = extract_deployments([item])[0]
                deploys_total += 1
                if d["healthy"]:
                    deploys_healthy += 1
            for item in b.result.items_of_kind("DeploymentConfig"):
                meta = item.get("metadata", {}) or {}
                key = ("DeploymentConfig", meta.get("namespace", ""), meta.get("name", ""))
                if key in seen_deploy:
                    continue
                seen_deploy.add(key)
                d = extract_deploymentconfigs([item])[0]
                deploys_total += 1
                if d["healthy"]:
                    deploys_healthy += 1
            # Pod は Block ごとのモード (batch のみ long_running 判定) を考慮
            mode = "batch" if group_title == "Batch Pods" else "default"
            for item in b.result.items_of_kind("Pod"):
                meta = item.get("metadata", {}) or {}
                key = (meta.get("namespace", ""), meta.get("name", ""))
                if key in seen_pod:
                    continue
                seen_pod.add(key)
                p = extract_pods([item], mode=mode)[0]
                if p["is_completed"]:
                    continue
                pods_total += 1
                if p["healthy"]:
                    pods_healthy += 1
                if p["long_running"]:
                    batch_long_running += 1

    def card(label: str, value: str, cls: str = "") -> str:
        return (
            f'<div class="card {cls}">'
            f'<div class="label">{_h(label)}</div>'
            f'<div class="value">{_h(value)}</div>'
            "</div>"
        )

    cards = [
        card("Nodes Ready", f"{nodes_ready}/{nodes_total}",
             "ok" if nodes_total and nodes_ready == nodes_total else "warn"),
        card("Workloads Healthy", f"{deploys_healthy}/{deploys_total}",
             "ok" if deploys_total and deploys_healthy == deploys_total else "warn"),
        card("Pods Running", f"{pods_healthy}/{pods_total}",
             "ok" if pods_total and pods_healthy == pods_total else "warn"),
        card("Batch Long-Running", str(batch_long_running),
             "err" if batch_long_running > 0 else "ok"),
    ]
    return "".join(cards)


# ----------------------------------------------------------------------------
# エントリポイント
# ----------------------------------------------------------------------------

def main() -> int:
    if shutil.which("oc") is None:
        print("ERROR: oc が PATH に見つかりません", file=sys.stderr)
        return 127

    print("oc コマンドを実行中...", file=sys.stderr)
    groups = collect_all()

    for _, blocks in groups:
        for b in blocks:
            status = "OK" if b.result.ok else f"NG ({b.result.returncode})"
            print(f"  [{status}] {b.result.label}", file=sys.stderr)

    summary_html = build_summary(groups)
    html_text = build_html(groups, summary_html)

    # 出力先: /data/YYYY/MM/DD/YYYY_MMDD_HHMM_status_check_report.html
    now = datetime.now()
    out_dir = Path(f"/data/{now:%Y}/{now:%m}/{now:%d}")
    out_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{now:%Y}_{now:%m%d}_{now:%H%M}_status_check_report.html"
    out_path = out_dir / filename
    out_path.write_text(html_text, encoding="utf-8")

    print(f"\n✓ レポートを生成しました: {out_path}", file=sys.stderr)

    any_ok = any(b.result.ok for _, blocks in groups for b in blocks)
    return 0 if any_ok else 1


if __name__ == "__main__":
    sys.exit(main())









terraform

data "ibm_resource_group" "rg" {
  name = "test"
}




resource "ibm_resource_instance" "cos" {
  name              = "obi-test-object-storage-01"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = data.ibm_resource_group.rg.id
}

resource "ibm_cos_bucket" "bucket" {
  bucket_name          = "obi-test-bucket-01"
  resource_instance_id = ibm_resource_instance.cos.id
  region_location      = "jp-tok"
  storage_class        = "standard"

  force_delete = true
}

resource "ibm_resource_key" "cos_credential" {
  name                 = "test-credential"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id

  parameters = {
    HMAC = true
  }
}




output "object-storage-name" {
  value = ibm_resource_instance.cos.name
}

output "object-storage-id" {
  value = ibm_resource_instance.cos.id
}

output "bucket-name" {
  value = ibm_cos_bucket.bucket.bucket_name
}

output "bucket-id" {
  value = ibm_cos_bucket.bucket.id
}

output "credential" {
  value     = ibm_resource_key.cos_credential.credentials
  sensitive = true
}





terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 2.2.0"
    }
  }
}

provider "ibm" {
  region = "jp-tok"
}









# Status Checker

XX環境のOpenshift監視ツールに障害発生または停止した場合に備え、定期的にクラスタ上、リソースのステータスを確認するツールを作成する。

## 監視対象

- Calico Podのステータス
- Application Podのステータス
- バッチの長期実行

## 全体構成

- 各リソースのステータスを確認するCronjob
- CronjobにマウントするPVとしてIBM Object Storageを利用する。

## コンポーネント

### マニフェスト構成

- ClusterRole
  - CronJob内のスクリプトを実行できる権限を設定する。
- ClusterRoleBinding
  - ClusterRoleとCronJobのServiceAccountと紐づく
- ServiceAccount
  - CronJob用ServiceAccount
- CronJob
  - 定期的にステータスを確認し、レポートを作成する。
- Secret
  - IBM Object Storage用Service Credentialを設定する。
- PersistentVolumeClaim
  - レポート保管用PVを作成する。

### イメージ

- Redhatの公式 + 最新イメージを利用
- [Red Hat Ecosystem Catalog - Containers](https://catalog.redhat.com/en/search?searchType=Containers)

- 検索キーワード：ubi10 python 3.14 minimal

- イメージの参照先をDockerfileに設定

```Dockerfile
FROM registry.access.redhat.com/ubi10/python-314-minimal:10.2-1777970431
..........
..........
```

- Openshiftのバージョンアップ時、イメージのOCコマンドもバージョンアップ
```Dockerfile
..........
ARG OC_VERSION=4.xx.xx
..........
```

- ビルド

```
docker build -t prodigy413/status-checker:1.0 .
docker push prodigy413/status-checker:1.0
```

- Object Storage作成
  - TerraformコードでObject Storageを作成
```
terraform init
terraform plan
terraform apply
```

terraform output -json credential | \
jq '{
    "access-key": .["cos_hmac_keys.access_key_id"],
    "secret-key": .["cos_hmac_keys.secret_access_key"]
}'

oc create secret generic cos-write-access \
--type ibm/ibmc-s3fs \
--from-literal=access-key=xxxx \
--from-literal=secret-key \
--dry-run=client \
-o yaml \
-n infra \
> object-storage-secrets.yaml

```
oc new-project infra
oc project infra
oc diff -f ./
oc apply -f ./
oc get clusterrole,clusterrolebinding,cronjob,sa,secret,pvc
oc get pv -l xxx
```

```
oc get pod
oc logs cronjob
```

## 作業フォルダ












apiVersion: v1
kind: ServiceAccount
metadata:
  name: status-checker
  namespace: infra
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: infra-status-checker
rules:
  - apiGroups: [""]
    resources: ["pods", "nodes"]
    verbs: ["get", "list"]
  - apiGroups: ["apps"]
    resources: ["deployments", "daemonsets"]
    verbs: ["get", "list"]
  - apiGroups: ["apps.openshift.io"]
    resources: ["deploymentconfigs"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: infra-status-checker
subjects:
  - kind: ServiceAccount
    name: status-checker
    namespace: infra
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: infra-status-checker
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: status-checker
  namespace: infra
spec:
  #schedule: "0 * * * *"
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      backoffLimit: 1
      template:
        spec:
          serviceAccountName: status-checker
          restartPolicy: Never
          containers:
          - name: status-checker
            image: prodigy413/status-checker:1.0
            #imagePullPolicy: IfNotPresent
            imagePullPolicy: Always
            #command: ["sleep", "3600"]
            env:
            - name: TZ
              value: "Asia/Tokyo"
            volumeMounts:
            - name: storage-volume
              mountPath: /data
          volumes:
          - name: storage-volume
            persistentVolumeClaim:
              claimName: test-pvc
```
