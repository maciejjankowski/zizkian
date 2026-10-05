:- use_module('../src/zizkian').
:- use_module(library(plunit)).

:- begin_tests(zizkian).

base(C) :-
    C = case{
        id: demo, mode: consulting, coaching_invited: false,
        brief: 'Improve onboarding', desired_result: 'First task completed',
        owner: 'Product lead', lenses: [constraint_hunter, veil_piercer],
        ordinary: ordinary{claim: 'Instruction may be sufficient',
            check: 'Compare instruction with a simplified flow',
            status: checked, evidence: [e1]},
        return_cut: reflection{observer: 'Analyst',
            statement: 'I benefit from recommending a redesign',
            defeater: 'Instruction alone achieves the desired result', status: hypothesis},
        evidence: [evidence{id: e1, statement: 'Users completed the task after instruction',
            source: 'Fictional test note', kind: observation}],
        readings: [],
        outcome: outcome{kind: retain_brief, action: 'Keep instruction',
            reason: 'No supported reason to reframe', reading_ids: [],
            stop_rule: 'Reopen if first-task failures recur'}
    }.

reading(R) :-
    R = reading{id: r1, claim: 'Flow complexity prevents completion',
        status: hypothesis, response: unasked, support: [], counterevidence: [],
        defeat_test: test{method: 'Compare two flows',
            observation: 'Instruction alone performs as well',
            status: untested, evidence: []}}.

has_rule(Report, Rule) :- member(V, Report.violations), V.rule == Rule.

test(no_finding_closes) :-
    base(C), audit(C, R), assertion(R.status == pass), assertion(R.verdict == no_finding).

test(hypothesis_allows_test_without_claiming_truth) :-
    base(C), reading(H),
    O = C.outcome.put(_{kind:test, action:'Run comparison', reading_ids:[r1]}),
    audit(C.put(_{readings:[H],outcome:O}), R),
    assertion(R.status == pass), assertion(R.verdict == ready_for_test).

test(evidence_backed_change) :-
    base(C), reading(H), T = H.defeat_test.put(_{status:survived,evidence:[e1]}),
    S = H.put(_{status:supported,support:[e1],defeat_test:T}),
    O = C.outcome.put(_{kind:change,reading_ids:[r1]}),
    audit(C.put(_{readings:[S],outcome:O}), R),
    assertion(R.status == pass), assertion(R.verdict == ready_for_decision).

test(unsupported_certainty_blocked) :-
    base(C), reading(H), audit(C.put(readings,[H.put(status,supported)]), R),
    assertion(R.status == blocked), assertion(has_rule(R, unsupported_reading)).

test(rejection_cannot_support_hidden_motive) :-
    base(C), reading(H), [E] = C.evidence,
    Trap = E.put(kind,participant_rejection),
    S = H.put(_{status:supported,support:[e1],response:rejected}),
    audit(C.put(_{evidence:[Trap],readings:[S]}), R),
    assertion(has_rule(R, rejection_as_evidence)).

test(weights_are_not_evidence) :-
    base(C), reading(H), [E] = C.evidence,
    S = H.put(_{status:supported,support:[e1]}),
    audit(C.put(_{evidence:[E.put(kind,attention_weight)],readings:[S]}), R),
    assertion(has_rule(R, weight_as_evidence)).

test(defeated_reading_must_be_withdrawn) :-
    base(C), reading(H), T = H.defeat_test.put(_{status:defeated,evidence:[e1]}),
    S = H.put(_{status:supported,support:[e1],defeat_test:T}),
    audit(C.put(readings,[S]), R), assertion(has_rule(R, defeated_reading)).

test(withdrawn_reading_allows_closure) :-
    base(C), reading(H), T = H.defeat_test.put(_{status:defeated,evidence:[e1]}),
    W = H.put(_{status:withdrawn,defeat_test:T}),
    audit(C.put(readings,[W]), R), assertion(R.status == pass).

test(coaching_requires_invitation) :-
    base(C), audit(C.put(_{mode:coaching,lenses:[mirror]}), R),
    assertion(has_rule(R, coaching_not_invited)).

test(accepted_response_does_not_replace_observation) :-
    base(C), reading(H), S = H.put(_{status:supported,response:accepted}),
    audit(C.put(readings,[S]), R), assertion(has_rule(R, unsupported_reading)).

test(rejected_coaching_reading_cannot_drive_action) :-
    base(C), reading(H), S = H.put(_{status:supported,support:[e1],response:rejected}),
    O = C.outcome.put(_{kind:change,reading_ids:[r1]}),
    audit(C.put(_{mode:coaching,coaching_invited:true,lenses:[mirror],
        readings:[S],outcome:O}), R),
    assertion(has_rule(R, participant_rejected)).

test(no_finding_cannot_hide_selected_interpretation) :-
    base(C), reading(H), O = C.outcome.put(reading_ids,[r1]),
    audit(C.put(_{readings:[H],outcome:O}), R),
    assertion(has_rule(R, closure_uses_reading)).

test(hypothesis_cannot_authorize_change) :-
    base(C), reading(H), O = C.outcome.put(_{kind:change,reading_ids:[r1]}),
    audit(C.put(_{readings:[H],outcome:O}), R),
    assertion(has_rule(R, decision_uses_hypothesis)).

test(ordinary_explanation_must_be_checked_before_change) :-
    base(C), reading(H), S = H.put(_{status:supported,support:[e1]}),
    O = C.outcome.put(_{kind:change,reading_ids:[r1]}),
    A = C.ordinary.put(_{status:untested,evidence:[]}),
    audit(C.put(_{readings:[S],ordinary:A,outcome:O}), R),
    assertion(has_rule(R, ordinary_not_checked)).

test(same_evidence_cannot_support_and_defeat) :-
    base(C), reading(H), S = H.put(_{support:[e1],counterevidence:[e1]}),
    audit(C.put(readings,[S]), R), assertion(has_rule(R, conflicting_evidence)).

test(missing_falsifier_is_invalid) :-
    base(C), reading(H), del_dict(defeat_test,H,_,Incomplete),
    audit(C.put(readings,[Incomplete]), R), assertion(R.status == invalid).

test(blank_falsifier_is_invalid) :-
    base(C), reading(H), T = H.defeat_test.put(observation,'   '),
    audit(C.put(readings,[H.put(defeat_test,T)]), R), assertion(R.status == invalid).

test(unknown_fields_are_invalid) :-
    base(C), audit(C.put(truth_score,0.98), R), assertion(R.status == invalid).

test(unknown_evidence_reference_is_invalid) :-
    base(C), reading(H), audit(C.put(readings,[H.put(support,[missing])]), R),
    assertion(R.status == invalid).

test(duplicate_ids_are_invalid) :-
    base(C), [E] = C.evidence, audit(C.put(evidence,[E,E]), R),
    assertion(R.status == invalid).

test(no_silent_defaults) :-
    base(C), del_dict(return_cut,C,_,Incomplete), audit(Incomplete,R),
    assertion(R.status == invalid).

test(wrong_type_is_invalid) :-
    base(C), audit(C.put(readings,42), R), assertion(R.status == invalid).

test(non_ground_input_is_invalid) :-
    base(C), audit(C.put(owner,_), R), assertion(R.status == invalid).

test(test_status_cannot_claim_observation_without_evidence) :-
    base(C), reading(H), T = H.defeat_test.put(status,survived),
    audit(C.put(readings,[H.put(defeat_test,T)]), R),
    assertion(has_rule(R, test_without_observation)).

test(all_rules_reported) :-
    base(C), reading(H), S = H.put(status,supported),
    audit(C.put(_{mode:coaching,lenses:[mirror],readings:[S]}), R),
    assertion(has_rule(R, coaching_not_invited)),
    assertion(has_rule(R, unsupported_reading)).

test(unknown_lens_blocked) :-
    base(C), audit(C.put(lenses,[omniscient_judge]),R),
    assertion(has_rule(R,lens_not_in_mode)).

test(personal_lens_cannot_silently_enter_business_analysis) :-
    base(C), audit(C.put(lenses,[identity_explorer]),R),
    assertion(has_rule(R,lens_not_in_mode)).

test(duplicate_lens_does_not_add_authority) :-
    base(C), audit(C.put(lenses,[operator,operator]),R),
    assertion(has_rule(R,duplicate_lens)).

test(coaching_does_not_become_a_panel) :-
    base(C), audit(C.put(_{mode:coaching,coaching_invited:true,lenses:[mirror,agency_auditor]}),R),
    assertion(has_rule(R,lens_count)).

test(accepted_coaching_hypothesis_can_be_tested) :-
    base(C), reading(H), A=H.put(response,accepted),
    O=C.outcome.put(_{kind:test,reading_ids:[r1]}),
    audit(C.put(_{mode:coaching,coaching_invited:true,lenses:[agency_auditor],
        readings:[A],outcome:O}),R), assertion(R.status==pass).

test(counterevidence_cannot_be_averaged_away) :-
    base(C), reading(H), S=H.put(_{status:supported,support:[e1],counterevidence:[e1]}),
    audit(C.put(readings,[S]),R), assertion(has_rule(R,unresolved_counterevidence)).

test(withdrawn_reading_cannot_drive_test) :-
    base(C), reading(H), W=H.put(status,withdrawn),
    O=C.outcome.put(_{kind:test,reading_ids:[r1]}),
    audit(C.put(_{readings:[W],outcome:O}),R),
    assertion(has_rule(R,withdrawn_reading_selected)).

test(no_basis_cannot_authorize_change) :-
    base(C), audit(C.put(outcome,C.outcome.put(kind,change)),R),
    assertion(has_rule(R,missing_basis)).

test(schema_cannot_be_satisfied_with_truth_score) :-
    base(C), audit(C.put(evidence,0.999),R), assertion(R.status==invalid).

test(checked_alternative_cannot_use_rejection) :-
    base(C), [E]=C.evidence,
    audit(C.put(evidence,[E.put(kind,participant_rejection)]),R),
    assertion(has_rule(R,ordinary_without_observation)).

:- end_tests(zizkian).
