// common.h - Synthetic rooted-guide contact-fitting workload shared by the CPU,
// CUDA, OpenCL and D3D11 benchmark harnesses.
//
// IMPORTANT: this is a SYNTHETIC STAND-IN for the Cyrus Scatter fitter. It is not
// the production algorithm and has no access to Cyrus source data. It is used only
// to measure dispatch/transfer overheads, mapping/divergence effects, CPU/GPU
// crossover and CUDA-vs-OpenCL-vs-D3D11 parity on identical inputs.
//
// Conventions: metres, +Y up, source-local frame. Instance transform = positive
// uniform scale s, yaw about +Y, translation t (world = R*s*local + t).
// Collider = capsule (segment a-b, radius r) in world space. Contact gap applied
// exactly once, in world units, converted to local by dividing by s.
#pragma once
#include <cstdint>
#include <cstring>
#include <cmath>
#include <vector>
#include <algorithm>
#include <chrono>
#include <cstdio>

struct F4 { float x, y, z, w; };

// ---------------- deterministic RNG (PCG32) ----------------
struct Pcg32 {
    uint64_t state, inc;
    explicit Pcg32(uint64_t seed, uint64_t seq = 54u) : state(0), inc((seq << 1u) | 1u) { next(); state += seed; next(); }
    uint32_t next() { uint64_t old = state; state = old * 6364136223846793005ULL + inc;
        uint32_t xs = (uint32_t)(((old >> 18u) ^ old) >> 27u); uint32_t rot = (uint32_t)(old >> 59u);
        return (xs >> rot) | (xs << ((-(int)rot) & 31)); }
    float uni() { return (next() >> 8) * (1.0f / 16777216.0f); }
    float range(float a, float b) { return a + (b - a) * uni(); }
};

// ---------------- workload description ----------------
struct Workload {
    uint64_t seed = 20261027;
    int G = 451;          // guides per source
    int Nn = 8;           // nodes per guide (root + Nn-1 free nodes)
    int K = 100;          // candidate (affected) instances supplied by neighbourhood search
    int iters = 8;        // fixed iteration count (history-free: every solve starts at rest)
    float kBend = 0.5f;   // pull toward parent-propagated rest shape
    float gap = 0.01f;    // contact gap in world metres
    float capR = 0.30f;   // collider capsule radius (world metres)
    float spacing = 0.35f;// instance grid spacing (metres)

    // source data (shared by all instances), node-major: rest[i*G + g] = (x,y,z, L_i)
    std::vector<F4> rest;       // Nn*G
    std::vector<F4> gsphere;    // G : guide bounding sphere (cx,cy,cz,radius) local
    // instances: (tx, tz, yaw, scale)
    std::vector<F4> inst;       // K
    // collider capsule in world: a=(x,y,z,r) b=(x,y,z,gap)
    F4 capA{}, capB{};

    void build() {
        Pcg32 rng(seed);
        rest.assign((size_t)Nn * G, F4{});
        gsphere.assign(G, F4{});
        for (int g = 0; g < G; ++g) {
            // grass-like blade: root within 0.12 m of plant origin, length 0.25..0.6 m, random lean
            float rx = rng.range(-0.12f, 0.12f), rz = rng.range(-0.12f, 0.12f);
            float len = rng.range(0.25f, 0.60f);
            float lean = rng.range(0.0f, 0.6f), az = rng.range(0.0f, 6.2831853f);
            float curv = rng.range(0.0f, 0.8f);
            float px = rx, py = 0.f, pz = rz;
            float seg = len / (Nn - 1);
            rest[(size_t)0 * G + g] = F4{px, py, pz, 0.f};
            float mnx = px, mny = py, mnz = pz, mxx = px, mxy = py, mxz = pz;
            for (int i = 1; i < Nn; ++i) {
                float t = (float)i / (Nn - 1);
                float a = lean + curv * t;          // bend increases toward tip
                float dx = std::sin(a) * std::cos(az), dz = std::sin(a) * std::sin(az), dy = std::cos(a);
                px += dx * seg; py += dy * seg; pz += dz * seg;
                rest[(size_t)i * G + g] = F4{px, py, pz, seg};
                mnx = std::min(mnx, px); mny = std::min(mny, py); mnz = std::min(mnz, pz);
                mxx = std::max(mxx, px); mxy = std::max(mxy, py); mxz = std::max(mxz, pz);
            }
            float cx = 0.5f * (mnx + mxx), cy = 0.5f * (mny + mxy), cz = 0.5f * (mnz + mxz);
            float rr = 0.f;
            for (int i = 0; i < Nn; ++i) { F4 p = rest[(size_t)i * G + g];
                float d = std::sqrt((p.x - cx) * (p.x - cx) + (p.y - cy) * (p.y - cy) + (p.z - cz) * (p.z - cz));
                rr = std::max(rr, d); }
            gsphere[g] = F4{cx, cy, cz, rr};
        }
        // K instances on a square grid centred on origin
        inst.assign(K, F4{});
        int side = (int)std::ceil(std::sqrt((double)K));
        for (int k = 0; k < K; ++k) {
            int ix = k % side, iz = k / side;
            float tx = (ix - 0.5f * (side - 1)) * spacing + rng.range(-0.05f, 0.05f);
            float tz = (iz - 0.5f * (side - 1)) * spacing + rng.range(-0.05f, 0.05f);
            inst[k] = F4{tx, tz, rng.range(0.f, 6.2831853f), rng.range(0.8f, 1.2f)};
        }
        // horizontal capsule lying across the field at height 0.25 m
        float half = 0.5f * side * spacing;
        capA = F4{-half, 0.25f, 0.f, capR};
        capB = F4{ half, 0.25f, 0.05f, gap};
    }
};

// ---------------- shared math (host reference, templated on precision) -------------
template <typename R> struct V3 { R x, y, z; };
template <typename R> inline V3<R> v3(R x, R y, R z) { return V3<R>{x, y, z}; }
template <typename R> inline V3<R> operator+(V3<R> a, V3<R> b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
template <typename R> inline V3<R> operator-(V3<R> a, V3<R> b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
template <typename R> inline V3<R> operator*(V3<R> a, R s) { return {a.x * s, a.y * s, a.z * s}; }
template <typename R> inline R dot(V3<R> a, V3<R> b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

// closest point on segment [a,b] to p
template <typename R> inline V3<R> closestOnSeg(V3<R> p, V3<R> a, V3<R> b) {
    V3<R> ab = b - a; R den = dot(ab, ab);
    R t = den > R(0) ? dot(p - a, ab) / den : R(0);
    t = t < R(0) ? R(0) : (t > R(1) ? R(1) : t);
    return a + ab * t;
}

// Per-instance local-frame collider (computed once per instance per event).
template <typename R> struct LocalCap { V3<R> a, b; R rad; /* r+gap, local units */ };

template <typename R> inline LocalCap<R> toLocal(const F4& in, const F4& A, const F4& B) {
    R c = (R)std::cos((R)in.z), s = (R)std::sin((R)in.z), invS = R(1) / (R)in.w;
    auto xf = [&](R x, R y, R z) { R dx = x - (R)in.x, dz = z - (R)in.y; // inverse yaw then scale
        return v3<R>((c * dx + s * dz) * invS, y * invS, (-s * dx + c * dz) * invS); };
    LocalCap<R> L; L.a = xf(A.x, A.y, A.z); L.b = xf(B.x, B.y, B.z);
    L.rad = ((R)A.w + (R)B.w) * invS; // radius + contact gap, applied once, to local units
    return L;
}

// Fit one guide. out[i] for i=0..Nn-1 (root copied). Returns residual penetration (local units).
template <typename R>
inline R fitGuide(const F4* rest, int G, int Nn, int g, const LocalCap<R>& C, int iters, R kBend, V3<R>* p) {
    for (int i = 0; i < Nn; ++i) { F4 q = rest[(size_t)i * G + g]; p[i] = v3<R>(q.x, q.y, q.z); }
    for (int it = 0; it < iters; ++it) {
        for (int i = 1; i < Nn; ++i) {
            F4 r0 = rest[(size_t)(i - 1) * G + g], r1 = rest[(size_t)i * G + g];
            V3<R> target = p[i - 1] + v3<R>((R)r1.x - (R)r0.x, (R)r1.y - (R)r0.y, (R)r1.z - (R)r0.z);
            p[i] = p[i] + (target - p[i]) * kBend;                         // bending surrogate
            V3<R> c = closestOnSeg(p[i], C.a, C.b); V3<R> d = p[i] - c;    // collision projection
            R dist = std::sqrt(dot(d, d));
            if (dist < C.rad) {
                V3<R> n = dist > R(1e-12) ? d * (R(1) / dist) : v3<R>(R(0), R(1), R(0));
                p[i] = c + n * C.rad;
            }
            V3<R> e = p[i] - p[i - 1]; R el = std::sqrt(dot(e, e));        // follow-the-leader length
            R L = (R)r1.w;
            if (el > R(1e-12)) p[i] = p[i - 1] + e * (L / el);
            else p[i] = p[i - 1] + v3<R>((R)r1.x - (R)r0.x, (R)r1.y - (R)r0.y, (R)r1.z - (R)r0.z);
        }
    }
    R res = R(0);
    for (int i = 1; i < Nn; ++i) {   // residual at nodes and segment midpoints
        V3<R> m = (p[i] + p[i - 1]) * R(0.5);
        V3<R> d1 = p[i] - closestOnSeg(p[i], C.a, C.b), d2 = m - closestOnSeg(m, C.a, C.b);
        R r1 = C.rad - std::sqrt(dot(d1, d1)), r2 = C.rad - std::sqrt(dot(d2, d2));
        res = std::max(res, std::max(r1, r2));
    }
    return res;
}

// guide broad-phase: bounding sphere vs capsule (local units)
template <typename R> inline bool guideNear(const F4& sph, const LocalCap<R>& C) {
    V3<R> c = v3<R>(sph.x, sph.y, sph.z); V3<R> q = closestOnSeg(c, C.a, C.b); V3<R> d = c - q;
    R lim = C.rad + (R)sph.w; return dot(d, d) < lim * lim;
}

// ---------------- timing helpers ----------------
struct Stats { double p50, p95, p99, mx, mean; };
inline Stats stats(std::vector<double> v) {
    std::sort(v.begin(), v.end()); Stats s{}; if (v.empty()) return s;
    auto q = [&](double f) { size_t i = (size_t)std::min<double>(v.size() - 1, std::floor(f * (v.size() - 1) + 0.5)); return v[i]; };
    s.p50 = q(0.5); s.p95 = q(0.95); s.p99 = q(0.99); s.mx = v.back();
    double sum = 0; for (double x : v) sum += x; s.mean = sum / v.size(); return s;
}
inline double nowMs() { using namespace std::chrono; return duration<double, std::milli>(steady_clock::now().time_since_epoch()).count(); }

// Output record for one active guide: id = k*G+g, then Nn float4 positions (w = residual on node 0)

// ---------------- synthetic skinned source mesh bound to guides ----------------
// Each vertex: bind = (g, s, t, 0) as floats-in-int; off = offset from the rest point on
// segment s (in rest frame); nrm = rest normal. Vertices sorted by guide.
struct MeshBind {
    int V = 0;
    std::vector<int> bindG, bindS; std::vector<float> bindT;
    std::vector<F4> off, nrm;
    std::vector<int> gStart; // G+1 prefix: vertices of guide g are [gStart[g], gStart[g+1])
    void build(const Workload& w, int Vtarget) {
        Pcg32 rng(w.seed ^ 0x9e3779b97f4a7c15ULL);
        int G = w.G, Nn = w.Nn; V = Vtarget;
        bindG.resize(V); bindS.resize(V); bindT.resize(V); off.resize(V); nrm.resize(V); gStart.assign(G + 1, 0);
        int per = V / G, extra = V % G, v = 0;
        for (int g = 0; g < G; ++g) {
            gStart[g] = v; int cnt = per + (g < extra ? 1 : 0);
            for (int j = 0; j < cnt; ++j, ++v) {
                float u = (cnt > 1) ? (float)j / (cnt - 1) : 0.f;             // along blade
                float pos = u * (Nn - 1); int s = std::min(Nn - 1, std::max(1, (int)std::floor(pos) + 1));
                float t = pos - (s - 1); t = std::min(1.f, std::max(0.f, t));
                float wdt = 0.004f * (1.f - u) * ((j & 1) ? 1.f : -1.f);       // blade half-width
                bindG[v] = g; bindS[v] = s; bindT[v] = t;
                off[v] = F4{wdt, 0.f, rng.range(-0.0005f, 0.0005f), 0.f};
                nrm[v] = F4{0.f, 0.f, 1.f, 0.f};
            }
        }
        gStart[G] = v;
    }
};

// Minimal-rotation deformation of one vertex (host reference; float).
inline void deformVertex(const F4* rest, int G, const float* posed /*Nn*3 or null*/, int g, int s, float t,
                         F4 off, F4 n0, float out[6]) {
    F4 r0 = rest[(size_t)(s - 1) * G + g], r1 = rest[(size_t)s * G + g];
    float a0x = r0.x, a0y = r0.y, a0z = r0.z, a1x = r1.x, a1y = r1.y, a1z = r1.z;
    float b0x = a0x, b0y = a0y, b0z = a0z, b1x = a1x, b1y = a1y, b1z = a1z;
    if (posed) { b0x = posed[(s - 1) * 3]; b0y = posed[(s - 1) * 3 + 1]; b0z = posed[(s - 1) * 3 + 2];
                 b1x = posed[s * 3]; b1y = posed[s * 3 + 1]; b1z = posed[s * 3 + 2]; }
    float dx = a1x - a0x, dy = a1y - a0y, dz = a1z - a0z, il = 1.f / std::sqrt(dx * dx + dy * dy + dz * dz);
    dx *= il; dy *= il; dz *= il;
    float ex = b1x - b0x, ey = b1y - b0y, ez = b1z - b0z, jl = 1.f / std::sqrt(ex * ex + ey * ey + ez * ez);
    ex *= jl; ey *= jl; ez *= jl;
    float c = dx * ex + dy * ey + dz * ez;
    float ax = dy * ez - dz * ey, ay = dz * ex - dx * ez, az = dx * ey - dy * ex;
    float k = 1.f / std::max(1.f + c, 1e-6f);
    auto rot = [&](float vx, float vy, float vz, float& ox, float& oy, float& oz) {
        float cx = ay * vz - az * vy, cy = az * vx - ax * vz, cz = ax * vy - ay * vx;
        float d = ax * vx + ay * vy + az * vz;
        ox = vx * c + cx + ax * d * k; oy = vy * c + cy + ay * d * k; oz = vz * c + cz + az * d * k; };
    float ox, oy, oz; rot(off.x, off.y, off.z, ox, oy, oz);
    out[0] = b0x + (b1x - b0x) * t + ox; out[1] = b0y + (b1y - b0y) * t + oy; out[2] = b0z + (b1z - b0z) * t + oz;
    rot(n0.x, n0.y, n0.z, out[3], out[4], out[5]);
}
