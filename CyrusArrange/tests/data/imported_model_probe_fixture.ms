/* Portable frozen CC0 fixture. Runner copies tests/ into its private bundle.
   Require that owned root; import only exact private output copies. */
global CA_TEST_ROOT
if CA_TEST_ROOT==undefined or (classOf CA_TEST_ROOT)!=String or CA_TEST_ROOT=="" do throw "Owned runner CA_TEST_ROOT is required for the portable imported-model fixture."
global CA_IMPORT_ASSET_ROOT=CA_TEST_ROOT+"tests/data/imported-model-assets/"
global CA_IMPORT_SOURCE_MANIFEST_SHA256=@"c222487d78c3ffea0a8dabb15652a0005b83959d6b778981b5273cb652283d5e"
global CA_IMPORT_FILES=#(
    #(@"modern_wooden_cabinet",@"assets/modern_wooden_cabinet/modern_wooden_cabinet_1k.fbx",@"606c105e4ee2082fb179bf495965d83d21c1945f005649f99eb783698f590dbe",799676,@"https://dl.polyhaven.org/file/ph-assets/Models/fbx/1k/modern_wooden_cabinet/modern_wooden_cabinet_1k.fbx"),
    #(@"modern_wooden_cabinet",@"assets/modern_wooden_cabinet/textures/modern_wooden_cabinet_diff_1k.jpg",@"e494b67439da73775413d6aaea369ae05a8ebd7705be8df08dbcd2ee4fd545e4",670353,@"https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/modern_wooden_cabinet/modern_wooden_cabinet_diff_1k.jpg"),
    #(@"wooden_bookshelf_worn",@"assets/wooden_bookshelf_worn/wooden_bookshelf_worn_1k.fbx",@"0e7b4870f4def36822d2466ed9e47bd5162279a64117e37a7e76eca97ae640ba",314092,@"https://dl.polyhaven.org/file/ph-assets/Models/fbx/1k/wooden_bookshelf_worn/wooden_bookshelf_worn_1k.fbx"),
    #(@"wooden_bookshelf_worn",@"assets/wooden_bookshelf_worn/textures/wooden_bookshelf_worn_diff_1k.jpg",@"970f60178decadd0d8fb1e5872f718350a49b027fd69469210c41ead350cba56",799126,@"https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/wooden_bookshelf_worn/wooden_bookshelf_worn_diff_1k.jpg"),
    #(@"standing_picture_frame_02",@"assets/standing_picture_frame_02/standing_picture_frame_02_1k.fbx",@"188a4a5d288aac72e17dce41d0bc2ece0bc4ad0da31f033ddc83f1bf5063abc8",134348,@"https://dl.polyhaven.org/file/ph-assets/Models/fbx/1k/standing_picture_frame_02/standing_picture_frame_02_1k.fbx"),
    #(@"standing_picture_frame_02",@"assets/standing_picture_frame_02/textures/standing_picture_frame_02_artwork_diff_1k.png",@"e5655ab3a732751e817718e2655501e8485feb5fc64508535a2a3ac22fe5f869",1004756,@"https://dl.polyhaven.org/file/ph-assets/Models/png/1k/standing_picture_frame_02/standing_picture_frame_02_artwork_diff_1k.png"),
    #(@"standing_picture_frame_02",@"assets/standing_picture_frame_02/textures/standing_picture_frame_02_diff_1k.jpg",@"9090300e8397c6ff14262276e4b162d9adfd128b785aeca255006fe06a1b2945",166316,@"https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/standing_picture_frame_02/standing_picture_frame_02_diff_1k.jpg"),
    #(@"ceramic_vase_02",@"assets/ceramic_vase_02/ceramic_vase_02_1k.fbx",@"468e06315795f91a6c5d324e57469b23a132d114f519031c58f48b0fc7ff6852",295004,@"https://dl.polyhaven.org/file/ph-assets/Models/fbx/1k/ceramic_vase_02/ceramic_vase_02_1k.fbx"),
    #(@"ceramic_vase_02",@"assets/ceramic_vase_02/textures/ceramic_vase_02_diff_1k.jpg",@"12320e404c744095945b164293e522baadb6a0b393648f5908bfea2903f7fcc0",98894,@"https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/ceramic_vase_02/ceramic_vase_02_diff_1k.jpg"),
    #(@"wooden_bowl_02",@"assets/wooden_bowl_02/wooden_bowl_02_1k.fbx",@"693bc97c84dab9132f38fea233ad9301e4e1e494733ed6b4009727effca75484",147484,@"https://dl.polyhaven.org/file/ph-assets/Models/fbx/1k/wooden_bowl_02/wooden_bowl_02_1k.fbx"),
    #(@"wooden_bowl_02",@"assets/wooden_bowl_02/textures/wooden_bowl_02_diff_1k.jpg",@"a3bb80f6ea747491fe91628badc0b98d320fc6d427682564095aba6033a523dc",805338,@"https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/wooden_bowl_02/wooden_bowl_02_diff_1k.jpg")
)
global CA_IMPORT_CASES=#(
    #(@"modern_wooden_cabinet",@"assets/modern_wooden_cabinet/modern_wooden_cabinet_1k.fbx",[2440.0004148483,520.0000107288,680.1425069571],24976,@"Modern Wooden Cabinet",@"Patrik Pangerl",@"https://polyhaven.com/a/modern_wooden_cabinet"),
    #(@"wooden_bookshelf_worn",@"assets/wooden_bookshelf_worn/wooden_bookshelf_worn_1k.fbx",[1373.9517927170,581.3020169735,2063.4420514107],10106,@"Wooden Bookshelf Worn",@"Ulan Cabanilla",@"https://polyhaven.com/a/wooden_bookshelf_worn"),
    #(@"standing_picture_frame_02",@"assets/standing_picture_frame_02/standing_picture_frame_02_1k.fbx",[216.8921604753,102.2887229919,266.3925290108],2986,@"Standing Picture Frame 02",@"James Ray Cock",@"https://polyhaven.com/a/standing_picture_frame_02"),
    #(@"ceramic_vase_02",@"assets/ceramic_vase_02/ceramic_vase_02_1k.fbx",[219.8381572962,221.4527726173,309.2874630820],2756,@"Ceramic Vase 02",@"James Ray Cock",@"https://polyhaven.com/a/ceramic_vase_02"),
    #(@"wooden_bowl_02",@"assets/wooden_bowl_02/wooden_bowl_02_1k.fbx",[130.7134702802,124.5396770537,73.0979447981],4666,@"Wooden Bowl 02",@"Kuutti Siitonen",@"https://polyhaven.com/a/wooden_bowl_02")
)
