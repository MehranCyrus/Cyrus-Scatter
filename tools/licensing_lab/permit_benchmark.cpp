#include "signed_support.h"
#include <nlohmann/json.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <vector>
#include <algorithm>
using namespace cyrus::licensing;
int main(int argc,char** argv) {
    if(argc!=2)return 2;
    std::ifstream input(argv[1]);const auto data=nlohmann::json::parse(input);
    LicenseSession session(signedLabTrust(),signedLabHost());
    if(session.install(data["samples"]["active"].get<std::string>())!=TokenError::None)return 3;
    const auto claims=session.snapshot();
    const AuthorityFacts facts{Authority::Verified,ScatterAuthorRight,true,true,true,claims->not_before,claims->expires};
    constexpr int count=100000;int owner=0;std::uint64_t accepted=0;
    nlohmann::json result;
    for(int mode=0;mode<3;++mode) {
        std::vector<double> samples;
        for(int trial=0;trial<9;++trial) {
            auto start=std::chrono::steady_clock::now();
            for(int i=0;i<count;++i) {
                if(mode==0)accepted+=decide(Operation::AuthorScatter,facts,{true,1800000100}).allowed;
                else if(mode==1)accepted+=session.decide(Operation::AuthorScatter,{true,1800000100}).allowed;
                else {auto permit=session.admit(Operation::AuthorScatter,&owner,{true,1800000100},1000,30000);accepted+=session.consume(permit,Operation::AuthorScatter,&owner,1001);}
            }
            const auto nanos=std::chrono::duration<double,std::nano>(std::chrono::steady_clock::now()-start).count()/count;
            samples.push_back(nanos);
        }
        std::sort(samples.begin(),samples.end());
        result[mode==0?"pure_policy":mode==1?"verified_snapshot_decision":"admit_and_consume"]={{"median_ns",samples[4]},{"min_ns",samples.front()},{"max_ns",samples.back()}};
    }
    if(accepted!=std::uint64_t(count)*9*3)return 4;
    result["note"]="Native API microbenchmark only; excludes host clock acquisition and MAXScript. No network, disk or signature in loops. Not FPS.";
    std::cout<<result.dump(2)<<'\n';return 0;
}
