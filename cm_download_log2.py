#!/usr/bin/env python3
import requests, zipfile, os, sys
token = "zC9pB3hVlCNv8FOZ1JnAukz_g9wY39X7jZmCOOtK9iw"
build_id = sys.argv[1] if len(sys.argv) > 1 else "6a58497b59904fcd1668ab23"
r = requests.get(f"https://api.codemagic.io/builds/{build_id}", headers={"x-auth-token": token}, timeout=30)
arts = r.json().get("build", {}).get("artefacts", [])
for i, a in enumerate(arts):
    url = a.get("url", "")
    if not url: continue
    fname = url.split("/")[-1]
    print(f"[{i}] Downloading {fname}...")
    r2 = requests.get(url, headers={"x-auth-token": token}, timeout=120, stream=True)
    if r2.ok:
        outpath = f"E:/Code/mihon-main/ios/cm_artifacts/{build_id}"
        os.makedirs(outpath, exist_ok=True)
        zippath = f"{outpath}/{i}_{fname}"
        with open(zippath, "wb") as f:
            for chunk in r2.iter_content(8192): f.write(chunk)
        try:
            z = zipfile.ZipFile(zippath)
            z.extractall(f"{outpath}/art{i}")
            z.close()
            print(f"  Extracted to {outpath}/art{i}")
            for f2 in os.listdir(f"{outpath}/art{i}"): print(f"    {f2}")
        except: print(f"  Not a zip: {fname}")
