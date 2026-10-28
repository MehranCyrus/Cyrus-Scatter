#pragma once
#include <nlohmann/json.hpp>
#include <cmath>
#include <cstdint>
#include <vector>
#include <set>
#include <stdexcept>
#include <string>

namespace cyrus::recipeauthored {
using Json=nlohmann::json;
inline constexpr std::size_t maxBytes=8*1024*1024,maxRows=1000000;
inline void need(bool p,const char* why){if(!p)throw std::invalid_argument(why);}
inline void keys(const Json& j,std::initializer_list<const char*> names){need(j.is_object()&&j.size()==names.size(),"Invalid authored recipe fields");for(auto n:names)need(j.contains(n),"Missing authored recipe field");}
inline std::string text(const Json& j,std::size_t cap=256){need(j.is_string(),"Expected authored recipe text");auto s=j.get<std::string>();need(!s.empty()&&s.size()<=cap&&s.find('\0')==std::string::npos,"Invalid authored recipe text");return s;}
inline void validateEdits(const Json& j){
    keys(j,{"version","layers"});need(j["version"]==1&&j["layers"].is_array()&&j["layers"].size()<=1000,"Unsupported Edit recipe payload");std::set<std::string> owners;std::size_t count=0;
    for(const auto& l:j["layers"]){keys(l,{"owner","rows"});need(owners.insert(text(l["owner"])).second,"Duplicate Edit recipe owner");need(l["rows"].is_array(),"Invalid Edit recipe rows");count+=l["rows"].size();need(count<=maxRows,"Edit recipe exceeds 1M records");std::set<std::pair<std::string,std::string>> variants;
        for(const auto& r:l["rows"]){keys(r,{"input","output","source","revision","order","delta","deleted","local"});text(r["input"]);auto output=text(r["output"]),source=text(r["source"]);text(r["revision"],65536);need(variants.emplace(output,source).second,"Duplicate Edit recipe source variant");
            need(r["order"].is_number_integer()&&r["order"].get<std::int64_t>()>=0&&r["order"].get<std::int64_t>()<INT64_MAX,"Invalid Edit recipe ordering");need(r["deleted"].is_boolean()&&r["local"].is_boolean()&&r["delta"].is_array()&&r["delta"].size()==12,"Invalid Edit recipe transform");for(const auto& v:r["delta"])need(v.is_number()&&std::isfinite(v.get<double>())&&std::abs(v.get<double>())<=1e30,"Invalid Edit recipe number");
        }
    }
}
inline Json parseData(const std::string& s,int limit){need(s.size()<=maxBytes,"Authored recipe exceeds 8 MiB");std::vector<std::set<std::string>> names;auto j=Json::parse(s,[&](int d,Json::parse_event_t e,Json& v){need(d<=limit,"Authored recipe nesting limit");if(e==Json::parse_event_t::object_start)names.emplace_back();if(e==Json::parse_event_t::key)need(!names.empty()&&names.back().insert(v.get<std::string>()).second,"Duplicate authored recipe key");if(e==Json::parse_event_t::object_end)names.pop_back();return true;});return j;}
inline Json parseEdits(const std::string& s){auto j=parseData(s,16);validateEdits(j);return j;}
}
