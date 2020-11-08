- [Video](#video)
- [Introduction](#introduction)
- [WebAssembly from scratch](#webassembly-from-scratch)
  - [Editor](#editor)
  - [Runtime](#runtime)
  - [Writing our first WebAssembly function](#writing-our-first-webassembly-function)
  - [Executing our first WebAssembly function](#executing-our-first-webassembly-function)
  - [Recursion in WebAssembly](#recursion-in-webassembly)
- [WebAssembly from C](#webassembly-from-c)
- [WebAssembly from AssemblyScript](#webassembly-from-assemblyscript)
- [Want more?](#want-more)

# Video

[![Bekijk de video](https://img.youtube.com/vi/e77IzFO5a28/hqdefault.jpg)](https://www.youtube.com/playlist?list=PLNALXJPvImgvamymxZXHTUIkeLhkjWIZY)

# Introduction

In the first section of this exercise session we will implement a simple program in pure WebAssembly.
In this section we will focus purely on the language itself and the security properties it offers.

However, WebAssembly is part of a big ecosystem of languages and toolchains.
In the second part of the session we will explore WebAssembly as a compilation target for the C language.

The third part of the session will look at integrations of WebAssembly into a web browser.
We will be executing our own WebAssembly programs inside a simple web page.

# WebAssembly from scratch

The basic text format in which WebAssembly can be written by hand is the `wat` (Web Assembly Text) format.

## Editor

`wat` files can be created with any text editor.
They are a textual representation of a WebAssembly program.
WebAssembly programs are typically executed in the `wasm` format, which contains WebAssembly bytecode directly interpretable by a WebAssembly stack machine.
The relation between `wat` and `wasm` is similar to the relation between assembly languages and machine code.

A cross-platform editor that supports syntax highlighting and code suggestion for the WebAssembly text format is [`Visual Studio Code`](https://code.visualstudio.com/). 
Use the marketplace to install the WebAssembly Toolkit for VSCode.

## Runtime

There are many ways to execute WebAssembly bytecode on your machine.
You could for instance use;
* An interpreter
* An emulator
* A compiler
  * Ahead-of-time
  * Just-in-time

An *interpreter* will read the WebAssembly file line by line, while parsing and executing each line. An *emulator* will emulate an actual WebAssembly stack machine on which you can directly execute the bytecode. A *compiler* will translate the WebAssembly bytecode to the [ISA](https://en.wikipedia.org/wiki/Instruction_set_architecture) of your computer. 

*Ahead-of-time compilers* will translate this bytecode and provide you with an object file or executable that can be used on your machine. *Just-in-time compilers* are a sort of hybrid between interpreters and ahead-of-time compilers. Some code in the source file is interpreted while other code (typically code that executes often) is compiled and executed.

For this exercise we will suggest to use [`wasmtime`](https://github.com/bytecodealliance/wasmtime), a mature just-in-time compiler for WebAssembly.
Follow the installation instructions for `wasmtime` on the GitHub page.

## Writing our first WebAssembly function

Typically we start our journey in a new programming language using a simple *Hello, world!* program.
Here we run into a problem.
The WebAssembly stack machine has no inherent monitor or console to which we can print strings.
In WebAssembly, *Hello, world!* is rather complex.

Let's start with a simple addition function as discussed in the introductory video.

```wasm
(module
    (func $add (param i32 i32) (result i32)
    local.get 0 ;;Push first parameter to stack
    local.get 1 ;;Push second parameter to stack
    i32.add ;;Consume two values from the stack
            ;;Push the sum of these parameters back to the stack
    )
)
```
This example differs slightly from the video.
We didn't name our parameters since that is optional.
Parameters can be accessed using an index.
Also, we've used `local.get` instead of `get_local`.
Both are the same.

## Executing our first WebAssembly function

So we've written a function that can be executed on a WebAssembly stack machine.
`wasmtime` allows us to execute functions in WebAssembly modules from the command line using `--invoke`.

```bash
$ wasmtime add.wat --invoke add 1 2
Error: failed to run main module `add.wat`

Caused by:
    no item named `add` in ``
```
We have defined the function `$add` as private to the module.
If we want to access this function from outside the module we need to export it.

```wasm
(module
    (func $add (export "add") (param i32 i32) (result i32)
    local.get 0 ;;Push first parameter to stack
    local.get 1 ;;Push second parameter to stack
    i32.add ;;Consume two values from the stack
            ;;Push the sum of these parameters back to the stack
    )
)
```

Now we can call it using `wasmtime` (you can safely ignore the warnings):

```bash
$ wasmtime add.wat --invoke add 1 2
...
3
```

## Recursion in WebAssembly

Take a look at this simple recursive WebAssembly factorial implementation and read the inlined comments:

```wasm

(module
    (func $factorial (export "fact") (param i32) (result i32)
        ;;Function execution starts from an empty stack
        ;;Due to the result type, the function execution should end
        ;;with a single i32 value on the stack.
        (if (result i32) ;;Both if-branches must end with 1 i32 on the stack
            (i32.lt_s (local.get 0) (i32.const 2)) ;;Condition (if n < 2)
            (then (i32.const 1)) ;;Push value 1 to stack
            (else
                (i32.sub (local.get 0) (i32.const 1)) ;;Push value n - 1 to stack
                call $factorial ;;Pops one value (n - 1) from stack and pushes
                                ;;factorial(n - 1) to stack
                local.get 0     ;;Push n to stack
                i32.mul         ;;Pops 2 values from stack (n, n - 1)
                                ;;and replaces with their multiplication
            )
        )
    )
)
```
To write WebAssembly you need to constantly keep the stack state in mind.
Even an `if` statement needs to adhere to the type system.
These restrictions make it impossible to write a valid WebAssembly function that does not adhere to it's own type signature.
In other words, if the signature of a valid WebAssembly function states that it takes two parameters and produces one return value, this is a guarantee. Thus, the type system knows the exact effect a function call will have on the state of the program call stack.


> **Exercise**: Write a recursive function `$fibonnaci(n)` that calculates the n-th fibonnaci number.

# WebAssembly from C

**TODO**

# WebAssembly from AssemblyScript

**TODO**

# Want more?

[https://webassembly.org/getting-started/developers-guide/](Developers guide)