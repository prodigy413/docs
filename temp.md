ibmcloud resource service-instances -o json
ibmcloud resource service-instances | grep sccwp
ibmcloud resource service-instance-delete sccwp --recursive

ibmcloud iam trusted-profiles
ibmcloud iam trusted-profiles | grep sccwp
ibmcloud iam trusted-profile-delete sccwp-1
ibmcloud iam trusted-profile-delete sccwp-2
ibmcloud iam trusted-profiles

ibmcloud resource service-instance-delete app-config-sccwp
ibmcloud resource service-instances -o json







from collections import defaultdict
import csv
from json import loads
from subprocess import run


def run_command(cmd: list) -> dict:
    result = run(["aws", "iam", *cmd, "--output", "json", "--no-cli-pager"], capture_output=True, text=True)
    if result.returncode == 0:
        data = loads(result.stdout)
        return data
    else:
        raise Exception(result.stderr)


def get_groups() -> list:
    data = run_command(["list-groups"])
    group_names = [group["GroupName"] for group in data["Groups"]]
    return group_names


def get_group_users(groups: list) -> list:
    group_users = list()
    for group in groups:
        data = run_command(["get-group", "--group-name", group])
        user_names = [user["UserName"] for user in data["Users"]]
        group_users.append({"group": group, "users": user_names})
    return group_users


def get_group_policies(groups: list) -> list:
    group_policies = list()
    for group in groups:
        data = run_command(["list-attached-group-policies", "--group-name", group])
        policy_names = [policy["PolicyName"] for policy in data["AttachedPolicies"]]
        group_policies.append({"group": group, "policies": policy_names})
    return group_policies


def build_index(users: list, policies: list) -> dict:
    idx = defaultdict(lambda: {"users": [], "policies": []})
    for user in users:
        idx[user["group"]]["users"] = user["users"]
    for policy in policies:
        idx[policy["group"]]["policies"] = policy["policies"]
    return idx


def write_csv(idx: dict, filename: str) -> None:
    with open(filename, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Group", "Users", "Policies"])
        for group in idx.keys():
            users = list(idx[group].get("users", []))
            policies = list(idx[group].get("policies", []))
            max_rows = max(len(users), len(policies), 1)

            users += [""] * (max_rows - len(users))
            policies += [""] * (max_rows - len(policies))

            for i in range(max_rows):
                w.writerow([group if i == 0 else "", users[i], policies[i]])


if __name__ == "__main__":
    groups = get_groups()
    users = get_group_users(groups)
    policies = get_group_policies(groups)
    idx = build_index(users, policies)
    filename = "/home/obi/test/develop-code/python/aws/iam_group_report.csv"
    write_csv(idx, filename)




kubectl get cronjobs -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,ACTIVE_DEADLINE_SECONDS:.spec.jobTemplate.spec.activeDeadlineSeconds'



aws iam list-groups \
  --query 'Groups[].GroupName' --output text
「グループを列挙する」正式コマンドです。
AWS Documentation

グループのメンバー（ユーザー）

bash
Copy code
aws iam get-group --group-name <GROUP_NAME> \
  --query 'Users[].UserName' --output text
指定グループに属するユーザーを返します。
AWS Documentation

グループにアタッチされた“管理ポリシー”一覧

bash
Copy code
aws iam list-attached-group-policies --group-name <GROUP_NAME> \
  --query 'AttachedPolicies[].{Name:PolicyName,Arn:PolicyArn}' --output table
グループに管理ポリシー（AWS 管理／カスタマー管理）が付与されている場合に列挙します。
AWS Documentation

グループに埋め込まれた“インラインポリシー”名一覧

bash
Copy code
aws iam list-group-policies --group-name <GROUP_NAME> \
  --query 'PolicyNames' --output table
グループにインラインポリシーがあれば、そのポリシー名を返します。
AWS Documentation
+1

インラインポリシーの本文（JSON）を取得

bash
Copy code
aws iam get-group-policy \
  --group-name <GROUP_NAME> \
  --policy-name <INLINE_POLICY_NAME> \
  --query 'PolicyDocument' --output json
インラインポリシーのドキュメント本文を取得します。
AWS Documentation
+1

管理ポリシーの本文（JSON）を取得

bash
Copy code
# まずデフォルト版のVersionIdを取得
aws iam get-policy --policy-arn <POLICY_ARN> \
  --query 'Policy.DefaultVersionId' --output text

# 取得したVersionIdを使って本文を取得
aws iam get-policy-version \
  --policy-arn <POLICY_ARN> --version-id <VERSION_ID> \
  --query 'PolicyVersion.Document' --output json






#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Collect IAM group members and policies via AWS CLI and output as JSON.

Requirements:
- AWS CLI v2 installed and configured (credentials/profile)
- Python 3.8+
Usage:
  python collect_iam_groups.py --profile prod --include-docs --out iam_groups.json
"""

import argparse
import json
import os
import subprocess
import sys
from typing import Any, Dict, List, Optional, Union
from urllib.parse import unquote

def run_aws(cmd: List[str], profile: Optional[str]) -> Dict[str, Any]:
    base = ["aws"] + cmd + ["--output", "json"]
    if profile:
        base += ["--profile", profile]
    # Disable AWS CLI pager just in case
    env = dict(os.environ)
    env["AWS_PAGER"] = ""
    try:
        res = subprocess.run(
            base, check=True, capture_output=True, text=True, env=env
        )
    except FileNotFoundError:
        print("ERROR: aws CLI not found in PATH.", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        msg = e.stderr.strip() or e.stdout.strip()
        raise RuntimeError(f"aws {' '.join(cmd)} failed: {msg}") from e

    txt = res.stdout.strip()
    if not txt:
        return {}
    try:
        return json.loads(txt)
    except json.JSONDecodeError:
        # Some commands might print non-JSON in edge cases
        return {"raw": txt}

def list_groups(profile: Optional[str]) -> List[Dict[str, Any]]:
    # aws iam list-groups
    # https://docs.aws.amazon.com/cli/latest/reference/iam/list-groups.html
    data = run_aws(["iam", "list-groups"], profile)
    return data.get("Groups", [])

def get_group_users(group_name: str, profile: Optional[str]) -> List[Dict[str, Any]]:
    # aws iam get-group --group-name <group>
    # https://docs.aws.amazon.com/cli/latest/reference/iam/get-group.html
    data = run_aws(["iam", "get-group", "--group-name", group_name], profile)
    return data.get("Users", []) or []

def list_attached_group_policies(group_name: str, profile: Optional[str]) -> List[Dict[str, Any]]:
    # aws iam list-attached-group-policies --group-name <group>
    # https://docs.aws.amazon.com/cli/latest/reference/iam/list-attached-group-policies.html
    data = run_aws(["iam", "list-attached-group-policies", "--group-name", group_name], profile)
    return data.get("AttachedPolicies", []) or []

def list_group_inline_policy_names(group_name: str, profile: Optional[str]) -> List[str]:
    # aws iam list-group-policies --group-name <group>
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/list-group-policies.html
    data = run_aws(["iam", "list-group-policies", "--group-name", group_name], profile)
    names = data.get("PolicyNames", []) or []
    return list(names)

def get_group_inline_policy_document(group_name: str, policy_name: str, profile: Optional[str]) -> Union[Dict[str, Any], str]:
    # aws iam get-group-policy --group-name <group> --policy-name <name>
    # NOTE: Document may be URL-encoded (per docs), so decode if needed.
    # https://docs.aws.amazon.com/cli/latest/reference/iam/get-group-policy.html
    # https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetGroupPolicy.html
    data = run_aws(
        ["iam", "get-group-policy", "--group-name", group_name, "--policy-name", policy_name],
        profile,
    )
    doc = data.get("PolicyDocument")
    if doc is None:
        return ""
    if isinstance(doc, dict):
        return doc
    # doc might be a URL-encoded JSON string -> decode then try json
    decoded = unquote(doc)
    try:
        return json.loads(decoded)
    except Exception:
        return decoded

def get_managed_policy_default_version(arn: str, profile: Optional[str]) -> Optional[str]:
    # aws iam get-policy --policy-arn <arn>
    # https://docs.aws.amazon.com/cli/latest/reference/iam/get-policy.html
    data = run_aws(["iam", "get-policy", "--policy-arn", arn], profile)
    pol = data.get("Policy") or {}
    return pol.get("DefaultVersionId")

def get_managed_policy_document(arn: str, version_id: str, profile: Optional[str]) -> Union[Dict[str, Any], str]:
    # aws iam get-policy-version --policy-arn <arn> --version-id <vid>
    # https://docs.aws.amazon.com/cli/latest/reference/iam/get-policy-version.html
    data = run_aws(
        ["iam", "get-policy-version", "--policy-arn", arn, "--version-id", version_id],
        profile,
    )
    pv = data.get("PolicyVersion") or {}
    doc = pv.get("Document")
    if doc is None:
        return ""
    if isinstance(doc, dict):
        return doc
    decoded = unquote(doc)
    try:
        return json.loads(decoded)
    except Exception:
        return decoded

def collect(include_docs: bool, profile: Optional[str]) -> Dict[str, Any]:
    result: Dict[str, Any] = {"groups": []}
    for g in list_groups(profile):
        gname = g.get("GroupName")
        entry: Dict[str, Any] = {
            "group": {
                "GroupName": gname,
                "Arn": g.get("Arn"),
                "Path": g.get("Path"),
                "CreateDate": g.get("CreateDate"),
                "GroupId": g.get("GroupId"),
            },
            "users": [],
            "policies": {
                "managed": [],
                "inline": [],
            },
        }

        # Members
        users = get_group_users(gname, profile)
        entry["users"] = [{"UserName": u.get("UserName"), "Arn": u.get("Arn")} for u in users]

        # Managed (attached) policies
        attached = list_attached_group_policies(gname, profile)
        for ap in attached:
            item = {"PolicyName": ap.get("PolicyName"), "PolicyArn": ap.get("PolicyArn")}
            if include_docs:
                try:
                    dv = get_managed_policy_default_version(ap["PolicyArn"], profile)
                    if dv:
                        doc = get_managed_policy_document(ap["PolicyArn"], dv, profile)
                        item["Document"] = doc
                        item["DefaultVersionId"] = dv
                except Exception as e:
                    item["DocumentError"] = str(e)
            entry["policies"]["managed"].append(item)

        # Inline policies
        for pname in list_group_inline_policy_names(gname, profile):
            inline_item: Dict[str, Any] = {"PolicyName": pname}
            if include_docs:
                try:
                    inline_item["Document"] = get_group_inline_policy_document(gname, pname, profile)
                except Exception as e:
                    inline_item["DocumentError"] = str(e)
            entry["policies"]["inline"].append(inline_item)

        result["groups"].append(entry)

    return result

def main():
    p = argparse.ArgumentParser(description="Export IAM group members and policies via AWS CLI.")
    p.add_argument("--profile", help="AWS CLI profile name (optional)")
    p.add_argument("--include-docs", action="store_true",
                   help="Fetch and include full policy documents (managed & inline).")
    p.add_argument("--out", help="Output JSON file path (optional). If omitted, prints to stdout.")
    args = p.parse_args()

    try:
        data = collect(include_docs=args.include_docs, profile=args.profile)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)

    js = json.dumps(data, ensure_ascii=False, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(js)
        print(f"Wrote: {args.out}")
    else:
        print(js)

if __name__ == "__main__":
    main()

~~~
