"""Closed recipes and source-preserving plans for the private preparation tool."""
from pathlib import Path
import hashlib
import json
import math

VERSION = '0.1.0'


def digest(path):
    result = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            result.update(chunk)
    return result.hexdigest()


def object_fields(value, allowed, required=()):
    if not isinstance(value, dict) or set(value) - set(allowed) or set(required) - set(value):
        raise ValueError('Missing or unknown recipe fields: ' + str(allowed))


def number(value, minimum, maximum):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or not minimum <= value <= maximum:
        raise ValueError(f'Expected a finite number in [{minimum}, {maximum}]')
    return value


def text(value):
    if not isinstance(value, str) or not value or len(value) > 1024 or any(ord(c) < 32 for c in value):
        raise ValueError('Expected a nonempty bounded label without control characters')
    return value


def boolean(value):
    if not isinstance(value, bool):
        raise ValueError('Expected a Boolean')
    return value


def unique_names(rows):
    names = [row['layer'] for row in rows]
    if len(names) != len(set(names)) or len(names) > 256:
        raise ValueError('Layer rules must be unique and bounded')


def read_recipe(path):
    path = Path(path).resolve()
    if path.stat().st_size > 1024 * 1024:
        raise ValueError('Recipe exceeds 1 MiB')
    def closed_pairs(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('Duplicate recipe field: ' + key)
            result[key] = value
        return result
    data = json.loads(path.read_text(encoding='utf-8-sig'), object_pairs_hook=closed_pairs)
    object_fields(data, ['version', 'bakeFrame', 'translationMetres', 'protectedLayers', 'nativeReduction', 'materials', 'post'], ['version'])
    if type(data['version']) is not int or data['version'] != 1:
        raise ValueError('Unsupported preparation recipe version')
    data.setdefault('bakeFrame', 0)
    number(data['bakeFrame'], -100000, 100000)
    if not isinstance(data['bakeFrame'], int):
        raise ValueError('Bake frame must be an integer')
    translation = data.setdefault('translationMetres', [0, 0, 0])
    if not isinstance(translation, list) or len(translation) != 3:
        raise ValueError('Translation must have three canonical metre components')
    for value in translation:
        number(value, -1000000, 1000000)
    protected = data.setdefault('protectedLayers', [])
    if not isinstance(protected, list) or len(protected) > 256 or len(set(map(text, protected))) != len(protected):
        raise ValueError('Protected layer names must be unique and bounded')
    native = data.setdefault('nativeReduction', {'minimumFaces': 5000, 'layers': []})
    object_fields(native, ['minimumFaces', 'layers'], ['minimumFaces', 'layers'])
    if not isinstance(native['minimumFaces'], int):
        raise ValueError('Minimum faces must be an integer')
    number(native['minimumFaces'], 1, 100000000)
    if not isinstance(native['layers'], list):
        raise ValueError('Native layers must be a list')
    for row in native['layers']:
        object_fields(row, ['layer', 'percent', 'keepUV'], ['layer', 'percent', 'keepUV'])
        text(row['layer']); number(row['percent'], 1, 100); boolean(row['keepUV'])
    unique_names(native['layers'])
    materials = data.setdefault('materials', {'mode': 'retain', 'rules': []})
    object_fields(materials, ['mode', 'rules'], ['mode', 'rules'])
    if materials['mode'] not in ['retain', 'scalar-approximation'] or not isinstance(materials['rules'], list) or len(materials['rules']) > 256:
        raise ValueError('Unsupported material mode or rule count')
    if materials['mode'] == 'retain' and materials['rules']:
        raise ValueError('Material replacement rules require explicit approximation mode')
    textures = {}
    for row in materials['rules']:
        object_fields(row, ['sourceName', 'pattern', 'baseColor', 'colorSpace', 'roughness', 'metalness', 'baseColorTexture', 'opacityTexture', 'doubleSided', 'label'], ['label'])
        if ('pattern' in row) == ('sourceName' in row):
            raise ValueError('Material rule needs exactly one sourceName or pattern')
        text(row.get('pattern', row.get('sourceName'))); text(row['label'])
        if 'baseColor' in row:
            if not isinstance(row['baseColor'], list) or len(row['baseColor']) != 3:
                raise ValueError('Base colour must have three components')
            for value in row['baseColor']:
                number(value, 0, 1)
            if row.get('colorSpace') not in ['srgb', 'linear']:
                raise ValueError('Base colour requires an explicit colour space')
        elif 'colorSpace' in row:
            raise ValueError('Colour space requires base colour')
        for field in ['roughness', 'metalness']:
            if field in row:
                number(row[field], 0, 1)
        if 'doubleSided' in row:
            boolean(row['doubleSided'])
        for field in ['baseColorTexture', 'opacityTexture']:
            if field in row:
                original = text(row[field]); texture = (path.parent / original).resolve()
                if not texture.is_file() or texture.suffix.lower() not in ['.png', '.jpg', '.jpeg']:
                    raise ValueError('Native material texture must be an existing PNG/JPEG: ' + original)
                textures[str(texture)] = digest(texture)
                row[field] = str(texture)
    post = data.setdefault('post', {'layers': [], 'textureEdge': 2048, 'textureQuality': 92, 'meshopt': True})
    object_fields(post, ['layers', 'textureEdge', 'textureQuality', 'meshopt', 'textureFormat', 'quantization'], ['layers', 'textureEdge', 'textureQuality', 'meshopt'])
    post.setdefault('textureFormat', 'preserve'); post.setdefault('quantization', None)
    if post['textureFormat'] not in ['preserve', 'webp']:
        raise ValueError('Unsupported texture output format')
    if post['quantization'] is not None:
        object_fields(post['quantization'], ['positionBits', 'normalBits', 'uvBits'], ['positionBits', 'normalBits', 'uvBits'])
        for value in post['quantization'].values():
            number(value, 8, 16)
            if type(value) is not int:
                raise ValueError('Quantization bits must be integers')
    number(post['textureEdge'], 128, 4096); number(post['textureQuality'], 1, 100); boolean(post['meshopt'])
    if not isinstance(post['textureEdge'], int) or not isinstance(post['textureQuality'], int) or not isinstance(post['layers'], list):
        raise ValueError('Invalid post-export settings')
    for row in post['layers']:
        object_fields(row, ['layer', 'ratio', 'error', 'normals'], ['layer', 'ratio', 'error', 'normals'])
        text(row['layer']); number(row['ratio'], .01, 1); number(row['error'], 0, .01)
        if row['normals'] not in ['preserve', 'crease45']:
            raise ValueError('Unsupported normal policy')
    unique_names(post['layers'])
    return data, {'recipePath': str(path), 'recipeSha256': digest(path), 'textures': textures}


def make_plan(source, output, recipe_path):
    source, output = Path(source).resolve(), Path(output).resolve()
    if not source.is_file() or source.suffix.lower() != '.max':
        raise ValueError('Source must be an existing .max file')
    if output.exists():
        raise ValueError('Preserve existing output; choose a fresh destination')
    if output == source or source.is_relative_to(output):
        raise ValueError('Output cannot contain the original source')
    recipe, identities = read_recipe(recipe_path)
    return {'tool': 'Cyrus scene preparation', 'toolVersion': VERSION, 'source': str(source), 'sourceSha256': digest(source), 'sourceBytes': source.stat().st_size, 'output': str(output), 'recipe': recipe, **identities}


def max_string(value):
    # MAXScript quoted strings use the same escapes here; UTF-8 source keeps labels.
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"').replace('\r', '\\r').replace('\n', '\\n').replace('\t', '\\t') + '"'
