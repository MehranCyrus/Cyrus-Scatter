// Isolated diagnosis: identical hard coverage with increasing authored history.
// No Forest timing, polygon implementation, host, drawing or speedup comparison.
#include "brush.h"
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
using namespace cyrus::brush;
using Clock = std::chrono::steady_clock;
double ms(Clock::time_point t) { return std::chrono::duration<double, std::milli>(Clock::now()-t).count(); }
Anchor at(const Surface& s, double x, double y) {
    Hit h;
    if (!s.hit({{x,y,100},{0,0,-1}},h)) throw std::runtime_error("Missing hit");
    return h.anchor;
}
int main() {
    Surface surface({{{-100,-100,0},{100,-100,0},{100,100,0},{-100,100,0}},{{{0,1,2}},{{0,2,3}}}});
    std::vector<Anchor> anchors;
    std::vector<double> expected;
    for (unsigned y=0;y<100;++y) for (unsigned x=0;x<100;++x) {
        const double px=-99+2.*x, py=-99+2.*y;
        anchors.push_back(at(surface,px,py));
        expected.push_back(px*px+py*py<400 ? 1. : 0.);
    }
    Stroke stroke; stroke.id=1; stroke.radius=20; stroke.strength=1; stroke.softness=0;
    Sample sample; sample.anchor=at(surface,0,0); sample.view={{0,0,100},{0,0,-1},false};
    stroke.samples={sample};
    std::cout << "repeat,strokes,queries,build_ms,query_ms,bytes,accepted,max_error\n" << std::setprecision(10);
    for (unsigned repeat=0;repeat<4;++repeat) for (unsigned count:{1u,10u,100u,1000u}) {
        Document document{surface.fingerprint(),{}};
        for (unsigned i=0;i<count;++i) { stroke.id=i+1; document.strokes.push_back(stroke); }
        auto start=Clock::now(); Field field(surface,document); double build=ms(start);
        start=Clock::now(); double error=0; unsigned accepted=0;
        for (std::size_t i=0;i<anchors.size();++i) {
            double w=field.evaluate(anchors[i]);
            error=std::max(error,std::abs(w-expected[i])); accepted+=w>0;
        }
        double query=ms(start);
        if (error>1e-9) throw std::runtime_error("Coverage differs from analytic hard disk");
        std::cout << repeat << ',' << count << ',' << anchors.size() << ',' << build << ',' << query << ','
                  << encode(document).size() << ',' << accepted << ',' << error << '\n';
    }
}
