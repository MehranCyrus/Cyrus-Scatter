import importlib.util
import json
from pathlib import Path
import sys
import pytest

MODULE=Path(__file__).resolve().parents[1]/'quality_validation/results.py'
spec=importlib.util.spec_from_file_location('quality_results',MODULE)
results=importlib.util.module_from_spec(spec);sys.modules[spec.name]=results;spec.loader.exec_module(results)


@pytest.fixture
def expected():
    return results.Expected('run','request','scenario','artifact',('a','b'))


def complete(expected):
    return {'schema':'cyrus.max-scenario/1',**{k:getattr(expected,k) for k in ('run_id','request_id','scenario_id','artifact_id')},
            'terminal':'complete','status':'pass','assertions':[{'id':i,'status':'pass'} for i in expected.assertions]}


@pytest.mark.parametrize('mutation',['run_id','request_id','scenario_id','artifact_id','terminal','status','missing','duplicate','empty','failed','truncated','early'])
def test_incomplete_never_passes(tmp_path,expected,mutation):
    value=complete(expected);path=tmp_path/'result.json'
    if mutation in value:value[mutation]='different'
    elif mutation=='missing':value['assertions'].pop()
    elif mutation=='duplicate':value['assertions'].append(value['assertions'][0])
    elif mutation=='empty':value['assertions']=[]
    elif mutation=='failed':value['assertions'][0]['status']='fail'
    elif mutation=='early':value.pop('terminal')
    path.write_text('{"schema":' if mutation=='truncated' else json.dumps(value),encoding='utf-8')
    with pytest.raises(results.IncompleteResult):results.read_result(path,expected)


def test_missing_result(tmp_path,expected):
    with pytest.raises(results.IncompleteResult):results.read_result(tmp_path/'absent',expected)


def test_complete_current_request(tmp_path,expected):
    path=tmp_path/'result.json';path.write_text(json.dumps(complete(expected)),encoding='utf-8')
    assert results.read_result(path,expected)['status']=='pass'


@pytest.mark.parametrize('first,last',[('fail','pass'),('pass','fail'),('pass','pass')])
@pytest.mark.parametrize('nested',[False,True])
def test_duplicate_status_keys_never_pass(tmp_path,expected,first,last,nested):
    text=json.dumps(complete(expected))
    needle='"status": "pass"'
    replacement='"status": '+json.dumps(first)+', "status": '+json.dumps(last)
    position=text.rfind(needle) if nested else text.find(needle)
    text=text[:position]+text[position:].replace(needle,replacement,1)
    path=tmp_path/'ambiguous.json';path.write_text(text,encoding='utf-8')
    with pytest.raises(results.IncompleteResult):results.read_result(path,expected)


@pytest.mark.parametrize('key',['run_id','request_id','scenario_id','artifact_id','terminal'])
def test_duplicate_identity_or_terminal_keys_never_pass(tmp_path,expected,key):
    value=complete(expected);text=json.dumps(value)
    pair=json.dumps(key)+': '+json.dumps(value[key])
    text=text.replace(pair,pair+', '+pair,1)
    path=tmp_path/'ambiguous.json';path.write_text(text,encoding='utf-8')
    with pytest.raises(results.IncompleteResult):results.read_result(path,expected)


def test_escaped_equivalent_key_is_duplicate(tmp_path,expected):
    text=json.dumps(complete(expected)).replace('"status": "pass"','"status": "fail", "sta\\u0074us": "pass"',1)
    path=tmp_path/'escaped.json';path.write_text(text,encoding='utf-8')
    with pytest.raises(results.IncompleteResult):results.read_result(path,expected)
