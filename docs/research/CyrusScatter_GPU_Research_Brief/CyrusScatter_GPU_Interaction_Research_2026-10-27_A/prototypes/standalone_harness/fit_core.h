/* fit_core.h - SYNTHETIC guide-fit and deformation core.
 * Written in a C99 subset so the SAME SOURCE compiles as:
 *   - host C++   (DEV empty, GLOBAL empty, F4 = float4-like struct)
 *   - CUDA       (DEV __device__ __forceinline__, GLOBAL empty, F4 = float4)
 *   - OpenCL C   (DEV inline, GLOBAL __global, F4 = float4)
 * Required macros before inclusion: DEV, GLOBAL, REAL, F4, SQRT, COS, SIN.
 * No include guard on purpose: CUDA includes it twice in namespaces (float/double).
 * This is NOT the Cyrus Scatter production fitter; see README in prototypes/.
 */
#ifndef FC_MAXN
#define FC_MAXN 16
#endif

typedef struct { REAL x, y, z; } r3;
typedef struct { r3 a, b; REAL rad; } lcap;   /* capsule in plant-local units; rad = radius + contact gap */

DEV r3 R3(REAL x, REAL y, REAL z) { r3 v; v.x = x; v.y = y; v.z = z; return v; }
DEV r3 add3(r3 a, r3 b) { return R3(a.x + b.x, a.y + b.y, a.z + b.z); }
DEV r3 sub3(r3 a, r3 b) { return R3(a.x - b.x, a.y - b.y, a.z - b.z); }
DEV r3 mul3(r3 a, REAL s) { return R3(a.x * s, a.y * s, a.z * s); }
DEV REAL dot3(r3 a, r3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
DEV r3 cross3(r3 a, r3 b) { return R3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x); }
DEV r3 node3(F4 q) { return R3((REAL)q.x, (REAL)q.y, (REAL)q.z); }

DEV r3 closestOnSeg(r3 p, r3 a, r3 b) {
    r3 ab = sub3(b, a); REAL den = dot3(ab, ab);
    REAL t = den > (REAL)0 ? dot3(sub3(p, a), ab) / den : (REAL)0;
    t = t < (REAL)0 ? (REAL)0 : (t > (REAL)1 ? (REAL)1 : t);
    return add3(a, mul3(ab, t));
}

/* inst = (tx, tz, yaw, uniformScale>0); A = (ax,ay,az, radius); B = (bx,by,bz, contactGap) world metres */
DEV lcap toLocal(F4 inst, F4 A, F4 B) {
    REAL c = COS((REAL)inst.z), s = SIN((REAL)inst.z), invS = (REAL)1 / (REAL)inst.w;
    lcap L;
    REAL dx = (REAL)A.x - (REAL)inst.x, dz = (REAL)A.z - (REAL)inst.y;
    L.a = R3((c * dx + s * dz) * invS, (REAL)A.y * invS, (-s * dx + c * dz) * invS);
    dx = (REAL)B.x - (REAL)inst.x; dz = (REAL)B.z - (REAL)inst.y;
    L.b = R3((c * dx + s * dz) * invS, (REAL)B.y * invS, (-s * dx + c * dz) * invS);
    L.rad = ((REAL)A.w + (REAL)B.w) * invS;   /* contact gap applied exactly once */
    return L;
}

DEV int guideNear(F4 sph, lcap C) {
    r3 c = node3(sph); r3 d = sub3(c, closestOnSeg(c, C.a, C.b));
    REAL lim = C.rad + (REAL)sph.w;
    return dot3(d, d) < lim * lim;
}

/* rest is node-major: rest[i*G+g] = (x,y,z, restLength of segment i-1..i). Returns residual penetration. */
DEV REAL fitGuide(GLOBAL const F4* rest, int G, int Nn, int g, lcap C, int iters, REAL kBend, r3* p) {
    int i, it;
    for (i = 0; i < Nn; ++i) p[i] = node3(rest[i * G + g]);
    for (it = 0; it < iters; ++it) {
        for (i = 1; i < Nn; ++i) {
            F4 q0 = rest[(i - 1) * G + g], q1 = rest[i * G + g];
            r3 rd = sub3(node3(q1), node3(q0));
            r3 target = add3(p[i - 1], rd);
            p[i] = add3(p[i], mul3(sub3(target, p[i]), kBend));          /* bending surrogate */
            {
                r3 c = closestOnSeg(p[i], C.a, C.b); r3 d = sub3(p[i], c);
                REAL dist = SQRT(dot3(d, d));
                if (dist < C.rad) {                                        /* contact projection */
                    r3 n = dist > (REAL)1e-12 ? mul3(d, (REAL)1 / dist) : R3((REAL)0, (REAL)1, (REAL)0);
                    p[i] = add3(c, mul3(n, C.rad));
                }
            }
            {
                r3 e = sub3(p[i], p[i - 1]); REAL el = SQRT(dot3(e, e)); REAL L = (REAL)q1.w;
                p[i] = el > (REAL)1e-12 ? add3(p[i - 1], mul3(e, L / el)) : add3(p[i - 1], rd); /* FTL length */
            }
        }
    }
    {
        REAL res = (REAL)0;
        for (i = 1; i < Nn; ++i) {
            r3 m = mul3(add3(p[i], p[i - 1]), (REAL)0.5);
            r3 d1 = sub3(p[i], closestOnSeg(p[i], C.a, C.b));
            r3 d2 = sub3(m, closestOnSeg(m, C.a, C.b));
            REAL e1 = C.rad - SQRT(dot3(d1, d1)), e2 = C.rad - SQRT(dot3(d2, d2));
            res = res > e1 ? res : e1; res = res > e2 ? res : e2;
        }
        return res;
    }
}

/* Minimal-rotation deformation: a0,a1 rest segment, b0,b1 posed segment (float only). */
DEV void deformVtx(r3 a0, r3 a1, r3 b0, r3 b1, REAL t, F4 off, F4 n0, r3* pos, r3* nrm) {
    r3 d = sub3(a1, a0); d = mul3(d, (REAL)1 / SQRT(dot3(d, d)));
    r3 e = sub3(b1, b0); e = mul3(e, (REAL)1 / SQRT(dot3(e, e)));
    REAL c = dot3(d, e); r3 ax = cross3(d, e);
    REAL k = (REAL)1 / ((REAL)1 + c > (REAL)1e-6 ? (REAL)1 + c : (REAL)1e-6);
    r3 v = node3(off);
    r3 o = add3(add3(mul3(v, c), cross3(ax, v)), mul3(ax, dot3(ax, v) * k));
    *pos = add3(add3(b0, mul3(sub3(b1, b0), t)), o);
    v = node3(n0);
    *nrm = add3(add3(mul3(v, c), cross3(ax, v)), mul3(ax, dot3(ax, v) * k));
}

/* pack unit normal into 10:10:10 snorm-ish unsigned */
DEV unsigned packN(r3 n) {
    REAL fx = n.x < (REAL)-1 ? (REAL)-1 : (n.x > (REAL)1 ? (REAL)1 : n.x);
    REAL fy = n.y < (REAL)-1 ? (REAL)-1 : (n.y > (REAL)1 ? (REAL)1 : n.y);
    REAL fz = n.z < (REAL)-1 ? (REAL)-1 : (n.z > (REAL)1 ? (REAL)1 : n.z);
    unsigned x = (unsigned)((fx * (REAL)0.5 + (REAL)0.5) * (REAL)1023 + (REAL)0.5);
    unsigned y = (unsigned)((fy * (REAL)0.5 + (REAL)0.5) * (REAL)1023 + (REAL)0.5);
    unsigned z = (unsigned)((fz * (REAL)0.5 + (REAL)0.5) * (REAL)1023 + (REAL)0.5);
    return x | (y << 10) | (z << 20);
}
