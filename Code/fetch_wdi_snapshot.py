#!/usr/bin/env python3
"""Optional explicit refresh. Downloads into a NEW directory; never changes frozen data."""
import argparse,hashlib,json,ssl,urllib.request
from datetime import datetime,timezone
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--output-dir',type=Path,required=True)
    args=ap.parse_args();args.output_dir.mkdir(parents=True,exist_ok=False)
    prov=json.loads((ROOT/'Sources/provenance.json').read_text());snapshots=[]
    for item in prov['snapshots']:
        req=urllib.request.Request(item['url'],headers={'User-Agent':'PM-TBL-reproducibility/1.0'})
        with urllib.request.urlopen(req,timeout=90,context=ssl.create_default_context()) as r:raw=r.read()
        obj=json.loads(raw)
        if not isinstance(obj,list) or len(obj)!=2 or obj[0]['pages']!=1:raise ValueError('Incomplete or unexpected WDI response')
        (args.output_dir/item['file']).write_bytes(raw)
        snapshots.append(dict(file=item['file'],url=item['url'],sha256=hashlib.sha256(raw).hexdigest(),source_lastupdated=obj[0].get('lastupdated')))
    (args.output_dir/'provenance.json').write_text(json.dumps(dict(retrieved_utc=datetime.now(timezone.utc).isoformat(),snapshots=snapshots),indent=2))
    print('Downloaded new snapshots only. Reconcile the new vintage and price parameters before using it.')
if __name__=='__main__':main()
