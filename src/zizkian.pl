% SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
% Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
:- module(zizkian, [audit/2, audit_json/2, audit_file/2]).
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
    audit_record(Case, Raw), report_metadata(Raw, Report).

report_metadata(Raw, Report) :-
    Report = Raw.put(_{schema_version:'0.3.2',scope:declared_record_only,
        evidence_verified:false,
        human_review_required:[source_authenticity,evidence_relevance,
            test_discrimination,ordinary_explanation_strength,
            participant_authority,analyst_payoff,stopping_decision]}).

invalid_report(Issues, Report) :-
    report_metadata(report{status:invalid,verdict:repair_input,
        violations:Issues,warnings:[]},Report).

audit_record(Case, Report) :-
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
    setup_call_cleanup(open(Path, read, Stream, [type(binary)]),
        read_string(Stream, _, Bytes),
        close(Stream)),
    string_codes(Bytes,Octets),
    ( phrase(utf8_text(Codes),Octets) -> string_codes(Text,Codes),audit_json(Text,Report)
    ; invalid_report([issue{rule:input_error,target:input,
        message:'The file must contain valid UTF-8 without overlong encodings or surrogate code points.'}],Report) ).

% Decode bytes explicitly: permissive stream decoding can repair invalid UTF-8
% before validation sees it. Accept only shortest encodings of Unicode scalars.
utf8_text([C|Cs]) --> utf8_scalar(C), !, utf8_text(Cs).
utf8_text([]) --> [].
utf8_scalar(C) --> [C], {between(0,127,C)}, !.
utf8_scalar(C) --> [A,B], {between(194,223,A),between(128,191,B),
    C is (A-192)*64+B-128}, !.
utf8_scalar(C) --> [A,B,D], {between(224,239,A),between(128,191,B),between(128,191,D),
    (A=:=224 -> B>=160; A=:=237 -> B=<159; true),
    C is (A-224)*4096+(B-128)*64+D-128}, !.
utf8_scalar(C) --> [A,B,D,E], {between(240,244,A),between(128,191,B),
    between(128,191,D),between(128,191,E),
    (A=:=240 -> B>=144; A=:=244 -> B=<143; true),
    C is (A-240)*262144+(B-128)*4096+(D-128)*64+E-128}.

% Preserve JSON types until schema validation. Converting strings first loses
% the distinction between the text "false" and the JSON Boolean false.
audit_json(Text, Report) :-
    catch(audit_json_checked(Text, Report), _,
        invalid_report([issue{rule:input_error,target:input,
            message:'Supply one strict JSON document with unique object keys and valid Unicode.'}],Report)).

audit_json_checked(Text, Report) :-
    ( (string(Text);atom(Text)), string_codes(Text,Codes), phrase(json_document,Codes) -> true
    ; throw(error(syntax_error(strict_json),audit_json/2)) ),
    ( phrase(json_unicode(Normalized),Codes) -> string_codes(Json,Normalized)
    ; throw(error(syntax_error(unicode_scalar),audit_json/2)) ),
    atom_json_dict(Json, Typed, [value_string_as(string),default_tag(data)]),
    findall(I,schema_issue(json,case,Typed,case,I),Issues),
    ( Issues == [] -> canonical(Typed,Case), audit(Case,Report)
    ; invalid_report(Issues,Report) ).

canonical(V,C) :-
    ( string(V) -> atom_string(C,V)
    ; is_dict(V) -> dict_pairs(V,Tag,Pairs),maplist(canonical_pair,Pairs,Converted),dict_pairs(C,Tag,Converted)
    ; is_list(V) -> maplist(canonical,V,C)
    ; C=V ).
canonical_pair(K-V,K-C) :- canonical(V,C).

% Old SWI JSON libraries lack surrogate-pair decoding. Normalize genuine Unicode
% escapes after syntax validation, preserving all other escapes as whole units.
json_unicode(Codes) --> [92,117,A,B,C,D],
    {hex_value(A,VA),hex_value(B,VB),hex_value(C,VC),hex_value(D,VD),
     High is VA*4096+VB*256+VC*16+VD}, !,
    ( {between(55296,56319,High)} ->
        [92,117],json_hex_value(Low),{between(56320,57343,Low),
        Scalar is 65536+(High-55296)*1024+Low-56320,
        Codes=[Scalar|Rest]},json_unicode(Rest)
    ; {between(56320,57343,High)} -> {fail}
    ; {Codes=[92,117,A,B,C,D|Rest]},json_unicode(Rest) ).
json_unicode([92,C|Cs]) --> [92,C], !, json_unicode(Cs).
json_unicode([C|Cs]) --> [C], !, json_unicode(Cs).
json_unicode([]) --> [].
json_hex_value(Value) --> [A,B,C,D],
    {hex_value(A,VA),hex_value(B,VB),hex_value(C,VC),hex_value(D,VD),
     Value is VA*4096+VB*256+VC*16+VD}.
hex_value(C,V) :- (between(48,57,C)->V is C-48;between(65,70,C)->V is C-55;between(97,102,C)->V is C-87).

% Syntax-only preflight: SWI's JSON reader intentionally accepts some extensions.
% The same grammar guards native and WASM input; the library still decodes data.
json_document --> json_space, json_value, json_space.
json_space --> [C], {memberchk(C,[9,10,13,32])}, !, json_space.
json_space --> [].
json_value --> [123], !, json_space, json_members, [125].
json_value --> [91], !, json_space, json_elements, [93].
json_value --> [34], !, json_string.
json_value --> [116,114,117,101], !.
json_value --> [102,97,108,115,101], !.
json_value --> [110,117,108,108], !.
json_value --> json_number.
json_members --> json_member, !, json_more_members.
json_members --> [].
json_member --> [34], json_string, json_space, [58], json_space, json_value, json_space.
json_more_members --> [44], !, json_space, json_member, json_more_members.
json_more_members --> [].
json_elements --> json_value, !, json_space, json_more_elements.
json_elements --> [].
json_more_elements --> [44], !, json_space, json_value, json_space, json_more_elements.
json_more_elements --> [].
json_string --> [34], !.
json_string --> [92], !, json_escape, json_string.
json_string --> [C], {C>=32,C=\=34,C=\=92,\+between(55296,57343,C)}, json_string.
json_escape --> [C], {memberchk(C,[34,92,47,98,102,110,114,116])}, !.
json_escape --> [117], json_hex, json_hex, json_hex, json_hex.
json_hex --> [C], {between(48,57,C);between(65,70,C);between(97,102,C)}.
json_number --> json_minus, json_integer, json_fraction, json_exponent.
json_minus --> [45], !.
json_minus --> [].
json_integer --> [48], !.
json_integer --> [C], {between(49,57,C)}, json_digits.
json_digits --> [C], {between(48,57,C)}, !, json_digits.
json_digits --> [].
json_fraction --> [46], !, json_digit, json_digits.
json_fraction --> [].
json_exponent --> [C], {memberchk(C,[69,101])}, !, json_sign, json_digit, json_digits.
json_exponent --> [].
json_sign --> [C], {memberchk(C,[43,45])}, !.
json_sign --> [].
json_digit --> [C], {between(48,57,C)}.

verdict(C, Verdict) :-
    Kind = C.outcome.kind,
    ( Kind == retain_brief -> Verdict = awaiting_closure_review
    ; Kind == test -> Verdict = awaiting_test_review
    ; Verdict = awaiting_change_review ).

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

schema_issue(Type, Value, Path, Issue) :- schema_issue(prolog,Type,Value,Path,Issue).
schema_issue(Format, Type, Value, Path, Issue) :-
    ( is_dict(Value) ->
        schema(Type, Fields),
        ( member(Key-Spec, Fields), path(Path, Key, Child),
          ( get_dict(Key, Value, V) -> value_issue(Format, Spec, V, Child, Issue)
          ; Issue = issue{rule:missing_field,target:Child,message:'Required field missing.'} )
        ; dict_pairs(Value, _, Pairs), member(Key-_, Pairs),
          \+ memberchk(Key-_, Fields), path(Path, Key, Child),
          Issue = issue{rule:unknown_field,target:Child,message:'Unrecognized field; check spelling.'} )
    ; Issue = issue{rule:invalid_type,target:Path,message:'Expected an object.'} ).

value_issue(Format, object(Type), V, Path, I) :- schema_issue(Format, Type, V, Path, I).
value_issue(Format, list(Spec), V, Path, I) :-
    ( is_list(V) -> nth1(Index,V,Item), path(Path,Index,Child), value_issue(Format,Spec,Item,Child,I)
    ; I = issue{rule:invalid_type,target:Path,message:'Expected an array.'} ).
value_issue(Format, text, V, Path, I) :-
    \+ nonblank_text(Format,V),
    I = issue{rule:invalid_text,target:Path,message:'Expected nonblank text.'}.
value_issue(_, boolean, V, Path, I) :-
    \+ memberchk(V,[true,false]),
    I = issue{rule:invalid_boolean,target:Path,message:'Expected true or false.'}.
value_issue(Format, enum(Allowed), V, Path, I) :-
    \+ enum_value(Format,V,Allowed),
    format(atom(Message),'Expected one of ~w.',[Allowed]),
    I = issue{rule:invalid_status,target:Path,message:Message}.

nonblank_atom(V) :- atom(V), normalize_space(atom(Text),V), Text \== ''.
nonblank_text(prolog,V) :- nonblank_atom(V).
nonblank_text(json,V) :- string(V),normalize_space(string(Text),V),Text \== "".
enum_value(prolog,V,Allowed) :- memberchk(V,Allowed).
enum_value(json,V,Allowed) :- string(V),atom_string(A,V),memberchk(A,Allowed).
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
