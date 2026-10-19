"""Generate three small density qualification fixtures, not final product artwork."""
from pathlib import Path
import argparse, hashlib, json, math, random, struct, zlib

SIZE = 256
VERSION = 1
TAU = 2 * math.pi


def smooth(a, b, x):
    t = max(0., min(1., (x-a)/(b-a)))
    return t*t*(3-2*t)


def noise(seed, anisotropy=1):
    rng = random.Random(seed)
    grids=[]
    for i in range(1,6):
        nx,ny=2**i,max(1,2**i//anisotropy)
        grids.append((nx,ny,[rng.random() for _ in range(nx*ny)],.55**i))
    total=sum(row[3] for row in grids)
    def sample(u,v):
        value=0.
        for nx,ny,data,weight in grids:
            x,y=(u%1)*nx,(v%1)*ny;ix,iy=math.floor(x),math.floor(y)
            a,b=smooth(0,1,x-ix),smooth(0,1,y-iy)
            at=lambda xx,yy:data[(yy%ny)*nx+(xx%nx)]
            value+=((at(ix,iy)*(1-a)+at(ix+1,iy)*a)*(1-b)+(at(ix,iy+1)*(1-a)+at(ix+1,iy+1)*a)*b)*weight
        return value/total
    return sample


def islands(seed, count, radius, softness):
    rng = random.Random(seed)
    centres = [(rng.random(), rng.random(), radius*rng.uniform(.65, 1.35)) for _ in range(count)]
    def sample(u, v):
        value = 0.
        for x,y,r in centres:
            dx,dy=abs(u-x),abs(v-y)
            d=math.hypot(min(dx,1-dx), min(dy,1-dy))
            value=max(value,1-smooth(max(0,r-softness),r+softness,d))
        return value
    return sample


def grid(columns, rows, radius, stagger=False):
    def sample(u,v):
        row=math.floor(v*rows)
        x=(u*columns-(.5 if stagger and row%2 else 0))%1-.5
        y=(v*rows)%1-.5
        return 1-smooth(radius*.7,radius,math.hypot(x,y))
    return sample


def patterns():
    n=noise(73129); fine=noise(39217,4); broad=noise(84631)
    clumps=islands(21983,13,.085,.032); broken=islands(78233,7,.16,.06)
    definitions=[
        ('uniform','Uniform','Uniform',lambda u,v:1.),
        ('fine-grain','Fine grain','Noise',lambda u,v:smooth(.39,.67,noise_grain(u,v))),
        ('open-speckle','Open speckle','Noise',lambda u,v:smooth(.70,.88,noise_grain(u,v))),
        ('soft-clouds','Soft clouds','Noise',lambda u,v:n(u,v)),
        ('soft-patches','Soft patches','Patches',lambda u,v:smooth(.35,.65,n(u,v))),
        ('broken-patches','Broken patches','Patches',lambda u,v:smooth(.47,.55,n(u,v))),
        ('broad-patches','Broad patches','Patches',lambda u,v:smooth(.35,.65,broad(u,v))),
        ('quiet-clumps','Quiet clumps','Clumps',clumps),
        ('dense-clumps','Dense clumps','Clumps',islands(12973,28,.07,.022)),
        ('wind-lines','Wind lines','Streaks',lambda u,v:smooth(.40,.65,fine(v,u))),
        ('long-streaks','Long streaks','Streaks',lambda u,v:smooth(.42,.58,.5+.5*math.sin(TAU*(9*v+.2*math.sin(TAU*2*u))))),
        ('woven-curves','Woven curves','Curves',lambda u,v:smooth(.30,.70,.5+.5*math.sin(TAU*(4*u+2*v+.4*math.sin(TAU*v))))),
        ('ribbons','Ribbons','Curves',lambda u,v:smooth(.65,.85,.5+.5*math.sin(TAU*(5*v+.7*math.sin(TAU*u))))),
        ('round-islands','Round islands','Islands',islands(74353,4,.17,.045)),
        ('broken-islands','Broken islands','Islands',lambda u,v:broken(u,v)*smooth(.27,.6,n(u,v))),
        ('square-dots','Square dots','Grids',grid(8,8,.22)),
        ('offset-dots','Offset dots','Grids',grid(8,8,.3,True)),
        ('fine-lattice','Fine lattice','Grids',grid(16,16,.16)),
        ('wide-bands','Wide bands','Bands',lambda u,v:smooth(.20,.55,.5+.5*math.sin(TAU*3*v))),
        ('thin-bands','Thin bands','Bands',lambda u,v:smooth(.82,.96,.5+.5*math.sin(TAU*6*u))),
        ('cross-bands','Cross bands','Bands',lambda u,v:max(smooth(.85,.98,.5+.5*math.cos(TAU*4*u)),smooth(.85,.98,.5+.5*math.cos(TAU*4*v)))),
        ('soft-centre','Soft centre','Islands',lambda u,v:1-smooth(.14,.46,math.hypot(u-.5,v-.5))),
    ]
    return [row for row in definitions if row[0] in {"uniform","soft-patches","wide-bands"}]


def noise_grain(u,v):
    # A periodic integer hash; no global RNG or artist/placement seed is consumed.
    x,y=int(u*SIZE)%SIZE,int(v*SIZE)%SIZE
    value=(x*374761393+y*668265263+51047)&0xffffffff
    value=((value^(value>>13))*1274126177)&0xffffffff
    return ((value^(value>>16))&0xffffffff)/4294967295.


def png(pixels):
    def chunk(kind,data):
        return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
    # RGB is accepted by the existing portable PNG codec; each channel carries
    # the same scalar. Do not introduce a grayscale-only package incompatibility.
    rgb=bytearray(len(pixels)*3)
    rgb[0::3]=pixels;rgb[1::3]=pixels;rgb[2::3]=pixels
    rows=b''.join(b'\0'+rgb[y*SIZE*3:(y+1)*SIZE*3] for y in range(SIZE))
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!IIBBBBB',SIZE,SIZE,8,2,0,0,0))+chunk(b'gAMA',struct.pack('!I',100000))+chunk(b'IDAT',zlib.compress(rows,9))+chunk(b'IEND',b'')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[2]/'tools/density_0862/patterns')
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    entries=[]
    for identity,name,family,sample in patterns():
        # Image rows run top to bottom; field v runs bottom to top.
        pixels=bytes(round(255*max(0,min(1,sample((x+.5)/SIZE,1-(y+.5)/SIZE)))) for y in range(SIZE) for x in range(SIZE))
        data=png(pixels);path=args.output/(identity+'.png')
        if args.check:
            if not path.is_file() or path.read_bytes()!=data:raise SystemExit('Stale pattern: '+str(path))
        else:path.write_bytes(data)
        entries.append(dict(id=identity,name=name,family=family,file=path.name,sha256=hashlib.sha256(data).hexdigest(),width=SIZE,height=SIZE,minimum=min(pixels)/255,maximum=max(pixels)/255))
    manifest=dict(format='cyrus.density-patterns',version=VERSION,generator='generate_density_patterns.py/1',ownership='Original Cyrus mathematical generation; no vendor image inputs.',interpretation='linear scalar density; image top is v=1',entries=entries)
    data=(json.dumps(manifest,indent=2)+'\n').encode('utf-8');path=args.output/'index.json'
    if args.check:
        if not path.is_file() or path.read_bytes()!=data:raise SystemExit('Stale pattern catalog')
    else:path.write_bytes(data)
    catalog=''.join('\t'.join((item['id'],item['name'],item['family'],item['file'],item['sha256']))+'\n' for item in entries).encode('utf-8')
    path=args.output/'catalog.tsv'
    if args.check:
        if not path.is_file() or path.read_bytes()!=catalog:raise SystemExit('Stale picker catalog')
    else:path.write_bytes(catalog)
    print(('Verified' if args.check else 'Generated'),len(entries),'original Cyrus density patterns in',args.output)


if __name__=='__main__':main()
