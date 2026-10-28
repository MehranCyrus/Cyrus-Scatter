"""Generate bounded collider-count kernel tests from a real captured contact."""
from argparse import ArgumentParser
from pathlib import Path
import json

parser = ArgumentParser()
parser.add_argument('--fixture', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--plants', type=int, default=1)
parser.add_argument('--collider-height', type=float, help='Collider Z in the fixture\'s host units')
parser.add_argument('--include-large', action='store_true', help='Also generate the 16,384-obstacle successor tier')
args = parser.parse_args()
original = json.loads(args.fixture.read_text(encoding='utf-8'))
obstacles = [x for x in original['instances'] if original['layers'][x['layer']]['role'] & 1]
if len(obstacles) != 1:
    raise ValueError('The captured fixture must have exactly one movable collider')
plants = [x for x in original['instances'] if original['layers'][x['layer']]['role'] & 2]
if len(plants) != 1 or not 1 <= args.plants <= 2000:
    raise ValueError('Exactly one source plant and a bounded requested plant count are required')
args.output.mkdir(parents=True, exist_ok=False)
for count in ((1, 128, 1024, 4096, 16384) if args.include_large else (1, 128, 1024, 4096)):
    fixture = json.loads(json.dumps(original))
    fixture['audit'] = False
    if args.collider_height is not None:
        for item in fixture['instances']:
            if fixture['layers'][item['layer']]['role'] & 1:
                item['transform'][11] = args.collider_height
    for index in range(1, args.plants):
        item = dict(plants[0])
        item['identity'] = 'dense:' + str(index)
        item['transform'] = list(item['transform'])
        # Dense overlapping bounds isolate broad-phase costs; this is not an
        # art-directed distribution or a claim about presented performance.
        item['transform'][9] += ((index % 20) - 10) * .25
        item['transform'][10] += ((index // 20) % 20 - 10) * .25
        fixture['instances'].append(item)
    for index in range(1, count):
        item = dict(obstacles[0])
        item['identity'] = 'remote:' + str(index)
        item['transform'] = list(item['transform'])
        # Far-away obstacles cannot enter the real plant contact neighborhood.
        # The scene is numerical kernel input; this is not a Max viewport test.
        item['transform'][9] += 100000. + (index % 256) * 100.
        item['transform'][10] += 100000. + (index // 256) * 100.
        fixture['instances'].append(item)
    fixture['scale_fixture'] = {'obstacles': count, 'plants': args.plants, 'real_source': True,
                                'collider_height_host_units': args.collider_height,
                                'scope': 'Captured real plant source; additional plant bounds are densely arranged and extra obstacles deliberately distant. Kernel only.'}
    (args.output / ('obstacles-' + str(count) + '.json')).write_text(json.dumps(fixture, indent=2), encoding='utf-8')
    print(count)
