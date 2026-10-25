# Local integration changes

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
