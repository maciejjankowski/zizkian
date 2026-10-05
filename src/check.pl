% SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
% Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
:- use_module(zizkian).
:- use_module(library(http/json)).
:- initialization(main, main).

main :-
    current_prolog_flag(argv, Args),
    catch(run(Args,Report,Code), Error,
        ( message_to_string(Error,Message), Code=2,
          zizkian:invalid_report([issue{rule:input_error,target:input,message:Message}],Report) )),
    json_write_dict(current_output,Report,[width(100)]), nl, halt(Code).

run([Path],Report,Code) :- !,
    audit_file(Path,Report), exit_code(Report.status,Code).
run(_,_,_) :- throw(error(domain_error(arguments,
    'Usage: swipl -q -s src/check.pl -- case.json'),main/0)).

exit_code(pass,0).
exit_code(blocked,1).
exit_code(invalid,2).
