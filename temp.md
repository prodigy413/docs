```
FROM registry.access.redhat.com/ubi10/python-314-minimal:10.2-1779887616

USER root

ARG OC_VERSION=4.18.43

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
  /data/YYYY/MM/DD/YYYY_MMDD_HHMM_status_check_report.html

使い方:
  python3 status_checker.py
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


##############################
# oc コマンド実行
##############################
class OcCommandError(Exception):
    """oc コマンドの実行に失敗したことを示す例外"""

    def __init__(self, label: str, command: list[str], reason: str,
                 returncode: int, stderr: str = "", stdout: str = "") -> None:
        super().__init__(reason)
        self.label = label
        self.command = command
        self.reason = reason
        self.returncode = returncode
        self.stderr = stderr
        self.stdout = stdout

    def detail(self) -> str:
        """stderr に出すための詳細メッセージ"""
        lines = [
            f"FAILED: {self.label}",
            f"  command:    {' '.join(self.command)}",
            f"  exit code:  {self.returncode}",
            f"  reason:     {self.reason}",
        ]
        if self.stderr.strip():
            lines.append("  stderr:")
            for line in self.stderr.rstrip().splitlines():
                lines.append(f"    {line}")
        return "\n".join(lines)


@dataclass
class CommandResult:
    """oc コマンドの実行結果 (成功したもののみ)"""
    label: str
    command: list[str]
    stdout: str
    parsed: dict[str, Any]

    def items_of_kind(self, kind: str) -> list[dict]:
        return [it for it in self.parsed.get("items", []) if it.get("kind") == kind]


def run_oc(args: list[str], label: str) -> CommandResult:
    """
    oc を JSON 出力で実行して結果を返す。
    失敗した場合は OcCommandError を送出する (呼び出し元では catch しない方針)。
    """
    cmd = ["oc"] + args + ["-o", "json"]

    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, check=False, timeout=60,
        )
    except FileNotFoundError:
        raise OcCommandError(
            label, cmd, "oc コマンドが見つかりません", returncode=127,
        )
    except subprocess.TimeoutExpired:
        raise OcCommandError(
            label, cmd, "oc がタイムアウトしました (60s)", returncode=124,
        )

    if proc.returncode != 0:
        raise OcCommandError(
            label, cmd,
            reason=f"oc が exit code {proc.returncode} で失敗しました",
            returncode=proc.returncode,
            stderr=proc.stderr,
            stdout=proc.stdout,
        )

    if not proc.stdout.strip():
        raise OcCommandError(
            label, cmd,
            reason="oc の標準出力が空です (JSON が返却されませんでした)",
            returncode=proc.returncode,
            stderr=proc.stderr,
        )

    try:
        parsed = json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        raise OcCommandError(
            label, cmd,
            reason=f"oc 出力の JSON パースに失敗しました: {e}",
            returncode=proc.returncode,
            stderr=proc.stderr,
            stdout=proc.stdout,
        )

    return CommandResult(label, cmd, proc.stdout, parsed)


##############################
# データ抽出
##############################
def _parse_ts(ts: str | None) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None


def _age_str(created: datetime | None) -> str:
    """oc と同じ s/m/h/d 表記"""
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
    oc の RESTARTS 列で使われる経過時間表記。
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
        # oc が "8 (3m43s ago)" のように表示するための時刻情報
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


##############################
# HTML レンダリング
##############################
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
h1 { font-size: 25px; margin: 0 0 8px; font-weight: 600; letter-spacing: -0.01em; }
.meta { color: var(--muted); font-size: 14px; font-family: var(--mono); }

.section-group { margin-bottom: 40px; }
.section-group > h2.group {
  font-size: 14px;
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
  font-size: 15px;
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
  font-size: 12px;
  color: var(--muted);
  font-weight: 400;
  margin-left: auto;
  background: var(--panel-2);
  padding: 2px 8px;
  border-radius: 4px;
  border: 1px solid var(--border);
}
.table-wrap { overflow-x: auto; background: var(--panel); border: 1px solid var(--border); border-radius: 8px; }
table { width: 100%; border-collapse: collapse; font-size: 14px; }
th, td { text-align: left; padding: 9px 14px; white-space: nowrap; border-bottom: 1px solid var(--border); }
th {
  background: var(--panel-2);
  font-weight: 600;
  font-size: 12px;
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
  font-size: 12px;
  font-weight: 600;
  font-family: var(--mono);
}
.badge.ok { background: rgba(63,185,80,0.15); color: var(--ok); }
.badge.warn { background: rgba(210,153,34,0.15); color: var(--warn); }
.badge.err { background: rgba(248,81,73,0.15); color: var(--err); }
.badge.muted { background: rgba(139,148,158,0.15); color: var(--muted); }
.muted-inline { color: var(--muted); font-family: var(--mono); font-size: 12px; }
.empty { padding: 18px; color: var(--muted); text-align: center; font-size: 14px; }
.error {
  background: rgba(248,81,73,0.1);
  border: 1px solid var(--err);
  color: var(--err);
  padding: 12px 16px;
  border-radius: 8px;
  font-family: var(--mono);
  font-size: 13px;
  white-space: pre-wrap;
}
.note { font-size: 12px; color: var(--muted); margin-top: 6px; font-family: var(--mono); }
footer {
  margin-top: 48px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
  color: var(--muted);
  font-size: 13px;
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


##############################
# レポート作成
##############################
@dataclass
class Block:
    title: str
    result: CommandResult
    renderer: Callable[[CommandResult], str]


def build_html(groups: list[tuple[str, list[Block]]]) -> str:
    parts: list[str] = []
    for group_title, blocks in groups:
        parts.append('<div class="section-group">')
        parts.append(f'<h2 class="group">{_h(group_title)}</h2>')
        for b in blocks:
            inner = b.renderer(b.result)
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

{"".join(parts)}

<footer>Generated by status_checker.py</footer>
</div>
</body>
</html>
"""


##############################
# レンダリング
##############################
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


##############################
# コマンド実行
##############################
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
    batch_blocks = [Block("batch-prd-1: Pods",
                          batch_pod, render_pods_batch)]

    return [
        ("Worker Nodes", worker_nodes),
        ("Calico Pods", calico_blocks),
        ("Application Pods", app_blocks),
        ("Batch Pods", batch_blocks),
    ]


##############################
# Main
##############################
def main() -> int:
    if shutil.which("oc") is None:
        print("ERROR: oc が PATH に見つかりません", file=sys.stderr)
        return 127

    print("oc コマンドを実行中...", file=sys.stderr)

    try:
        groups = collect_all()
    except OcCommandError as e:
        print("", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        print("ERROR: oc コマンドの実行に失敗したため、処理を中断します。", file=sys.stderr)
        print("=" * 60, file=sys.stderr)
        print(e.detail(), file=sys.stderr)
        return e.returncode if e.returncode != 0 else 1

    for _, blocks in groups:
        for b in blocks:
            print(f"  [OK] {b.result.label}", file=sys.stderr)

    html_text = build_html(groups)

    # 出力先: /data/YYYY/MM/DD/YYYY_MMDD_HHMM_status_check_report.html
    now = datetime.now()
    out_dir = Path(f"/data/{now:%Y}/{now:%m}/{now:%d}")
    out_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{now:%Y}_{now:%m%d}_{now:%H%M}_status_check_report.html"
    out_path = out_dir / filename
    out_path.write_text(html_text, encoding="utf-8")

    print(f"\n✓ レポートを生成しました: {out_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())










apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: infra-status-checker
  labels:
    app: status-checker
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
  labels:
    app: status-checker
subjects:
  - kind: ServiceAccount
    name: status-checker
    namespace: infra
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: infra-status-checker
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: status-checker-pvc
  labels:
    app: status-checker
  namespace: infra
  annotations:
    ibm.io/auto-create-bucket: "false"
    ibm.io/auto-delete-bucket: "false"
    ibm.io/bucket: "obi-test-bucket-01"
    ibm.io/secret-name: "cos-write-access"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ibmc-s3fs-standard-regional
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: status-checker
  namespace: infra
  labels:
    app: status-checker
imagePullSecrets:
- name: all-icr-io
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: status-checker
  namespace: infra
  labels:
    app: status-checker
spec:
  #schedule: "0 * * * *"
  schedule: "*/2 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 60
      template:
        spec:
          serviceAccountName: status-checker
          restartPolicy: Never
          containers:
          - name: status-checker
            image: jp.icr.io/obi-infra/status-checker:1.0
            #imagePullPolicy: IfNotPresent
            imagePullPolicy: Always
            #command: ["sleep", "3600"]
            env:
            - name: TZ
              value: "Asia/Tokyo"
            resources:
              requests:
                cpu: "100m"
                memory: "128Mi"
              limits:
                cpu: "500m"
                memory: "512Mi"
            volumeMounts:
            - name: storage-volume
              mountPath: /data
          volumes:
          - name: storage-volume
            persistentVolumeClaim:
              claimName: status-checker-pvc










# Status Checker

XX環境のOpenshift監視ツールに障害発生または停止した場合に備え、定期的にクラスタ上、リソースのステータスを確認するツールを作成する。

## 監視対象

- Calico Podのステータス
- Application Podのステータス
- バッチの長期実行

## 全体構成

- Cronjobで1時間ごと各リソースのステータスを確認するPythonスクリプトを実行
- スクリプトの実行結果を/dataに保管
- 

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
  - イメージプール用認証情報を設定する。
  - IBM Object Storage用Service Credentialを設定する。
- PersistentVolumeClaim
  - レポート保管用PVを作成する。

### イメージ

- Redhatの公式 + 最新イメージを利用
- [Red Hat Ecosystem Catalog - Containers](https://catalog.redhat.com/en/search?searchType=Containers)
- 以下検索する。
  - 検索キーワード：ubi10 python 3.14 minimal
- 検索結果をクリックする。
- イメージの参照先をDockerfileに設定

```Dockerfile
FROM registry.access.redhat.com/ubi10/python-314-minimal:10.2-1779887616
..........
..........
```

- Openshiftのバージョンアップ時、イメージのOCコマンドもバージョンアップ
```Dockerfile
..........
ARG OC_VERSION=4.xx.xx
..........
```

- ICRのNamespace作成

```
ibmcloud cr login

ibmcloud cr region-set ap-north

ibmcloud cr namespaces

ibmcloud cr namespace-add obi-infra

ibmcloud cr namespaces
```

- ビルド
```
docker build -t prodigy413/status-checker:1.0 .
docker push prodigy413/status-checker:1.0

docker build -t jp.icr.io/obi-infra/status-checker:1.0 .

docker images

docker push jp.icr.io/obi-infra/status-checker:1.0

ibmcloud cr images --restrict obi-infra

```

- Object Storage作成
  - TerraformコードでObject Storageを作成
```
terraform validate
terraform init
terraform plan
terraform apply
```

terraform output -json credential | \
jq '{
    "access-key": .["cos_hmac_keys.access_key_id"],
    "secret-key": .["cos_hmac_keys.secret_access_key"]
}'

cd yaml

oc create secret generic cos-write-access \
  --type ibm/ibmc-s3fs \
  --from-literal=access-key=6ad704240b8244f99e603eadf281dd25 \
  --from-literal=secret-key=b52326c2e2fdcd8cff2e709f46019ee5b7d093a7443a6e44 \
  --dry-run=client \
  -o yaml \
  -n infra \
| oc label --local -f - app=status-checker -o yaml \
| sed '/^[[:space:]]*creationTimestamp: null$/d' \
> object-storage-secrets.yaml

```
oc new-project infra

oc project infra

oc get secrets all-icr-io -n default -oyaml > all-icr-io.yaml

# 以下削除
- annotations
- creationTimestamp
- resourceVersion
- uid
# namespaceをinfraに変更

oc get pod

oc diff -f ./

oc apply -f ./

oc get secrets

oc get clusterrole,clusterrolebinding,cronjob,sa,secret,pvc -l app=status-checker

oc get pv | grep status-checker-pvc
```

```
oc get pod

oc logs status-checker-29664622-8kgll
```

## 作業フォルダ












resource "aws_organizations_account" "management" {
  email     = "root@test.com"
  name      = "management"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "infrastructure" {
  email = "test04@test.com"
  name  = "infrastructure"
  #parent_id = aws_organizations_organizational_unit.infra.id
  parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    ManagedBy   = "Kiban"
    Owner       = "Kiban"
  }

  #depends_on = [aws_organizations_organizational_unit.infra]
}

resource "aws_organizations_account" "audit" {
  email = "test05@test.net"
  name  = "audit"
  #parent_id = aws_organizations_organizational_unit.security.id
  parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  #depends_on = [aws_organizations_organizational_unit.security]
}

resource "aws_organizations_account" "evs" {
  email = "test06@test.net"
  name  = "evs"
  #parent_id = aws_organizations_organizational_unit.evs.id
  parent_id = data.aws_organizations_organization.this.roots[0].id
  tags = {
    AccountType = "Security"
    Environment = "Common"
    Owner       = "Kiban"
  }

  #depends_on = [aws_organizations_organizational_unit.evs]
}

resource "aws_organizations_account" "system-stg" {
  email = "test07@test.net"
  name  = "system-stg"
  #parent_id = aws_organizations_organizational_unit.non-prod.id
  parent_id = data.aws_organizations_organization.this.roots[0].id

  #depends_on = [aws_organizations_organizational_unit.non-prod]
}










export AWS_PROFILE=management

terraform init
terraform plan -generate-config-out=account.tf
terraform apply

^.*null.*\r?\n









# aws organizations list-accounts --query 'Accounts[*].[Name, Id]' --output table

import {
  to = aws_organizations_account.management
  id = "test"
}

import {
  to = aws_organizations_account.infrastructure
  id = "test"
}

import {
  to = aws_organizations_account.audit
  id = "test"
}

import {
  to = aws_organizations_account.evs
  id = "test"
}

import {
  to = aws_organizations_account.system-stg
  id = "test"
}

#import {
#  to = aws_organizations_account.system-prd
#  id = "test"
#}










############################
# Variables
############################
locals {
  root_id           = data.aws_organizations_organization.this.roots[0].id
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

############################
# Organizational Units
############################
locals {
  root_ous = {
    security = "security"
    infra    = "infrastructure"
    workload = "workload"
  }

  workload_ous = {
    evs        = "evs"
    system-prd = "system-prd"
    system-stg = "system-stg"
  }
}

resource "aws_organizations_organizational_unit" "root" {
  for_each = local.root_ous

  name      = each.value
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workload" {
  for_each = local.workload_ous

  name      = each.value
  parent_id = aws_organizations_organizational_unit.root["workload"].id
}

############################
# Groups
############################
locals {
  identity_store_groups = {
    mck-admin = "MultiCloud Kiban Team Administrators"
    mck       = "MultiCloud Kiban Team"
    bk        = "Bunsan Kiban Team"
    nw        = "Network Team"
    inet      = "Internet Team"
    assist    = "Assist Team"
  }
}

resource "aws_identitystore_group" "this" {
  for_each = local.identity_store_groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value
}

############################
# Permission Sets
############################
locals {
  ssoadmin_permission_sets = {
    organization_admin = {
      name        = "organization-admin"
      description = "Organization-wide administrator"
    }

    workload_operator = {
      name        = "workload-operator"
      description = "Workload operator"
    }
  }
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.ssoadmin_permission_sets

  instance_arn     = local.instance_arn
  name             = each.value.name
  description      = each.value.description
  session_duration = "PT8H"
}

############################
# Managed Policy Attachments
############################
resource "aws_ssoadmin_managed_policy_attachment" "organization-admin-adminaccess" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization-admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "workload-operator-poweruser" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

############################
# Inline policy document for workload-operator
############################

data "aws_iam_policy_document" "workload-operator-inline" {
  ########################################
  # Organization / Account / Control Tower
  ########################################
  statement {
    sid    = "DenyOrganizationAccountAndControlTowerManagement"
    effect = "Deny"

    actions = [
      # AWS Organizations
      "organizations:*",

      # AWS Account Management
      "account:*",

      # AWS Control Tower
      "controltower:*",
      "controlcatalog:*"
    ]

    resources = ["*"]
  }

  ########################################
  # IAM Identity Center / Identity Store
  ########################################
  statement {
    sid    = "DenyIdentityCenterManagement"
    effect = "Deny"

    actions = [
      "sso:*",
      "sso-directory:*",
      "identitystore:*"
    ]

    resources = ["*"]
  }

  ########################################
  # Security / Audit / Governance Services
  ########################################
  statement {
    sid    = "DenySecurityAuditAndGovernanceServices"
    effect = "Deny"

    actions = [
      # Logging / Audit
      "cloudtrail:*",
      "config:*",
      "auditmanager:*",

      # Security posture / threat detection
      "securityhub:*",
      "guardduty:*",
      "detective:*",
      "inspector:*",
      "inspector2:*",
      "macie2:*",
      "securitylake:*",
      "access-analyzer:*",

      # Firewall / org-wide security management
      "fms:*",

      # AWS Artifact
      "artifact:*"
    ]

    resources = ["*"]
  }

  ########################################
  # Billing / Cost Management
  ########################################
  statement {
    sid    = "DenyBillingAndCostManagement"
    effect = "Deny"

    actions = [
      "billing:*",
      "ce:*",
      "budgets:*",
      "cur:*",
      "cur-reporting:*",
      "cost-optimization-hub:*",
      "bcm-data-exports:*",
      "pricing:*",
      "payments:*",
      "tax:*",
      "invoicing:*",
      "consolidatedbilling:*",
    ]

    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "workload-operator-inline" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload-operator.arn
  inline_policy      = data.aws_iam_policy_document.workload-operator-inline.json
}

############################
# Account Assignments
############################

locals {
  account_assignments = {
    mgmt-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.organization-admin.arn
      group_id       = aws_identitystore_group.mck-admin.group_id
      target_id      = aws_organizations_account.management.id
    }
    audit-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.organization-admin.arn
      group_id       = aws_identitystore_group.mck-admin.group_id
      target_id      = aws_organizations_account.audit.id
    }
    infra-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.organization-admin.arn
      group_id       = aws_identitystore_group.mck-admin.group_id
      target_id      = aws_organizations_account.infrastructure.id
    }
    evs-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.organization-admin.arn
      group_id       = aws_identitystore_group.mck-admin.group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-stg-mck-admin = {
      permission_set = aws_ssoadmin_permission_set.organization-admin.arn
      group_id       = aws_identitystore_group.mck-admin.group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    evs-bk = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.bk.group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-stg-bk = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.bk.group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    infra-assist = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.assist.group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    evs-assist = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.assist.group_id
      target_id      = aws_organizations_account.evs.id
    }
    system-stg-assist = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.assist.group_id
      target_id      = aws_organizations_account.system-stg.id
    }
    infra-nw = {
      permission_set = aws_ssoadmin_permission_set.workload-operator.arn
      group_id       = aws_identitystore_group.nw.group_id
      target_id      = aws_organizations_account.system-stg.id
    }
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignments

  instance_arn       = local.instance_arn
  permission_set_arn = each.value.permission_set

  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.target_id
  target_type = "AWS_ACCOUNT"
}

resource "terraform_data" "run-script" {

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 10 && python3 get-org-info.py"
  }

  depends_on = [
    aws_ssoadmin_account_assignment.management-mck-admin,
    aws_ssoadmin_account_assignment.audit-mck-admin,
    aws_ssoadmin_account_assignment.infra-mck-admin,
    aws_ssoadmin_account_assignment.evs-bk-workload-operator,
    aws_ssoadmin_account_assignment.system-stg-bk-workload-operator
  ]
}











```
