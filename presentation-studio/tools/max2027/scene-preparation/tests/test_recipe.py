import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('recipe', Path(__file__).resolve().parents[1] / 'recipe.py')
recipe = importlib.util.module_from_spec(spec); spec.loader.exec_module(recipe)


class RecipeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.root = Path(self.temp.name)
        self.path = self.root / 'recipe.json'
    def tearDown(self):
        self.temp.cleanup()
    def read(self, data):
        self.path.write_text(json.dumps(data), encoding='utf-8'); return recipe.read_recipe(self.path)
    def test_defaults_preserve_geometry_materials_and_origin(self):
        data, _ = self.read({'version': 1})
        self.assertEqual(data['nativeReduction']['layers'], [])
        self.assertEqual(data['materials'], {'mode': 'retain', 'rules': []})
        self.assertEqual(data['translationMetres'], [0, 0, 0])
        self.assertEqual(data['post']['textureFormat'], 'preserve'); self.assertIsNone(data['post']['quantization'])
    def test_explicit_lossy_choices_are_bounded_and_closed(self):
        for change in [{'version': True}, {'extra': 1}, {'bakeFrame': True}, {'translationMetres': [float('nan'), 0, 0]}, {'nativeReduction': {'minimumFaces': 1, 'layers': [{'layer': 'A', 'percent': 0, 'keepUV': True}]}}, {'post': {'layers': [], 'textureEdge': 8192, 'textureQuality': 92, 'meshopt': True}}]:
            with self.subTest(change=change), self.assertRaises(ValueError): self.read({'version': 1, **change})
    def test_shared_layer_names_cannot_have_conflicting_rules(self):
        row = {'layer': 'A', 'percent': 50, 'keepUV': True}
        with self.assertRaises(ValueError): self.read({'version': 1, 'nativeReduction': {'minimumFaces': 10, 'layers': [row, row]}})
    def test_texture_substitutions_require_opt_in_existing_files_and_colour_space(self):
        with self.assertRaises(ValueError): self.read({'version': 1, 'materials': {'mode': 'retain', 'rules': [{'pattern': '*', 'label': 'replacement'}]}})
        with self.assertRaises(ValueError): self.read({'version': 1, 'materials': {'mode': 'scalar-approximation', 'rules': [{'pattern': '*', 'label': 'replacement', 'baseColor': [1, 1, 1]}]}})
        texture = self.root / 'owned.png'; texture.write_bytes(b'fixture identity; native decoding tested separately')
        data, identity = self.read({'version': 1, 'materials': {'mode': 'scalar-approximation', 'rules': [{'pattern': '*', 'label': 'replacement', 'baseColorTexture': 'owned.png'}]}})
        self.assertEqual(data['materials']['rules'][0]['baseColorTexture'], str(texture))
        self.assertEqual(identity['textures'][str(texture)], recipe.digest(texture))
    def test_plan_never_replaces_existing_source_or_output(self):
        self.read({'version': 1}); source = self.root / 'original.max'; source.write_bytes(b'owned Max fixture')
        plan = recipe.make_plan(source, self.root / 'fresh', self.path)
        self.assertEqual(plan['sourceSha256'], recipe.digest(source)); self.assertFalse((self.root / 'fresh').exists())
        for output in [source, self.root]:
            with self.assertRaises(ValueError): recipe.make_plan(source, output, self.path)
        (self.root / 'fresh').mkdir(); (self.root / 'fresh' / 'previous.glb').write_bytes(b'complete result')
        with self.assertRaises(ValueError): recipe.make_plan(source, self.root / 'fresh', self.path)
        self.assertEqual((self.root / 'fresh' / 'previous.glb').read_bytes(), b'complete result')
    def test_generated_strings_cannot_inject_maxscript(self):
        self.assertEqual(recipe.max_string('a"\\b\n'), '"a\\"\\\\b\\n"')
    def test_duplicate_json_fields_are_rejected(self):
        self.path.write_text('{"version":1,"version":1}', encoding='utf-8')
        with self.assertRaises(ValueError): recipe.read_recipe(self.path)
    def test_exact_material_names_and_lossy_post_settings_remain_explicit(self):
        data, _ = self.read({'version': 1, 'materials': {'mode': 'scalar-approximation', 'rules': [{'sourceName': 'Glas - algemeen', 'label': 'Artistic glazing', 'baseColor': [.5, .6, .7], 'colorSpace': 'srgb'}]}, 'post': {'layers': [], 'textureEdge': 2048, 'textureQuality': 92, 'meshopt': True, 'textureFormat': 'webp', 'quantization': {'positionBits': 16, 'normalBits': 12, 'uvBits': 16}}})
        self.assertEqual(data['post']['quantization']['normalBits'], 12)
        with self.assertRaises(ValueError): self.read({'version': 1, 'materials': {'mode': 'scalar-approximation', 'rules': [{'sourceName': 'A', 'pattern': '*', 'label': 'ambiguous'}]}})


if __name__ == '__main__':
    unittest.main()
