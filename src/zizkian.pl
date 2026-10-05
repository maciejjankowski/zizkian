% SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
% Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
:- module(zizkian, [audit/2, audit_file/2]).
% Native SWI calls this library http/json; its WASM distribution calls it json.
:- if(exists_source(library(http/json))).
:- use_module(library(http/json)).
:- else.
:- use_module(library(json)).
:- endif.
:- use_module(library(lists)).

% The Zizkian: inspect a declared reasoning record, never infer hidden motives.
% Negation below means absent from this validated record, not false in the world.

audit(Case, Report) :-
    ( ground(Case) ->
        findall(I, schema_issue(case, Case, case, I), ShapeIssues),
        ( ShapeIssues == [] ->
            findall(I, reference_issue(Case, I), InputIssues)
        ; InputIssues = ShapeIssues )
    ; InputIssues = [issue{rule:non_ground_input,target:case,
        message:'Supply a complete ground record; unknowns need explicit statuses.'}] ),
    ( InputIssues \== [] ->
        Report = report{status:invalid,verdict:repair_input,
            violations:InputIssues,warnings:[]}
    ; findall(issue{rule:Rule,target:Target,message:Message},
            violation(Case, Rule, Target, Message), Raw),
      sort(Raw, Violations),
      findall(issue{rule:Rule,target:Target,message:Message},
            caution(Case, Rule, Target, Message), Warnings),
      ( Violations == [] -> Status = pass, verdict(Case, Verdict)
      ; Status = blocked, Verdict = revise ),
      Report = report{status:Status,verdict:Verdict,
          violations:Violations,warnings:Warnings}
    ).

audit_file(Path, Report) :-
    setup_call_cleanup(open(Path, read, Stream, [encoding(utf8)]),
        ( json_read_dict(Stream, Case, [value_string_as(atom),default_tag(data)]),
          read_string(Stream, _, Rest), normalize_space(string(Tail), Rest),
          ( Tail == "" -> true
          ; throw(error(domain_error(single_json_document, Path), audit_file/2)) ) ),
        close(Stream)),
    audit(Case, Report).

verdict(C, Verdict) :-
    Kind = C.outcome.kind,
    ( Kind == retain_brief -> Verdict = no_finding
    ; Kind == test -> Verdict = ready_for_test
    ; Verdict = ready_for_decision ).

schema(case, [id-text,mode-enum([consulting,coaching]),coaching_invited-boolean,
    brief-text,desired_result-text,owner-text,lenses-list(text),ordinary-object(ordinary),
    return_cut-object(reflection),evidence-list(object(evidence)),
    readings-list(object(reading)),outcome-object(outcome)]).
schema(ordinary, [claim-text,check-text,status-enum([untested,checked]),evidence-list(text)]).
schema(reflection, [observer-text,statement-text,defeater-text,
    status-enum([hypothesis,no_finding])]).
schema(evidence, [id-text,statement-text,source-text,
    kind-enum([observation,participant_rejection,attention_weight])]).
schema(reading, [id-text,claim-text,status-enum([hypothesis,supported,withdrawn]),
    response-enum([unasked,accepted,rejected]),support-list(text),
    counterevidence-list(text),defeat_test-object(test)]).
schema(test, [method-text,observation-text,status-enum([untested,survived,defeated]),
    evidence-list(text)]).
schema(outcome, [kind-enum([retain_brief,test,change]),action-text,reason-text,
    reading_ids-list(text),stop_rule-text]).

schema_issue(Type, Value, Path, Issue) :-
    ( is_dict(Value) ->
        schema(Type, Fields),
        ( member(Key-Spec, Fields), path(Path, Key, Child),
          ( get_dict(Key, Value, V) -> value_issue(Spec, V, Child, Issue)
          ; Issue = issue{rule:missing_field,target:Child,message:'Required field missing.'} )
        ; dict_pairs(Value, _, Pairs), member(Key-_, Pairs),
          \+ memberchk(Key-_, Fields), path(Path, Key, Child),
          Issue = issue{rule:unknown_field,target:Child,message:'Unrecognized field; check spelling.'} )
    ; Issue = issue{rule:invalid_type,target:Path,message:'Expected an object.'} ).

value_issue(object(Type), V, Path, I) :- schema_issue(Type, V, Path, I).
value_issue(list(Spec), V, Path, I) :-
    ( is_list(V) -> nth1(Index,V,Item), path(Path,Index,Child), value_issue(Spec,Item,Child,I)
    ; I = issue{rule:invalid_type,target:Path,message:'Expected an array.'} ).
value_issue(text, V, Path, I) :-
    \+ nonblank_atom(V),
    I = issue{rule:invalid_text,target:Path,message:'Expected nonblank text.'}.
value_issue(boolean, V, Path, I) :-
    \+ memberchk(V,[true,false]),
    I = issue{rule:invalid_boolean,target:Path,message:'Expected true or false.'}.
value_issue(enum(Allowed), V, Path, I) :-
    \+ memberchk(V,Allowed),
    format(atom(Message),'Expected one of ~w.',[Allowed]),
    I = issue{rule:invalid_status,target:Path,message:Message}.

nonblank_atom(V) :- atom(V), normalize_space(atom(Text),V), Text \== ''.
path(Parent, Key, Path) :- format(atom(Path),'~w.~w',[Parent,Key]).

reference_issue(C, issue{rule:duplicate_id,target:Target,message:'IDs must be unique.'}) :-
    ( Target = evidence, Items = C.evidence ; Target = readings, Items = C.readings ),
    findall(Id,(member(Item,Items),Id=Item.id),Ids),
    sort(Ids,Unique), length(Ids,N), length(Unique,M), N \= M.
reference_issue(C, issue{rule:unknown_evidence,target:Target,message:Message}) :-
    evidence_ref(C,Target,Id), \+ evidence(C,Id,_),
    format(atom(Message),'Unknown evidence ID: ~w.',[Id]).
reference_issue(C, issue{rule:unknown_reading,target:outcome,message:Message}) :-
    member(Id,C.outcome.reading_ids), \+ reading(C,Id,_),
    format(atom(Message),'Unknown reading ID: ~w.',[Id]).

evidence_ref(C, ordinary, Id) :- member(Id,C.ordinary.evidence).
evidence_ref(C, Target, Id) :-
    member(R,C.readings), Target = R.id,
    ( member(Id,R.support); member(Id,R.counterevidence); member(Id,R.defeat_test.evidence) ).
evidence(C, Id, E) :- member(E,C.evidence), E.id == Id.
reading(C, Id, R) :- member(R,C.readings), R.id == Id.
observation(C, Id) :- evidence(C,Id,E), E.kind == observation.
active(R) :- R.status \== withdrawn.
selected(C, R) :- member(Id,C.outcome.reading_ids), reading(C,Id,R).

% Named rules yield a complete violation list, not a single opaque boolean.
violation(C, coaching_not_invited, case, 'Personal coaching requires an invitation.') :-
    C.mode == coaching, C.coaching_invited == false.
violation(C, lens_count, lenses, 'Consulting selects 1 to 3 lenses; coaching selects one.') :-
    length(C.lenses,N),
    ( N < 1 ; C.mode == consulting, N > 3 ; C.mode == coaching, N > 1 ).
violation(C, lens_not_in_mode, Lens, 'This lens does not belong to the selected mode.') :-
    member(Lens,C.lenses), \+ permitted_lens(C.mode,Lens).
violation(C, duplicate_lens, lenses, 'Do not count the same lens more than once.') :-
    sort(C.lenses,U), length(C.lenses,N), length(U,M), N \= M.
violation(C, unsupported_reading, Target, 'A supported reading needs a sourced observation.') :-
    member(R,C.readings), Target = R.id, R.status == supported,
    \+ (member(Id,R.support),observation(C,Id)).
violation(C, rejection_as_evidence, Target, 'Participant rejection cannot support a reading.') :-
    member(R,C.readings), Target = R.id, active(R), member(Id,R.support),
    evidence(C,Id,E), E.kind == participant_rejection.
violation(C, weight_as_evidence, Target, 'An attention weight is not evidence for a reading.') :-
    member(R,C.readings), Target = R.id, active(R), member(Id,R.support),
    evidence(C,Id,E), E.kind == attention_weight.
violation(C, conflicting_evidence, Target, 'The same item is declared support and counterevidence.') :-
    member(R,C.readings), Target = R.id, active(R), member(Id,R.support), memberchk(Id,R.counterevidence).
violation(C, unresolved_counterevidence, Target, 'Withdraw or revise a reading with declared counterevidence.') :-
    member(R,C.readings), Target = R.id, R.status == supported, R.counterevidence \== [].
violation(C, defeated_reading, Target, 'A defeated reading must be withdrawn.') :-
    member(R,C.readings), Target = R.id, active(R), R.defeat_test.status == defeated.
violation(C, test_without_observation, Target, 'An observed test outcome requires observation evidence.') :-
    member(R,C.readings), Target = R.id, R.defeat_test.status \== untested,
    \+ (member(Id,R.defeat_test.evidence),observation(C,Id)).
violation(C, ordinary_without_observation, ordinary, 'A checked alternative needs an observation.') :-
    C.ordinary.status == checked,
    \+ (member(Id,C.ordinary.evidence),observation(C,Id)).
violation(C, ordinary_not_checked, ordinary, 'Check the ordinary explanation before changing the decision.') :-
    C.outcome.kind == change, C.ordinary.status \== checked.
violation(C, closure_uses_reading, outcome, 'No finding closes without selecting an interpretation.') :-
    C.outcome.kind == retain_brief, C.outcome.reading_ids \== [].
violation(C, missing_basis, outcome, 'A test or change must name its reading.') :-
    C.outcome.kind \== retain_brief, C.outcome.reading_ids == [].
violation(C, decision_uses_hypothesis, Target, 'A change needs a supported reading, not a hypothesis.') :-
    C.outcome.kind == change, selected(C,R), Target = R.id, R.status \== supported.
violation(C, withdrawn_reading_selected, Target, 'A withdrawn reading cannot drive a test or change.') :-
    selected(C,R), Target = R.id, R.status == withdrawn.
violation(C, participant_rejected, Target, 'A rejected framing cannot drive the participant\'s next step.') :-
    selected(C,R), Target = R.id, R.response == rejected.
violation(C, coaching_choice_unconfirmed, Target, 'The participant must accept a coaching step\'s framing.') :-
    C.mode == coaching, selected(C,R), Target = R.id, R.response \== accepted.

caution(C, untested_alternative, ordinary, 'The ordinary explanation has not yet been checked.') :-
    C.ordinary.status == untested.
caution(C, untested_falsifier, Target, 'A defeating observation is specified but has not been tested.') :-
    member(R,C.readings), Target = R.id, active(R), R.defeat_test.status == untested.

permitted_lens(_, veil_piercer).
permitted_lens(consulting,L) :- memberchk(L,[customer_advocate,constraint_hunter,
    incentive_detective,economic_examiner,cannibal,operator]).
permitted_lens(coaching,L) :- memberchk(L,[mirror,pattern_archaeologist,
    identity_explorer,agency_auditor,boundary_engineer,choice_architect]).
