~~~python
# from dotenv import load_dotenv
# load_dotenv()

import os
import json
import urllib.request
import urllib.parse

# export SCCWP_AUTH_TOKEN="$(ibmcloud iam oauth-tokens | awk '{print $4}')"
# SCCWP_GUID=$(ibmcloud resource service-instance sccwp-test --output json | jq -r '.[].guid')

URL = "https://jp-tok.security-compliance-secure.cloud.ibm.com"
AUTH_TOKEN = os.getenv("SCCWP_AUTH_TOKEN")
INSTANCE_ID = "55f1010a-7e3c-49c6-bc8d-8d4293a7566c"

# final_url = URL + "/api/cspm/v1/inventory/resources"
final_url = URL + "/api/cspm/v1/tasks"
# final_url = URL + "/api/v2/policies"
# final_url = URL + "/platform/v1/zones"
# final_url = URL + "/api/cspm/v1/tasks/757634/rerun"

headers = {
    "Authorization": f"Bearer {AUTH_TOKEN}",
    "IBMInstanceID": INSTANCE_ID,
    "Content-Type": "application/json"
}

req = urllib.request.Request(final_url, headers=headers)
# req = urllib.request.Request(final_url, headers=headers, method="POST")

with urllib.request.urlopen(req) as response:
    body = response.read()
    print(body.decode("utf-8"))

~~~
