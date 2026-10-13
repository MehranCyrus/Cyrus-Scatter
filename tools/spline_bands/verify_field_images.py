"""Independent pixel checks for captured integrated field/inspection feedback."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('receipt',type=Path);args=parser.parse_args()
    source=json.loads(args.receipt.read_text());assert source['passed'], 'Capture did not pass'
    images={};stats={};checks=[]
    def check(ok,label):
        checks.append({'passed':bool(ok),'label':label})
        if not ok:raise AssertionError(label)
    for entry in source['images']:
        path=Path(entry['path']);assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
        im=Image.open(path).convert('RGB');images[entry['label']]=im
        red=blue=white=green=0
        for r,g,b in im.getdata():
            red+=r>170 and g<90 and b<90
            blue+=b>170 and r<90 and g<90
            green+=g>130 and g>r*1.5 and g>b*1.5
            white+=min(r,g,b)>190
        stats[entry['label']]={'red':red,'blue':blue,'white':white,'green':green}
    report={'capture_sha256':hashlib.sha256(args.receipt.read_bytes()).hexdigest(),'checks':checks,'pixels':stats}
    try:
        for label in ('retained-field','retained-boundaries','retained-bundle','fallback-bundle'):
            for color in ('red','blue'):
                check(stats[label][color]>stats['plants-only'][color]+100, label+': '+color+' density is visibly distinct from plants alone')
        for label in ('retained-boundaries','retained-bundle','fallback-bundle'):
            check(stats[label]['white']>stats['retained-field']['white']+50, label+': white inspection lines are visible')
        check(ImageChops.difference(images['retained-boundaries'],images['retained-bundle']).getbbox() is not None,
              'Radius display changes the actual combined inspection image')
        check(stats['retained-bundle']['green']>stats['retained-boundaries']['green']+50, 'Published radius rings are visibly green in the actual bundle')
        for color in ('red','blue','white','green'):
            ratio=stats['fallback-bundle'][color]/max(1,stats['retained-bundle'][color])
            check(.8<ratio<1.2,'Fallback '+color+' coverage agrees with the retained bundle within rasterization tolerance')
        check(ImageChops.difference(images['fallback-bundle'],images['empty-background']).getbbox() is not None,
              'The production fallback draws the combined field and radius bundle')
        report['passed']=True
    except Exception as error:
        report.update(passed=False,error=str(error));raise
    finally:
        output=args.receipt.with_name(args.receipt.stem+'-verified.json');output.write_text(json.dumps(report,indent=2)+'\n')
    print(str(output)+': '+str(len(checks))+' image checks passed')

if __name__=='__main__':main()
