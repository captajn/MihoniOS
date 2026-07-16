#!/usr/bin/env python3
import requests, sys
token = "zC9pB3hVlCNv8FOZ1JnAukz_g9wY39X7jZmCOOtK9iw"
build_id = sys.argv[1] if len(sys.argv) > 1 else "6a58497b59904fcd1668ab23"
r = requests.get(f"https://api.codemagic.io/builds/{build_id}", headers={"x-auth-token": token}, timeout=30)
d = r.json().get("build", {})
print("Status:", d.get("status"))
print("Message:", d.get("message", "")[:300])
arts = d.get("artefacts", [])
print(f"Artifacts: {len(arts)}")
for a in arts:
    print(f"  {a.get('url', '')[:100]}")
