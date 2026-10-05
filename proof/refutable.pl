:- module(zizkian_refutability, [refutability/1]).
:- use_module('../src/zizkian').
:- use_module(library(http/json)).
:- initialization(main, main).

% A finite witness of a formal property, not proof of a real-world diagnosis.
refutability(Report) :-
    source_file(zizkian_refutability:refutability(_), Source),
    file_directory_name(Source, Directory),
    example(Directory, 'supported.json', Before),
    example(Directory, 'defeated.json', Defeated),
    example(Directory, 'withdrawn.json', Withdrawn),
    Before.status == pass,
    Defeated.status == blocked,
    member(Issue, Defeated.violations), Issue.rule == defeated_reading,
    Withdrawn.status == pass, Withdrawn.verdict == no_finding,
    Report = proof{property:refutable,status:demonstrated,
        scope:'A fictional declared reading can lose eligibility and be withdrawn.',
        before:Before,after_defeater:Defeated,after_withdrawal:Withdrawn}.

example(Directory, Name, Report) :-
    atomic_list_concat([Directory,'/../examples/',Name], Path), audit_file(Path,Report).

main :-
    ( refutability(Report) -> json_write_dict(current_output,Report,[width(100)]),nl,halt(0)
    ; writeln(user_error,'Refutability witness failed.'), halt(1) ).
