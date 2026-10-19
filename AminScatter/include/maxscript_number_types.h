#pragma once
#include <maxscript/foundation/numbers.h>

// Max 2024 exposes macros; newer SDKs expose Number static methods.
namespace cyrus::host {
inline bool integerNumber(Value* value) {
#if CYRUS_MAX_YEAR == 2024
    return is_integer_number(value);
#else
    return Number::is_integer_number(value);
#endif
}
inline bool floatNumber(Value* value) {
#if CYRUS_MAX_YEAR == 2024
    return is_float_number(value);
#else
    return Number::is_float_number(value);
#endif
}
}
