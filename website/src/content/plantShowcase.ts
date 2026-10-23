export const plantCategories = ['Trees', 'Shrubs', 'Grasses', 'Groundcover', 'Flowers', 'Leaves'] as const
export interface ShowcasePlant { id: string; name: string; category: typeof plantCategories[number]; image: string }
/** Curated original Corona renders; model and map files are not part of this website. */
export const showcasePlants: ShowcasePlant[] = [
  {
    "id": "A073",
    "name": "Broadleaf Tree 02",
    "category": "Trees",
    "image": "./assets/library-showcase/broadleaf-tree-02.jpg"
  },
  {
    "id": "A075",
    "name": "Cypress Tree",
    "category": "Trees",
    "image": "./assets/library-showcase/cypress-tree.jpg"
  },
  {
    "id": "A098",
    "name": "Norway Maple - Red Foliage",
    "category": "Trees",
    "image": "./assets/library-showcase/norway-maple-red-foliage.jpg"
  },
  {
    "id": "A083",
    "name": "Lavender - 01",
    "category": "Shrubs",
    "image": "./assets/library-showcase/lavender-01.jpg"
  },
  {
    "id": "A086",
    "name": "Rugosa Rose - 02",
    "category": "Shrubs",
    "image": "./assets/library-showcase/rugosa-rose-02.jpg"
  },
  {
    "id": "A068",
    "name": "Grass - Bushy Clump",
    "category": "Grasses",
    "image": "./assets/library-showcase/grass-bushy-clump.jpg"
  },
  {
    "id": "A070",
    "name": "Clover - Patch 04",
    "category": "Groundcover",
    "image": "./assets/library-showcase/clover-patch-04.jpg"
  },
  {
    "id": "A088",
    "name": "Arthropodium - 01",
    "category": "Groundcover",
    "image": "./assets/library-showcase/arthropodium-01.jpg"
  },
  {
    "id": "A062",
    "name": "Common Blue Violet - 04",
    "category": "Flowers",
    "image": "./assets/library-showcase/common-blue-violet-04.jpg"
  },
  {
    "id": "A065",
    "name": "Creeping Phlox - 02",
    "category": "Flowers",
    "image": "./assets/library-showcase/creeping-phlox-02.jpg"
  },
  {
    "id": "A023",
    "name": "Sycamore Leaf 15 - Faded Gold",
    "category": "Leaves",
    "image": "./assets/library-showcase/sycamore-leaf-15-faded-gold.jpg"
  },
  {
    "id": "A007",
    "name": "Leaf 07 - Curled Leaf - Dry Brown",
    "category": "Leaves",
    "image": "./assets/library-showcase/leaf-07-curled-leaf-dry-brown.jpg"
  }
]
