"""Documented C++20 and resource bounds for the pinned native dependency."""
from pathlib import Path
p=Path(__file__).resolve().parents[2]/'AminScatter/third_party/geodesic'
assert not (p/'CYRUS_CHANGES.md').exists(), 'Patch pristine pinned headers once; do not overwrite the maintained integration'
def edit(name,old,new):
 f=p/name;s=f.read_text();assert old in s,(name,old);f.write_text(s.replace(old,new),encoding='utf-8')
edit('geodesic_memory.h','#include <memory>','#include <memory>\n#include <stdexcept>')
edit('geodesic_memory.h','std::auto_ptr<double>','std::unique_ptr<double[]>')
edit('geodesic_memory.h','m_storage.push_back( std::vector<T>() );',
     'if(m_storage.size() >= m_max_number_of_blocks) throw std::runtime_error("Surface brush memory admission exceeded; previous paint retained");\n\t\t\tm_storage.push_back( std::vector<T>() );')
edit('geodesic_algorithm_exact.h','m_memory_allocator(mesh->edges().size(), mesh->edges().size())','m_memory_allocator(4096, 64)')
edit('geodesic_algorithm_exact.h','void print_statistics();','void print_statistics();\n\tunsigned propagation_steps() const { return m_iterations; } // Cyrus aggregate work admission.')
edit('geodesic_algorithm_exact.h','m_queue_max_size = std::max(m_queue.size(), (size_t)m_queue_max_size);',
     'if(m_iterations >= 2000000 || m_queue.size() > 262144) throw std::runtime_error("Surface brush propagation capacity exceeded; previous paint retained");\n\t\tm_queue_max_size = static_cast<unsigned>(std::max(m_queue.size(), (size_t)m_queue_max_size));')
# Debug-only upstream connectedness printing is inappropriate for multi-component receivers.
edit('geodesic_mesh.h','assert(verify());','// Cyrus validates numeric/topology admission before initialization; disconnected components are supported.')
(p/'CYRUS_CHANGES.md').write_text('''# Local integration changes

Geodesic implementation: Copyright (C) 2008 Danil Kirsanov, MIT License.
Distribution: pygeodesic, Copyright (c) 2021 Michael Hogg, MIT License.
The accompanying SurfaceGeodesic-LICENSE.txt supplies the MIT permission terms.
Source: https://github.com/mhogg/pygeodesic at
8106598e5575c44ec2d74965362459e1c421896a.

Pinned upstream bytes/hashes are in UPSTREAM.json. The original MIT headers and
license are retained. Local modifications replace removed auto_ptr with owning
array unique_ptr, enforce allocator block capacity, cap exact-solver allocation
at 262,144 intervals and propagation at 2,000,000 steps, and remove debug-only
connectedness printing. An accessor exposes propagation steps for aggregate
import-work admission. Mesh numeric/manifold admission is performed by the
Cyrus adapter before calling the dependency. No upstream test result qualifies
these changes; the surface brush native and Max tests own acceptance.
''',encoding='utf-8')
