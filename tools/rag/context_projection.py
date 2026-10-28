"""Model-facing views over verified evidence; never truncate source or qualifiers."""
import copy
import json


def compact(value, selection):
    result = copy.deepcopy(value)
    identities = result.pop('configuration_identities', None)
    if identities:
        result['provenance'] = {
            'root': identities['root'],
            'generation': value['index_generation'],
            'corpus_path': identities['corpus_path'],
            'corpus_sha256': identities['corpus_sha256'],
            'build_receipt': identities['build_receipt'],
            'detail_command': 'Repeat this command with --detail full for complete provenance.',
        }
    for row in result.get('results', []):
        # These are indexing/display duplicates, not evidence or applicability.
        for key in ('search_text', 'excerpt', 'excerpt_truncated'):
            row.pop(key, None)
    # A status already reports each issue and a count. The full inventory is
    # available explicitly; it adds no citation or issue detail to this view.
    if 'corpus_scope' in result:
        result['corpus_scope'].pop('paths', None)
    result['context_selection'] = selection
    result['context_view'] = 'compact'
    return result


def render(value, selection, detail='compact', max_chars=24000):
    result = compact(value, selection) if detail == 'compact' else {
        **copy.deepcopy(value), 'context_selection': selection, 'context_view': 'full'}
    encoded = json.dumps(result, ensure_ascii=False, separators=(',', ':'))
    if len(encoded) <= max_chars:
        return result
    # Do not convert partial evidence into an apparently successful answer.
    return {'schema': 'cyrus.context-budget/1', 'ok': False,
            'error_type': 'context_budget_exceeded', 'required_chars': len(encoded),
            'max_chars': max_chars, 'results': [],
            'index_generation': value.get('index_generation'),
            'underlying_error_type': value.get('error_type'),
            'action': 'Use a narrower query or lower --top-k, or explicitly raise --max-chars. No evidence was clipped.',
            'context_selection': selection}
