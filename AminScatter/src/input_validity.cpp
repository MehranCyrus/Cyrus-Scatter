#include <max.h>
#include <iparamb2.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <unordered_set>

namespace {
// Max's node/PRS cache can report [t,t] for an ordinary unanimated transform.
// Recognize only the stock keyed controllers/composites. Script, expression,
// constraint, list, and third-party controllers keep their SDK validity even
// when IsAnimated() says false; absence of keys alone does not prove constancy.
bool constantController(Control* control) {
    if (!control) return true;
    if (control->IsAnimated()) return false;
    const auto id = control->ClassID();
    if (control->SuperClassID() == CTRL_MATRIX3_CLASS_ID && id == Class_ID(PRS_CONTROL_CLASS_ID, 0))
        return constantController(control->GetPositionController()) &&
               constantController(control->GetRotationController()) &&
               constantController(control->GetScaleController());
    // Stock Position XYZ and Euler XYZ scene class IDs, also checked by the
    // disposable Max 2027 probe. These IDs are scoped by controller superclass.
    if ((control->SuperClassID() == CTRL_POSITION_CLASS_ID && id == Class_ID(0x118f7e02, 0xffee238a)) ||
        (control->SuperClassID() == CTRL_ROTATION_CLASS_ID && id == Class_ID(0x2012, 0)))
        return constantController(control->GetXController()) &&
               constantController(control->GetYController()) &&
               constantController(control->GetZController());
    if (id.PartB() != 0) return false;
    const auto super = control->SuperClassID();
    switch (id.PartA()) {
        case LININTERP_FLOAT_CLASS_ID: case HYBRIDINTERP_FLOAT_CLASS_ID:
        case TCBINTERP_FLOAT_CLASS_ID: return super == CTRL_FLOAT_CLASS_ID && control->NumKeys() <= 1;
        case LININTERP_POSITION_CLASS_ID: case HYBRIDINTERP_POSITION_CLASS_ID:
        case TCBINTERP_POSITION_CLASS_ID: return super == CTRL_POSITION_CLASS_ID && control->NumKeys() <= 1;
        case LININTERP_ROTATION_CLASS_ID: case HYBRIDINTERP_ROTATION_CLASS_ID:
        case TCBINTERP_ROTATION_CLASS_ID: return super == CTRL_ROTATION_CLASS_ID && control->NumKeys() <= 1;
        case LININTERP_SCALE_CLASS_ID: case HYBRIDINTERP_SCALE_CLASS_ID:
        case TCBINTERP_SCALE_CLASS_ID: return super == CTRL_SCALE_CLASS_ID && control->NumKeys() <= 1;
        case HYBRIDINTERP_POINT3_CLASS_ID: case HYBRIDINTERP_COLOR_CLASS_ID:
        case TCBINTERP_POINT3_CLASS_ID: return super == CTRL_POINT3_CLASS_ID && control->NumKeys() <= 1;
        default: return false;
    }
}

void controllerValidity(Control* control, TimeValue t, Interval& valid) {
    if (!control || constantController(control)) return;
    // Keep each returned interval separate before intersecting dependencies.
    // A controller must never broaden another controller's cached validity.
    Interval local = FOREVER;
    switch (control->SuperClassID()) {
        case CTRL_FLOAT_CLASS_ID: { float value = 0; control->GetValue(t, &value, local); break; }
        case CTRL_POINT2_CLASS_ID: { Point2 value(0, 0); control->GetValue(t, &value, local); break; }
        case CTRL_POINT3_CLASS_ID: case CTRL_POSITION_CLASS_ID: {
            Point3 value(0, 0, 0); control->GetValue(t, &value, local); break;
        }
        case CTRL_POINT4_CLASS_ID: case CTRL_FRGBA_CLASS_ID: {
            Point4 value(0, 0, 0, 0); control->GetValue(t, &value, local); break;
        }
        case CTRL_ROTATION_CLASS_ID: { Quat value(0.0f, 0.0f, 0.0f, 1.0f); control->GetValue(t, &value, local); break; }
        case CTRL_SCALE_CLASS_ID: { ScaleValue value; control->GetValue(t, &value, local); break; }
        case CTRL_MATRIX3_CLASS_ID: {
            Matrix3 value(1); control->GetValue(t, &value, local, CTRL_RELATIVE); break;
        }
        default: local.Set(t, t); break;
    }
    valid &= local;
}

void settingsValidity(ReferenceTarget* owner, TimeValue t, Interval& valid) {
    for (int b = 0; b < owner->NumParamBlocks(); ++b) {
        auto* block = owner->GetParamBlock(b);
        if (!block) continue;
        // Node references are handled explicitly below. GetValidity() for the
        // whole block would import the node/PRS one-frame cache intervals.
        for (int p = 0; p < block->NumParams(); ++p) {
            const auto id = block->IndextoID(p);
            const int entries = is_tab(block->GetParameterType(id)) ? block->Count(id) : 1;
            for (int i = 0; i < entries; ++i)
                controllerValidity(block->GetControllerByIndex(p, i), t, valid);
        }
    }
}
}

// Called on the Max thread when an input changes or its cached interval expires.
// Never copies meshes, generates placements, or keeps scene references in C++.
// The script owns the interval and discards it on actual input notifications.
#ifdef CYRUS_ANALYZER_INPUT_VALIDITY
def_visible_primitive(cyrusAnalyzerInputValidity, "cyrusAnalyzerInputValidity");
Value* cyrusAnalyzerInputValidity_cf(Value** args, int count) {
    check_arg_count(cyrusAnalyzerInputValidity, 3, count);
#else
def_visible_primitive(cyrusScatterInputValidity, "cyrusScatterInputValidity");
Value* cyrusScatterInputValidity_cf(Value** args, int count) {
    check_arg_count(cyrusScatterInputValidity, 3, count);
#endif
    for (int i = 0; i < 3; ++i) type_check(args[i], Array, _T("input validity dependencies"));
    auto* settings = static_cast<Array*>(args[0]);
    auto* nodes = static_cast<Array*>(args[1]);
    auto* maps = static_cast<Array*>(args[2]);
    const TimeValue t = MAXScript_time();
    Interval valid = FOREVER;
    for (int i = 0; i < settings->size; ++i) {
        auto* owner = settings->data[i]->to_reftarg();
        if (!owner) throw RuntimeError(_T("Missing Cyrus settings dependency"));
        settingsValidity(owner, t, valid);
    }
    for (int i = 0; i < nodes->size; ++i) {
        auto* node = nodes->data[i]->to_node();
        if (!node) throw RuntimeError(_T("Missing Cyrus node dependency"));
        const auto& state = node->EvalWorldState(t);
        valid &= state.Validity(t);
        // ObjectState covers geometry and world-space modifiers. Check each
        // ancestor's actual transform controller; ignore the scene root cache.
        auto* root = GetCOREInterface()->GetRootNode();
        bool constant = true;
        std::unordered_set<INode*> ancestors;
        for (auto* ancestor = node; ancestor && ancestor != root; ancestor = ancestor->GetParentNode()) {
            if (!ancestors.insert(ancestor).second || ancestors.size() > 4096)
                throw RuntimeError(_T("Cyrus input parent chain exceeds the validity limit"));
            if (!constantController(ancestor->GetTMController())) constant = false;
        }
        if (!constant) {
            Interval transform = FOREVER;
            node->GetObjectTM(t, &transform);
            valid &= transform;
        }
    }
    for (int i = 0; i < maps->size; ++i) {
        auto* map = maps->data[i]->to_texmap();
        if (!map) throw RuntimeError(_T("Missing Cyrus texture dependency"));
        valid &= map->Validity(t);
    }
    // NEVER or an invalid third-party interval must not silently freeze animation.
    if (!valid.InInterval(t)) valid.Set(t, t);
    one_typed_value_local(Array* result);
    vl.result = new Array(3);
    vl.result->append(Integer::intern(valid.Start()));
    vl.result->append(Integer::intern(valid.End()));
    vl.result->append(valid == FOREVER ? &true_value : &false_value);
    return_value(vl.result);
}
