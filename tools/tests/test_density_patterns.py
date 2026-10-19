"""Independent properties of the original pattern data and portable PNG wrapper."""
import importlib.util
import json
from pathlib import Path
import struct
import zlib
import hashlib

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('cyrus_density_patterns',ROOT/'AminScatter/tools/generate_density_patterns.py')
patterns=importlib.util.module_from_spec(spec)
spec.loader.exec_module(patterns)


def test_original_catalog_has_resolved_unique_rgb_masks():
    folder=ROOT/'AminScatter/patterns'
    catalog=json.loads((folder/'index.json').read_text(encoding='utf-8'))
    assert {item['id'] for item in catalog['entries']}=={'uniform','soft-patches','wide-bands'}
    assert 'no vendor image inputs' in catalog['ownership']
    assert len({row['id'] for row in catalog['entries']})==len(catalog['entries'])
    assert len({row['sha256'] for row in catalog['entries']})==len(catalog['entries'])
    for row in catalog['entries']:
        data=(folder/row['file']).read_bytes()
        assert hashlib.sha256(data).hexdigest()==row['sha256']
        assert data[:8]==b'\x89PNG\r\n\x1a\n'
        width,height,depth,kind,compression,filtering,interlace=struct.unpack('!IIBBBBB',data[16:29])
        assert (width,height,depth,kind,compression,filtering,interlace)==(256,256,8,2,0,0,0)
        compressed=b'';at=8
        while at<len(data):
            size=struct.unpack('!I',data[at:at+4])[0]
            chunk=data[at+4:at+8];payload=data[at+8:at+8+size]
            assert zlib.crc32(chunk+payload)&0xffffffff==struct.unpack('!I',data[at+8+size:at+12+size])[0]
            if chunk==b'IDAT':compressed+=payload
            at+=12+size
        raw=zlib.decompress(compressed)
        assert len(raw)==height*(1+width*3)
        values=[]
        for y in range(height):
            scan=raw[y*(1+width*3):(y+1)*(1+width*3)]
            assert scan[0]==0
            assert scan[1::3]==scan[2::3]==scan[3::3]
            values.extend(scan[1::3])
        assert min(values)/255==row['minimum']
        assert max(values)/255==row['maximum']


def test_pattern_functions_repeat_at_both_tile_edges():
    for identity,_,_,sample in patterns.patterns():
        for q in (.0,.013,.217,.505,.791,.999):
            assert abs(sample(0,q)-sample(1,q))<1e-10,identity
            assert abs(sample(q,0)-sample(q,1))<1e-10,identity
            assert 0<=sample(q,.371)<=1,identity


def test_noise_parameters_and_seeds_are_reproducible_and_independent():
    a,b,c=patterns.noise(741),patterns.noise(741),patterns.noise(742)
    points=[(.13,.76),(.39,.24),(.86,.51)]
    assert [a(*p) for p in points]==[b(*p) for p in points]
    assert [a(*p) for p in points]!=[c(*p) for p in points]
