#!/usr/bin/env python3
"""Reproduce all-age valuation in Python using only the standard library.

Inputs are external licensed GBD subsets. No data are downloaded by this script.
"""
import argparse
import csv
import gzip
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read_rows(path):
    op = gzip.open if str(path).endswith('.gz') else open
    with op(path, 'rt', encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))

def write_rows(path, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    op = gzip.open if str(path).endswith('.gz') else open
    with op(path, 'wt', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)

def key(row):
    return tuple(int(row[x]) for x in ('location_id','year','sex_id'))

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--input-dir', type=Path, default=ROOT/'Data/Inputs')
    ap.add_argument('--output-dir', type=Path, default=ROOT/'Results/PythonValuation')
    args = ap.parse_args()
    cfg = json.loads((ROOT/'Parameters/valuation_settings.json').read_text())
    burden = read_rows(args.input_dir/'gbd_all_age_dalys.csv')
    hale = {key(r): r for r in read_rows(args.input_dir/'hale_all_age.csv')}
    pop = {key(r): r for r in read_rows(args.input_dir/'population_all_age.csv')}
    codes = {int(r['location_id']): r['Country.Code'] for r in read_rows(ROOT/'Sources/country_region_mapping_45.csv')}
    macro = json.loads((ROOT/'Sources/WDI_macro_1990_2023.json').read_text())[1]
    lookup = {(r['countryiso3code'],int(r['date']),r['indicator']['id']):r['value'] for r in macro}
    qref = lookup['USA',2023,'NY.GDP.PCAP.PP.KD']
    K = cfg['rebasing_2021_to_2023']
    assert math.isclose(qref,cfg['GDPpc_USA_2023_constant2021'],rel_tol=1e-12)
    assert len(burden)==4590 and len({key(r) for r in burden})==4590
    rows,missingness = [],[]
    for b in burden:
        k = key(b); code = codes[k[0]]
        q = lookup.get((code,k[1],'NY.GDP.PCAP.PP.KD'))
        g = lookup.get((code,k[1],'NY.GDP.MKTP.PP.KD'))
        available = q is not None and g is not None
        missingness.append(dict(location_id=k[0],ISO3=code,year=k[1],sex_id=k[2],valuation_available=available))
        if not available:
            continue
        h = float(hale[k]['HALE']); p = float(pop[k]['population']); daly = float(b['DALYs'])
        assert min(h,p,q,g)>0
        for epsilon in cfg['income_elasticity_scenarios']:
            for factor in cfg['HALE_factors']:
                vsl = cfg['VSL_USA_2023']*(q/qref)**epsilon
                vsly = vsl/(h*factor); vlw = daly*vsly; gdp = g*K
                rows.append(dict(location_id=k[0],location_name=b['location_name'],region_6=b['region_6'],ISO3=code,year=k[1],sex_id=k[2],sex_name=b['sex_name'],DALYs=daly,HALE=h,GDP_per_capita_const2021=q,GDP_per_capita=q*K,GDP_const2021=g,GDP=gdp,population=p,VSL=vsl,VSLY=vsly,VLW=vlw,VLW_GDP=vlw/gdp,VLW_GDP_pct=100*vlw/gdp,per_capita_VLW=vlw/p,epsilon=epsilon,hale_factor=factor,hale_convention='HALE/2 primary' if factor==.5 else 'HALE sensitivity',monetary_unit='Constant 2023 international dollars'))
    primary = [r for r in rows if r['epsilon']==1 and r['hale_factor']==.5]
    assert len(primary)==4548 and len(rows)==27288
    write_rows(args.output_dir/'analysis_ready_primary.csv',primary)
    write_rows(args.output_dir/'valuation_all_scenarios.csv.gz',rows)
    write_rows(args.output_dir/'coverage_missingness.csv',missingness)
    total = sum(r['VLW'] for r in primary if r['year']==2023 and r['sex_name']=='Both')
    print(f'PASS: {len(primary)} primary records; {len(rows)} six-scenario records; 2023 VLW={total/1e9:.12f} billion.')

if __name__=='__main__':
    main()
