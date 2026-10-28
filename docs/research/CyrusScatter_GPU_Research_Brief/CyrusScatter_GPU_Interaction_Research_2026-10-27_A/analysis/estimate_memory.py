#!/usr/bin/env python3
"""Analytical byte/precision calculations only. Not a CPU/GPU performance benchmark.
Run: python3 analysis/estimate_memory.py > analysis/calculated_estimates.json
All sizes are proposed layouts. The 451/22032/27501 counts are supplied context.
"""
import json, math, struct

def f32_ulp(x):
    bits = struct.unpack('<I', struct.pack('<f', x))[0]
    return struct.unpack('<f', struct.pack('<I', bits+1))[0] - struct.unpack('<f', struct.pack('<I', bits))[0]

G, V, T, S = 451, 22032, 27501, 8
pose_per_guide = 16 + S*32
source_parts = {'draw_vertices_48B':V*48,'triangle_indices_12B':T*12,'triangle_material_4B':T*4,'bindings_32B':V*32,'guide_descriptors_32B':G*32,'rest_nodes_32B':G*S*32,'rest_spans_16B':G*(S-1)*16}
scenes=[]
for k in (1,10,100,1000,10000,1000000):
    p=k*G*pose_per_guide
    m=k*V*32
    scenes.append({'affected_instances':k,'changed_guides_all':k*G,'pose_nodes':k*G*S,'guide_pose_and_directory_bytes':p,'position_normal_output_bytes':m,'triple_pose_plus_output_bytes':3*(p+m),'pose_one_way_ms_at_12_decimal_GBps':p/12e9*1000,'mesh_one_way_ms_at_12_decimal_GBps':m/12e9*1000,'pose_one_way_ms_at_24_decimal_GBps':p/24e9*1000,'mesh_one_way_ms_at_24_decimal_GBps':m/24e9*1000})
result={
    'status':'ANALYTICAL ESTIMATES; formula evaluation executed; no hardware benchmark',
    'assumptions':{'guides_per_clump':G,'logical_vertices_assumed_equal_render_vertices_for_lower_bound':V,'triangles':T,'pose_nodes_per_guide_proposed':S,'instance_record_bytes':96,'pose_node_bytes':32,'active_guide_directory_bytes':16,'position_normal_output_bytes_per_vertex':32,'additional_tangent_bytes_if_stored':16,'units':'bytes; decimal MB=10^6; decimal GB=10^9'},
    'shared_source_parts':source_parts,'shared_source_total_bytes':sum(source_parts.values()),
    'resident_1M_instance_record_bytes':1000000*96,'resident_1M_pose_directory_handles_4B':1000000*4,
    'dense_1M_by451_4B_lookup_bytes':1000000*G*4,
    'root_masks_1M_assuming451_groups_bytes':1000000*math.ceil(G/32)*4,
    'scenarios':scenes,
    'simple_1M_blades_assuming1guide4nodes4vertices':{'pose_bytes':1000000*(16+4*32),'position_normal_output_bytes':1000000*4*32},
    'plant_collider_pair_bytes_K10k_c64_stride16':10000*64*16,
    'sdf_2m_cube_float32':{'h_1cm_cells_200cubed_bytes':200**3*4,'h_1mm_cells_2000cubed_bytes':2000**3*4,'h_1cm_nodes_201cubed_bytes':201**3*4,'h_1mm_nodes_2001cubed_bytes':2001**3*4},
    'f32_spacing_metres':{str(x):f32_ulp(x) for x in (1.,1000.,10000.,1000000.)},
    'frame_period_ms':{str(hz):1000/hz for hz in (30,60,120)}
}
print(json.dumps(result,indent=2))
