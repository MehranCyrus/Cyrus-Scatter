from types import SimpleNamespace as Obj
import pytest
from cyrus_mcp.procedural import read_vector_paint
from cyrus_mcp.contracts import Fault


def test_vector_inspection_uses_area_revisions_and_preserves_missing_targets():
    document=object();calls=[]
    def stats(value):
        calls.append(value)
        return [17,2,128,1]
    area=Obj(layerID='a',paintSetName='Bed',areaTarget='plane',paintSetEnabled=True,
             paintDensity=.8,paintDocument=document)
    missing=Obj(layerID='b',paintSetName='Missing',areaTarget=None,paintSetEnabled=False,
                paintDensity=1,paintDocument=None)
    layer=Obj(paintAreas=[area,missing],paintEnabled=True)
    result=read_vector_paint(layer,stats,lambda node:node)
    assert result['representation']=='vector_regions'
    assert result['areas'][0]['revision']==17
    assert result['areas'][0]['contour_count']==2
    assert result['areas'][0]['vertex_count']==128
    assert result['areas'][1]['receiver'] is None
    assert result['areas'][1]['document_present'] is False
    assert calls==[document]
    # No field, mesh, generation or mutation API is present on these fixtures.


def test_vector_inspection_rejects_unbounded_areas_before_any_native_read():
    with pytest.raises(Fault):
        read_vector_paint(Obj(paintAreas=[None]*129),lambda _:pytest.fail('eager read'),lambda n:n)
