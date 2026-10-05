% SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
% Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
:- use_module('../src/zizkian').
:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- initialization(main,main).

% schema/2 remains the single field/type definition. This export describes shape;
% the Prolog audit additionally enforces nonblank text, references and reasoning.
main :-
    source_file(main,File),file_directory_name(File,Directory),
    atom_concat(Directory,'/../VERSION',VersionFile),
    read_file_to_string(VersionFile,Raw,[]),normalize_space(atom(Version),Raw),
    format(atom(Id),'https://maciejjankowski.com/zizkian/schema/record-~w.schema.json',[Version]),
    shape(object(case),Case),
    Schema=Case.put(_{'$schema':'https://json-schema.org/draft/2020-12/schema',
        '$id':Id,title:'The Zizkian record shape only',
        '$comment':'Generated from schema/2. Shape only: run the Prolog checker for nonblank text, references and reasoning rules. Evidence remains unverified.'}),
    json_write_dict(current_output,Schema,[width(100)]),nl.

shape(object(Type),S) :-
    zizkian:schema(Type,Fields),
    findall(Key,(member(Key-_,Fields)),Required),
    findall(Key-V,(member(Key-Spec,Fields),shape(Spec,V)),Pairs),
    dict_pairs(Properties,data,Pairs),
    S=data{type:object,additionalProperties:false,required:Required,properties:Properties}.
shape(list(Spec),data{type:array,items:Item}) :- shape(Spec,Item).
shape(text,data{type:string,minLength:1}).
shape(boolean,data{type:boolean}).
shape(enum(Allowed),data{type:string,enum:Allowed}).
