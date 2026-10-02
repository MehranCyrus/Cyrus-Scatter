// Proxy-only world-space display data. The placement/source cache remains the
// authority; oversized previews and Mesh mode retain the instanced CPU path.
namespace {
constexpr std::size_t proxyCacheByteLimit = 16u * 1024u * 1024u;
constexpr std::size_t proxyProcessByteLimit = 64u * 1024u * 1024u;
constexpr std::size_t proxyBatchFaceLimit = 4096;
std::atomic<std::size_t> proxyReservedBytes{0};
bool proxyBatchDrawing = true; // Session-only diagnostic switch; never serialized.

struct ProxyBatchReservation {
    std::size_t bytes = 0;
    ProxyBatchReservation() = default;
    ProxyBatchReservation(const ProxyBatchReservation&) = delete;
    ProxyBatchReservation& operator=(const ProxyBatchReservation&) = delete;
    ~ProxyBatchReservation() { release(); }
    void release() {
        if (bytes) proxyReservedBytes.fetch_sub(bytes, std::memory_order_relaxed);
        bytes = 0;
    }
    bool acquire(std::size_t wanted) {
        if (!wanted || wanted > proxyCacheByteLimit) return false;
        auto used = proxyReservedBytes.load(std::memory_order_relaxed);
        do {
            if (wanted > proxyProcessByteLimit - used) return false;
        } while (!proxyReservedBytes.compare_exchange_weak(used, used + wanted, std::memory_order_relaxed));
        bytes = wanted;
        return true;
    }
};

struct ProxyTriangle {
    std::array<Point3, 3> vertices;
    float shade;
};
struct ProxyBatch {
    std::size_t first, count;
    Point3 color;
};

float proxyFaceShade(const std::array<Point3, 3>& face, const Matrix3& tm) {
    // Preserve the old cross-product semantics for nonuniform/mirrored scales.
    const auto a = VectorTransform(tm, face[1] - face[0]);
    const auto b = VectorTransform(tm, face[2] - face[0]);
    const auto normal = Normalize(CrossProd(a, b));
    return .35f + .65f * std::abs(DotProd(normal, Normalize(Point3(.3f, -.5f, .8f))));
}
}
