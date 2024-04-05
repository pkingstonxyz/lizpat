# lizpat

A lisp written in zig

## Todo list

 - [ ] Implement read for identifiers
 - [ ] Implement print for identifiers
 - [ ] Implement read for parens/cells
 - [ ] Implement print for parens/cells
 - [ ] Implement read for integers
 - [ ] Implement read for floats
 - [ ] Implement read for strings
 - [ ] Implement tests for reading identifiers
 - [ ] Implement tests for reading integers
 - [ ] Implement tests for reading floats
 - [ ] Implement tests for reading strings
 - [ ] Implement tests for reading parens/cells

## Decisions/Thoughts

Identifiers are not stored in a given Sexp cell, instead they are stored as
an array index which points to the identifier. (I don't know if this is a bad
idea or not. I think java does something similar? Idk I don't have internet lmao)

## Pseudocode

\* means it is a stretch goal/deferred/not an immediate goal

read(str) -> s-expr
 - Reads in a string to s-expressions

eval(s-expr) -> s-expr
 - Evaluates an s-expression

print(s-expr) -> void 
 - prints in human readable format

prn(s-expr)* -> void 
 - imperatively prints in *read* readable format


```
main:
    1. Decide if its launching a repl or running a program file, handle accordingly
    2. Create the allocator to be used throughout the programs runtime
    3. Allocate a bunch of cells in the free list
    4. Run based on 1
```

