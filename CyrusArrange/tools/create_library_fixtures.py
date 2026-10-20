"""Create tiny original format-1 asset fixtures with an independent struct/zlib writer."""
from pathlib import Path
import struct
import zlib


def encode_asset(*, open_top=False):
    u32 = lambda n: struct.pack("<I", n)
    u64 = lambda n: struct.pack("<Q", n)
    real = lambda n: struct.pack("<d", n)
    point = lambda p: struct.pack("<3d", *p)
    points = lambda ps: u32(len(ps)) + b"".join(point(p) for p in ps)
    vertices = [(-50, -35, 0), (50, -35, 0), (50, 35, 0), (-50, 35, 0),
                (-50, -35, 20), (50, -35, 20), (50, 35, 20), (-50, 35, 20)]
    faces = [(0, 2, 1), (0, 3, 2), (0, 1, 5), (0, 5, 4), (1, 2, 6),
             (1, 6, 5), (2, 3, 7), (2, 7, 6), (3, 0, 4), (3, 4, 7)]
    if not open_top:
        faces += [(4, 5, 6), (4, 6, 7)]
    name = b"Independent open-top stack fixture" if open_top else b"Independent closed stack fixture"
    data = b"CYASSET\0" + u32(1) + u32(0x01020304) + u32(1)
    data += u64(1) + u32(len(name)) + name + u32(0) + u32(31)
    data += point((0, 0, 0)) + point((-50, -35, 0)) + point((50, 35, 20))
    data += points(vertices[:4]) + u32(1) + real(0)
    data += real(1) * 3 + u32(1) + real(20) + points(vertices[4:]) + u32(3)
    data += points(vertices) + u32(len(faces)) + b"".join(struct.pack("<3I", *f) for f in faces)
    return data + u32(zlib.crc32(data))


if __name__ == "__main__":
    target = Path(__file__).resolve().parents[1] / "tests/data"
    target.mkdir(exist_ok=True)
    for name, open_top in (("stack-closed.cyalib", False), ("stack-open.cyalib", True)):
        (target / name).write_bytes(encode_asset(open_top=open_top))
        print(target / name)
