#!/usr/bin/env python3
"""Deterministic arithmetic, not a GPU/Max benchmark. Python 3 standard library."""
import json
import math
import struct

def f32(x):
    return struct.unpack('<f', struct.pack('<f', x))[0]

def ulp32_positive(x):
    bits = struct.unpack('<I', struct.pack('<f', x))[0]
    return struct.unpack('<f', struct.pack('<I', bits + 1))[0] - f32(x)

def describe_bytes(n):
    return {'bytes': n, 'MB_decimal': n / 1e6, 'GB_decimal': n / 1e9,
            'GiB_binary': n / (1024**3)}

def main():
    G, V, T, nodes = 451, 22032, 27501, 8
    result = {
        'status': 'Executed arithmetic; all population/layout choices are assumptions, not measured allocations',
        'assumptions': {'source_guides_supplied': G, 'source_vertices_supplied': V,
            'source_triangles_supplied': T, 'nodes_per_guide_assumed': nodes,
            'pose_node_bytes_assumed': 32, 'source_node_bytes_assumed': 48,
            'guide_header_bytes_assumed': 32, 'instance_bytes_assumed': 80,
            'rest_vertex_bytes_assumed': 48, 'single_binding_bytes_assumed': 32,
            'triangle_index_bytes_assumed': 12, 'triangle_metadata_bytes_assumed': 8,
            'expanded_dynamic_position_normal_bytes_per_vertex': 24,
            'root_groups_equal_guides_for_mask_example_only': True},
        'shared_source_lower_model': describe_bytes(V*(48+32)+T*(12+8)+G*(32+nodes*48)),
        'populations': [],
        'fp32_spacing_metres': [],
        'frame_targets_ms': {str(hz): 1000/hz for hz in (30,60,120)},
        'dense_scalar_field': [],
    }
    for N in (1000,10000,100000,1000000):
        row = {'N':N, 'instance_records':describe_bytes(N*80),
            'dense_guide_table_4byte_if_every_instance_has_table':describe_bytes(N*G*4),
            'dense_guide_table_8byte_if_every_instance_has_table':describe_bytes(N*G*8),
            'all_active_pose_32B_8nodes':describe_bytes(N*G*nodes*32),
            'all_active_pose_three_versions':describe_bytes(N*G*nodes*32*3),
            'expanded_position_normal':describe_bytes(N*V*24),
            'word_padded_visibility_mask':describe_bytes(N*math.ceil(G/32)*4)}
        result['populations'].append(row)
    result['sparse_examples'] = {
        'N_1M_K_10_all_guides_pose':describe_bytes(10*G*nodes*32),
        'N_1M_K_10_changed_six_guides_pose_total':describe_bytes(6*nodes*32),
        'six_guides_headers_16B':describe_bytes(6*16),
        'K_10_expanded_position_normal':describe_bytes(10*V*24),
        'K_10000_all_guides_compact_pose_readback':describe_bytes(10000*G*nodes*32),
        'K_10000_expanded_position_normal':describe_bytes(10000*V*24),
        'K_10000_naive_8_colliders_per_span_pairs_16B':describe_bytes(10000*G*(nodes-1)*8*16),
        'K_10000_plant_collider_pairs_8_each_16B':describe_bytes(10000*8*16),
        'all_active_1M_simple_blades_8nodes_pose':describe_bytes(1000000*nodes*32),
    }
    for K in (10,1000,10000):
        size=K*G*nodes*32
        result.setdefault('conditional_transfer_only_lower_bounds',[]).append({
            'K':K,'bytes':size,'assumed_effective_link_GBps':12,
            'one_direction_ms':size/(12e9)*1000,
            'warning':'Illustrative 12 GB/s, not measured; excludes wait, dispatch, packing, validation, graphics upload and contention'})
    for x in (1.0,10.0,1000.0,100000.0,1000000.0):
        result['fp32_spacing_metres'].append({'coordinate_m':x,'ulp_m':ulp32_positive(x),
            'direct_quantized_1mm_delta_m':f32(x+0.001)-f32(x),
            'double_rebased_then_fp32_1mm_delta_m':f32((x+0.001)-x)})
    for extent,cell in ((2.0,0.01),(2.0,0.005),(20.0,0.01)):
        side=math.ceil(extent/cell)+1
        result['dense_scalar_field'].append({'extent_m':extent,'cell_m':cell,'samples_per_axis':side,
            'scalar_float32':describe_bytes(side**3*4),
            'scalar_plus_xyz_gradient_float32':describe_bytes(side**3*16)})
    # Basic internal arithmetic invariants; these do not exercise any application.
    assert result['populations'][-1]['all_active_pose_32B_8nodes']['bytes']==115456000000
    assert result['populations'][-1]['expanded_position_normal']['bytes']==528768000000
    assert result['fp32_spacing_metres'][-1]['ulp_m']==0.0625
    assert result['sparse_examples']['six_guides_headers_16B']['bytes']==96
    print(json.dumps(result,indent=2,sort_keys=True))

if __name__=='__main__':
    main()
