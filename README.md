# lizpat

A lisp written in zig

## Todo list

 - [x] Implement scan for parens
 - [x] Implement scan for comments
 - [x] Implement scan for strings
 - [x] Implement scan for numbers
 - [x] Implement scan for identifiers
 - [ ] Implement read for identifiers
 - [ ] Implement print for identifiers
 - [ ] Implement read for parens/cells
 - [ ] Implement print for parens/cells
 - [ ] Implement read for strings
 - [ ] Implement print for strings
 - [ ] Implement read for numbers
 - [ ] Implement print for strings
 - [ ] Implement tests for reading identifiers
 - [ ] Implement tests for reading integers
 - [ ] Implement tests for reading floats
 - [ ] Implement tests for reading strings
 - [ ] Implement tests for reading parens/cells

 ## Roadmap

Get a functioning RPL up and running

Get a calculator REPL up and running

Implement def

Implement fn

## Rough pseudocode

```
scanner (implemented basically identically to Crafting Interpreters)

read(scanner) -> sexp:
    list = new list
    loop:
        get token from scanner
        if error, handle it
        add it to the list
    #Reader macros need to get taken care of somewhere in here
    stack = newstack
    root = new cell
    curr = root
    for tok in list:
        if (:
            cell = new cell
            curr.cdr = new
        elif ):
            curr = stack.pop()
            if stack not empty:
                stack.top.car = curr
            else:
                return curr
        else:


eval

print

main
    init stdin, stdout
    init scanner "object"
    init memory allocator
    loop:
        print prompt
        collect input
        point scanner at input
        expr = read(in, scanner);
        result = eval(expr);
        print(result)
```
