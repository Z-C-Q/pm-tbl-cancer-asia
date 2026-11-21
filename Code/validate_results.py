#!/usr/bin/env python3
"""Independent arithmetic, coverage, aggregation and reference checks; stdlib only."""
import argparse
import csv
import gzip
import hashlib
import json
import math
from collections import Counter,defaultdict
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def rows(p):
    op=gzip.open if str(p).endswith('.gz') else open
    with op(p,'rt',encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def close(a,b):return math.isclose(float(a),float(b),rel_tol=1e-9,abs_tol=1e-6)
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--results-dir',type=Path,default=ROOT/'Results')
    ap.add_argument('--reference-dir',type=Path)
    args=ap.parse_args();out=args.results_dir;checks=[]
    def check(name,passed,detail=''):
        checks.append(dict(check=name,passed=bool(passed),detail=detail))
        if not passed:raise AssertionError(name+': '+detail)
    cfg=json.loads((ROOT/'Parameters/valuation_settings.json').read_text())
    prov=json.loads((ROOT/'Sources/provenance.json').read_text())
    check('Frozen WDI response hashes',all(hashlib.sha256((ROOT/'Sources'/s['file']).read_bytes()).hexdigest()==s['sha256'] for s in prov['snapshots']))
    defs=json.loads((ROOT/'Sources/WDI_USA_GDP_deflator.json').read_text())[1]
    defs={int(r['date']):r['value'] for r in defs}
    check('Price conversion equals frozen deflator ratio',close(cfg['rebasing_2021_to_2023'],defs[2023]/defs[2021]))
    a=rows(out/'Data/analysis_ready_primary.csv');s=rows(out/'Data/valuation_all_scenarios.csv.gz')
    key=lambda r:(r['location_id'],r['year'],r['sex_id'])
    required={'location_id','year','sex_id','DALYs','HALE','GDP_per_capita','GDP','population','VSL','VSLY','VLW','VLW_GDP','per_capita_VLW'}
    check('Required analysis-ready fields',required<=set(a[0]))
    check('Primary rows, unique keys and countries',len(a)==4548 and len({key(r) for r in a})==4548 and len({r['location_id'] for r in a})==45 and '153' not in {r['location_id'] for r in a})
    check('Primary valuation and ratio equations',all(close(r['VSL'],cfg['VSL_USA_2023']*(float(r['GDP_per_capita_const2021'])/cfg['GDPpc_USA_2023_constant2021'])) and close(r['GDP'],float(r['GDP_const2021'])*cfg['rebasing_2021_to_2023']) and close(r['VSLY'],float(r['VSL'])/(float(r['HALE'])/2)) and close(r['VLW'],float(r['DALYs'])*float(r['VSLY'])) and close(r['VLW_GDP'],float(r['VLW'])/float(r['GDP'])) and close(r['VLW_GDP_pct'],100*float(r['VLW'])/float(r['GDP'])) and close(r['per_capita_VLW'],float(r['VLW'])/float(r['population'])) for r in a))
    cases=Counter((float(r['epsilon']),float(r['hale_factor'])) for r in s)
    check('All six complete scenarios',len(s)==27288 and set(cases)=={(e,h) for e in [.5,1,1.5] for h in [.5,1]} and set(cases.values())=={4548})
    check('All six scenario equations',all(close(r['VSL'],cfg['VSL_USA_2023']*(float(r['GDP_per_capita_const2021'])/cfg['GDPpc_USA_2023_constant2021'])**float(r['epsilon'])) and close(r['VSLY'],float(r['VSL'])/(float(r['HALE'])*float(r['hale_factor']))) and close(r['VLW'],float(r['DALYs'])*float(r['VSLY'])) for r in s))
    lookup={(key(r),float(r['epsilon']),float(r['hale_factor'])):r for r in s}
    check('Full HALE halves VLW',all(close(float(r['VLW'])*2,lookup[key(r),float(r['epsilon']),.5]['VLW']) for r in s if float(r['hale_factor'])==1))
    cov=rows(out/'Tables/country_coverage_by_year.csv')
    check('43/44/45 annual coverage',all(int(r['valuation_countries'])==(43 if int(r['year'])<1994 else 44 if int(r['year'])<2000 else 45) for r in cov))
    check('All 45 countries in 2023',sum(r['year']=='2023' and r['sex_name']=='Both' for r in a)==45)
    ids=Counter(r['location_id'] for r in a if r['sex_name']=='Both')
    fixed={k for k,n in ids.items() if n==34};check('Fixed panel has 43 countries',len(fixed)==43)
    regional=rows(out/'Data/elasticity_sensitivity_region_year.csv');totals=defaultdict(float);asia={}
    for r in regional:
        k=tuple(r[x] for x in ['panel','hale_convention','epsilon','year'])
        if r['region']=='Asia':asia[k]=float(r['VLW'])
        else:totals[k]+=float(r['VLW'])
    check('Six regions reconcile to Asia',all(close(asia[k],v) for k,v in totals.items()))
    bases={r['location_id']:float(r['VSLY']) for r in a if r['year']=='1990' and r['sex_name']=='Both' and r['location_id'] in fixed}
    fixed2023=sum(float(r['DALYs'])*bases[r['location_id']] for r in a if r['year']=='2023' and r['sex_name']=='Both' and r['location_id'] in fixed)
    idx=rows(out/'Data/Figure_S6_index_comparison_fixed43.csv')
    check('Fixed valuation uses country-specific products',close(fixed2023,next(r['value'] for r in idx if r['year']=='2023' and r['series']=='VLW fixed 1990 VSLY')))
    check('Age weights recover provided ASDR',all(close(r['calc'],r['provided']) for r in rows(out/'QA/age_standard_check.csv')))
    dc=rows(out/'Tables/Table_S2_decomposition_45countries.csv')
    check('Decomposition sums to observed change',len(dc)==52 and all(close(sum(float(r[n]) for n in ['Aging','Population','Epidemiological_Change']),float(r['DALYs_2023'])-float(r['DALYs_1990'])) for r in dc))
    roll=rows(out/'Data/rolling_origin_predictions.csv')
    check('Temporal validation target dates',all(int(r['year'])==int(r['origin'])+int(r['horizon']) and int(r['origin'])<int(r['year'])<=2019 for r in roll))
    proj=rows(out/'Data/scenario_projections_2024_2050.csv');total=defaultdict(float);asia={}
    for r in proj:
        k=tuple(r[x] for x in ['panel','model','year'])
        if r['region']=='Asia':asia[k]=float(r['predicted'])
        else:total[k]+=float(r['predicted'])
    check('Scenario totals are regional sums',all(close(v,asia[k]) for k,v in total.items()))
    refs=json.loads((ROOT/'Documentation/reference_results.json').read_text())
    total2023=sum(float(r['VLW']) for r in a if r['year']=='2023' and r['sex_name']=='Both')
    check('2023 total matches frozen reference',close(total2023,refs['VLW_2023_45countries']))
    both2023=[r for r in a if r['year']=='2023' and r['sex_name']=='Both']
    check('2023 GDP ratio and per-capita result match reference',close(100*total2023/sum(float(r['GDP']) for r in both2023),refs['VLW_GDP_2023_pct']) and close(total2023/sum(float(r['population']) for r in both2023),refs['VLW_per_capita_2023']))
    if args.reference_dir:
        ref=rows(args.reference_dir/'analysis_ready_primary.csv');ref={key(r):r for r in ref}
        fields=['DALYs','HALE','GDP_per_capita','GDP','population','VSL','VSLY','VLW','VLW_GDP','per_capita_VLW']
        check('Every primary record matches frozen data',len(ref)==len(a) and all(all(close(r[n],ref[key(r)][n]) for n in fields) for r in a))
        ref=rows(args.reference_dir/'valuation_all_scenarios.csv.gz');ref={(key(r),float(r['epsilon']),float(r['hale_factor'])):r for r in ref}
        check('Every scenario matches frozen data',len(ref)==len(s) and all(all(close(r[n],ref[key(r),float(r['epsilon']),float(r['hale_factor'])][n]) for n in fields) for r in s))
    p=out/'QA/validation_checks.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(checks,indent=2))
    print(f'PASS: {len(checks)} independent validation checks.')

if __name__=='__main__':main()
