"""Derive a pinned experiment-only C variant; original reviewed sources stay unchanged."""
from pathlib import Path
import hashlib, json, sys
source=Path(sys.argv[1]);out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
original=(source/'geometry.hpp').read_bytes()
assert hashlib.sha256(original).hexdigest()=='2881c73a606fb727e67de3ec7609d654649c7c097a4b07b9a721cbb4155a085b', 'Unexpected original C header'
old='''inline bool unique_nonzero_render_ids(const std::vector<BoundVertex>& bindings) {
    for (std::size_t i = 0; i < bindings.size(); ++i) {
        if (bindings[i].render_vertex_id == 0 || bindings[i].logical_vertex_id == 0) return false;
        for (std::size_t j = 0; j < i; ++j)
            if (bindings[j].render_vertex_id == bindings[i].render_vertex_id) return false;
    }
    return true;
}'''
new='''inline bool unique_nonzero_render_ids(const std::vector<BoundVertex>& bindings) {
    // Private dense experiment: at most 2M admitted IDs, <=16 MiB temporary payload.
    std::vector<Id> sorted;
    sorted.reserve(bindings.size());
    for (const auto& binding : bindings) {
        if (binding.render_vertex_id == 0 || binding.logical_vertex_id == 0) return false;
        sorted.push_back(binding.render_vertex_id);
    }
    std::sort(sorted.begin(), sorted.end());
    return std::adjacent_find(sorted.begin(), sorted.end()) == sorted.end();
}'''
text=original.decode();assert text.count(old)==1;changed=text.replace(old,new).encode()
(out/'geometry.hpp').write_bytes(changed)
for name in ('evaluator.cpp','validator.cpp','diagnostic_obj.cpp','diagnostic_obj.hpp'):(out/name).write_bytes((source/name).read_bytes())
(out/'variant.json').write_text(json.dumps({'scope':'Private experiment only; source remains unchanged','change':'unique_nonzero_render_ids: nested scan -> sorted duplicate check','original_sha256':hashlib.sha256(original).hexdigest(),'variant_sha256':hashlib.sha256(changed).hexdigest(),'maximum_additional_id_payload_bytes':16000000},indent=2))
