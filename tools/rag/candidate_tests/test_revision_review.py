"""Reviewed scope/runtime revisions remain distinct from automatic refresh."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import candidate_support as s


class RevisionReviewTests(unittest.TestCase):
    def setUp(self):
        self.source={'path':'docs/a.md','sha256':'a'*64,'knowledge_status':'current','ranges':[[1,3]]}
        self.baseline={'sources':[self.source]}
        self.new={**self.source,'path':'docs/foundation.md','sha256':'b'*64}
        self.candidate={'schema':'cyrus.corpus/1','sources':[self.source,self.new]}
        self.review={'enrollment':{'added':[self.new['path']],'reason':'Reviewed foundation and its qualification limits','agent_reviewed':True},
            'sources':[{'path':self.new['path'],'old_sha256':None,'new_sha256':self.new['sha256'],
                'field_reasons':{k:'Inspected full parent, evidence and applicability' for k in self.new},
                **{k:True for k in ('diff_inspected','ranges_checked','context_checked','applicability_checked',
                    'authority_checked','generated_ownership_checked','canonical_checked')}}]}

    def test_explicit_addition_retains_prior_sources(self):
        result=s.review_definition(self.baseline,self.candidate,self.review)
        self.assertEqual([(r['path'],r['enrolled']) for r in result],[('docs/foundation.md',True)])

    def test_unreviewed_addition_or_missing_qualifier_denied(self):
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,self.candidate,None)
        self.review['sources'][0]['context_checked']=False
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,self.candidate,self.review)

    def test_removal_and_case_alias_denied_even_with_review(self):
        for sources in ([self.new],[self.source,{**self.new,'path':'DOCS/A.MD'}]):
            with self.subTest(sources=sources),self.assertRaises(s.Blocked):
                s.review_definition(self.baseline,{**self.candidate,'sources':sources},self.review)

    def test_historical_promotion_still_denied(self):
        old={**self.source,'knowledge_status':'historical'}
        new={**self.source,'sha256':'c'*64}
        review=copy.deepcopy(self.review)
        entry=review['sources'][0]
        entry.update(path=old['path'],old_sha256=old['sha256'],new_sha256=new['sha256'],
                     field_reasons={'sha256':'Reviewed successor','knowledge_status':'Proposed promotion'})
        with self.assertRaises(s.Blocked) as result:
            s.review_definition({'sources':[old]},{'schema':'cyrus.corpus/1','sources':[new]},review)
        self.assertEqual(result.exception.issue,'authority_promotion')

    def test_retirement_requires_exact_review_and_preserves_history(self):
        candidate={'schema':'cyrus.corpus/1','sources':[]}
        entry={'path':self.source['path'],'old_sha256':self.source['sha256'],
               'reason':'Retired migration fixture', 'historical_evidence':'sealed baseline corpus',
               'replacement_or_omission':'Omitted, no supported current equivalent',
               'agent_reviewed':True,'references_checked':True,'evaluation_requirements_checked':True}
        result=s.review_definition(self.baseline,candidate,{'retirements':[entry]})
        self.assertTrue(result[0]['retired'])
        self.assertEqual(self.baseline['sources'],[self.source])
        for changes in ([], [entry,entry], [{**entry,'old_sha256':'b'*64}],
                        [{**entry,'evaluation_requirements_checked':False}], [{**entry,'historical_evidence':''}]):
            with self.subTest(changes=changes),self.assertRaises(s.Blocked):
                s.review_definition(self.baseline,candidate,{'retirements':changes})
        with self.assertRaises(s.Blocked):
            s.review_definition(self.baseline,{'schema':'cyrus.corpus/1','sources':[self.source]}, {'retirements':[entry]})

    def test_atomic_section_review_does_not_allow_range_shrink(self):
        candidate={'schema':'cyrus.corpus/1','sources':[{**self.source,'contract_sections':[[1,3]]}]}
        entry={**self.review['sources'][0], 'path':self.source['path'], 'old_sha256':self.source['sha256'],
               'new_sha256':self.source['sha256'], 'field_reasons':{'contract_sections':'Preserve complete rule and limits'},
               'unchanged_metadata_reviewed':True}
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,candidate,{'sources':[entry]})
        entry['contract_sections_reviewed']=True
        self.assertEqual(len(s.review_definition(self.baseline,candidate,{'sources':[entry]})),1)
        candidate['sources'][0]['ranges']=[[1,2]]
        entry['field_reasons']['ranges']='Attempt to drop limits'
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,candidate,{'sources':[entry]})

    def test_runtime_review_binds_both_identities(self):
        runtime={'adapter.py':'a'*64}
        change={'name':'adapter.py','old_sha256':'a'*64,'new_sha256':'b'*64,
                'reason':'Reviewed selection and transport tests','diff_inspected':True,'tests_reviewed':True}
        self.assertEqual(s.review_runtime(runtime,{'runtime':[change]}),{'adapter.py':'b'*64})
        self.assertEqual(runtime,{'adapter.py':'a'*64})
        for bad in ({'old_sha256':'c'*64},{'name':'unknown.py'},{'new_sha256':'invalid'},{'tests_reviewed':False}):
            with self.subTest(bad=bad),self.assertRaises(s.Blocked):
                s.review_runtime(runtime,{'runtime':[{**change,**bad}]})
        with self.assertRaises(s.Blocked):s.review_runtime(runtime,{'runtime':[change,change]})

    def test_unchanged_parent_metadata_requires_explicit_review(self):
        candidate={'schema':'cyrus.corpus/1','sources':[{**self.source,'review_status':'Inspected successor provenance'}]}
        entry={**self.review['sources'][0],'path':self.source['path'],'old_sha256':self.source['sha256'],
               'new_sha256':self.source['sha256'],'field_reasons':{'review_status':'New provenance review'}}
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,candidate,{'sources':[entry]})
        entry['unchanged_metadata_reviewed']=True
        self.assertEqual(len(s.review_definition(self.baseline,candidate,{'sources':[entry]})),1)
        candidate['sources'][0]['ranges']=[[1,2]]
        entry['field_reasons']['ranges']='A reason cannot bypass the unchanged-range boundary'
        with self.assertRaises(s.Blocked):s.review_definition(self.baseline,candidate,{'sources':[entry]})

    def test_conclusion_review_does_not_allow_question_or_evidence_changes(self):
        before={'queries':[{'id':'O08','query':'fingerprint','required_evidence':['same-symbol'],
                           'reference_conclusion':'The prior exact fingerprint'}],'anchors':[]}
        after=copy.deepcopy(before);after['queries'][0]['reference_conclusion']='The current exact fingerprint'
        note={'group':'base','id':'O08','old_value':'The prior exact fingerprint','new_value':'The current exact fingerprint',
              'reason':'Inspected generated symbol changed with the current artifact','agent_reviewed':True}
        results={'questions':[],'metrics':{},'evaluation_sha256':'fixture'}
        with self.assertRaises(s.Blocked):s.compare_baseline(results,results,before,after,True)
        actual=s.compare_baseline(results,results,before,after,True,[note])
        self.assertTrue(actual['passed']);self.assertEqual(actual['reviewed_reference_conclusion_changes'],[note])
        altered=copy.deepcopy(after);altered['queries'][0]['query']='Easier substitute'
        with self.assertRaises(s.Blocked):s.compare_baseline(results,results,before,altered,True,[note])
        altered=copy.deepcopy(after);altered['queries'][0]['required_evidence']=[]
        with self.assertRaises(s.Blocked):s.compare_baseline(results,results,before,altered,True,[note])
        with self.assertRaises(s.Blocked):s.compare_baseline(results,results,before,after,True,[{**note,'old_value':'wrong'}])

    def test_equivalent_owner_addition_is_explicit_and_cannot_drop_requirements(self):
        unit={'id':'rule','canonical_paths':['guide.md'],'alternatives':[{'path':'guide.md','sha256':'a'*64,'start_line':1,'end_line':1}]}
        before={'queries':[{'id':'q','query':'same question','required_evidence':[unit]}],'anchors':[]}
        after=copy.deepcopy(before)
        after['queries'][0]['required_evidence'][0]['alternatives'].append({'path':'foundation.md','sha256':'b'*64,'start_line':1,'end_line':12})
        after['queries'][0]['required_evidence'][0]['canonical_paths'].append('foundation.md')
        note={'group':'base','id':'q','old_value':before['queries'][0]['required_evidence'],
              'new_value':after['queries'][0]['required_evidence'],'agent_reviewed':True,
              'reason':'A maintained contract now states the same requirement','equivalence_evidence':'Full rule, conditions and limits inspected'}
        result={'questions':[],'metrics':{},'evaluation_sha256':'fixture'}
        with self.assertRaises(s.Blocked):s.compare_baseline(result,result,before,after,True)
        self.assertTrue(s.compare_baseline(result,result,before,after,True,evidence_review=[note])['passed'])
        for mutation in ('drop_unit','drop_owner','change_id'):
            bad=copy.deepcopy(after)
            if mutation=='drop_unit':bad['queries'][0]['required_evidence']=[]
            elif mutation=='drop_owner':bad['queries'][0]['required_evidence'][0]['alternatives'].pop(0)
            else:bad['queries'][0]['required_evidence'][0]['id']='easier'
            with self.subTest(mutation=mutation),self.assertRaises(s.Blocked):
                s.compare_baseline(result,result,before,bad,True,evidence_review=[{**note,'new_value':bad['queries'][0]['required_evidence']}])
        with self.assertRaises(s.Blocked):s.compare_baseline(result,result,before,after,False,evidence_review=[note])


class ManualTradeoffTests(unittest.TestCase):
    def setUp(self):
        scores={'at_k':{str(k):{'unit_hits':[True,True],'found_units':2,'source_precision':.8,
                               'misleading_hits':[],'returned_count':k} for k in (5,10)},
                'canonical_rank':1,'canonical_reciprocal_rank':1.0}
        question={'group':'base','id':'q','answerable':True,'scores':scores,
                  'ranked_results':[{'path':'docs/a.md'}], 'required_evidence':['a','b'],
                  'resolved_source_qualifiers':{}}
        self.old={'evaluation_sha256':'a'*64,'variant':'plain','questions':[question],'metrics':{}}
        self.new=copy.deepcopy(self.old);self.new['evaluation_sha256']='b'*64
        changed=self.new['questions'][0]['scores']
        changed['canonical_rank']=2;changed['canonical_reciprocal_rank']=.5
        changed['at_k']['10']['source_precision']=.6
        self.labels={'queries':[{'id':'q','query':'same question','required_evidence':['a','b']}],'anchors':[]}

    def compare(self):
        return s.compare_baseline(self.old,self.new,self.labels,self.labels,True)

    def approval(self,comparison):
        return {'schema':'cyrus.retrieval-tradeoff-review/1','old_evaluation_sha256':'a'*64,
                'new_evaluation_sha256':'b'*64,'profile':'plain','comparison_sha256':s.sha(s.encoded(comparison)),
                'agent_reviewed':True,'reason':'Inspected newly enrolled evidence competes for ranks',
                'regressions':[{'finding':finding,'reason':'Required evidence remains fully retrieved; inspected changed rankings'}
                               for finding in comparison['regressions']]}

    def test_exact_manual_acceptance_preserves_failed_strict_result(self):
        comparison=self.compare();before=copy.deepcopy(comparison)
        result=s.review_manual_tradeoffs(comparison,self.old,self.new,self.approval(comparison))
        self.assertFalse(result['passed']);self.assertTrue(result['accepted_for_manual_candidate'])
        self.assertEqual(comparison,before);self.assertEqual(result['regressions'],before['regressions'])
        self.assertFalse(s.review_manual_tradeoffs(comparison,self.old,self.new)['accepted_for_manual_candidate'])

    def test_stale_identity_or_omitted_individual_reason_rejected(self):
        comparison=self.compare();review=self.approval(comparison)
        for change in ({'comparison_sha256':'c'*64},{'new_evaluation_sha256':'c'*64},
                       {'profile':'terminology'},{'agent_reviewed':False},{'regressions':[]},
                       {'reason':''},{'extra':'unrecognized'}):
            with self.subTest(change=change),self.assertRaises(s.Blocked):
                s.review_manual_tradeoffs(comparison,self.old,self.new,{**review,**change})

    def test_lost_required_unit_cannot_be_exchanged_for_another(self):
        self.old['questions'][0]['scores']['at_k']['10']['unit_hits']=[True,False]
        self.new['questions'][0]['scores']['at_k']['10']['unit_hits']=[False,True]
        comparison=self.compare()
        with self.assertRaises(s.Blocked) as error:
            s.review_manual_tradeoffs(comparison,self.old,self.new,self.approval(comparison))
        self.assertEqual(error.exception.issue,'unwaivable_retrieval_regression')

    def test_new_misleading_source_canonical_loss_and_negative_growth_denied(self):
        original=copy.deepcopy(self.new)
        for case in ('misleading5','misleading10','canonical','negative'):
            self.new=copy.deepcopy(original);q=self.new['questions'][0]
            if case.startswith('misleading'):
                q['scores']['at_k'][case[10:]]['misleading_hits']=[{'kind':'wrong_build','evidence':{'path':'docs/old.md'},'ranks':[1]}]
            elif case=='canonical':q['scores']['canonical_reciprocal_rank']=0
            else:
                q['answerable']=False;q['scores']['at_k']['10']['returned_count']=11
            comparison=self.compare()
            with self.subTest(case=case),self.assertRaises(s.Blocked) as error:
                s.review_manual_tradeoffs(comparison,self.old,self.new,self.approval(comparison))
            self.assertEqual(error.exception.issue,'unwaivable_retrieval_regression')


if __name__=='__main__':unittest.main()
