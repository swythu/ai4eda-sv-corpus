#!/usr/bin/env python3
import json, os, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
items=json.loads((root/"manifest.json").read_text())["projects"]
results=[]
for item in items:
 p=root/item["path"]; candidates=[p/"run.sh",p/"scripts/run.sh"]; script=next(x for x in candidates if x.exists())
 print(f"[RUN ] {item['category']}/{item['name']}",flush=True)
 cp=subprocess.run([str(script)],cwd=p,text=True,capture_output=True,env=os.environ.copy())
 status="pass" if cp.returncode==0 else "fail"
 print(f"[{status.upper():4s}] {item['category']}/{item['name']}",flush=True)
 results.append({"project":item["name"],"status":status,"detail":(cp.stdout+cp.stderr)[-4000:]})
(root/"validation_summary.json").write_text(json.dumps(results,indent=2)+"\n")
raise SystemExit(0 if all(x["status"]=="pass" for x in results) else 1)
