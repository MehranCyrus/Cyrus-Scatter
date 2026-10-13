#pragma once
class Value;
namespace cyrus::bands { class Field; }
// Host-thread adapter only; the returned immutable field remains owned by the
// GC argument throughout the native primitive call.
const cyrus::bands::Field& cyrusPreparedSplineField(Value*);
