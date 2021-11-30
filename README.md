- [Video](#video)
- [Introduction](#introduction)
- [WebAssembly from scratch](#webassembly-from-scratch)
  - [Editor](#editor)
  - [Runtime](#runtime)
  - [Writing our first WebAssembly function](#writing-our-first-webassembly-function)
  - [Executing our first WebAssembly function](#executing-our-first-webassembly-function)
  - [Recursion](#recursion)
  - [Exploring the type system](#exploring-the-type-system)
  - [Loops](#loops)
  - [WebAssembly System Interface](#webassembly-system-interface)
    - [Hello world](#hello-world)
- [WebAssembly as a compilation target](#webassembly-as-a-compilation-target)
  - [WebAssembly from C](#webassembly-from-c)
    - [Undefined behavior](#undefined-behavior)
- [WebAssembly in the browser](#webassembly-in-the-browser)
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

* **Exercise** Write a simple WebAssembly function `calc(a, b, c, d)` that returns `a * b - c * d` and test it using `wasmtime`

## Recursion

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


* **Exercise**: Write a recursive function `$fibonnaci(n)` that calculates the n-th fibonnaci number.

## Exploring the type system

If you've attempted to solve previous exercise you might've ran into some trouble with the WebAssembly type system.
Let's explore the type system in more detail using some examples.

When we look at the [WebAssembly specifications](https://webassembly.github.io/spec/core/valid/types.html#block-types) for block types we read the following statement:


> The block type is valid as function type [] → [valtype?].


A little higher in this specification we can find

> The 𝖻𝗅𝗈𝖼𝗄, 𝗅𝗈𝗈𝗉 and 𝗂𝖿 instructions are structured instructions. They bracket nested sequences of instructions, called blocks, terminated with, or separated by, 𝖾𝗇𝖽 or 𝖾𝗅𝗌𝖾 pseudo-instructions. As the grammar prescribes, they must be well-nested.
> 
> A structured instruction can consume input and produce output on the operand stack according to its annotated block type. It is given either as a type index that refers to a suitable function type, or as an optional value type inline, which is a shorthand for the function type [] → [valtype?].

What these statements informally say is that if-statements cannot consume values from the stack, but they might produce a value of type `valtype` to the stack.

The direct consequence of this statement is that the following construct is impossible:

```wasm
(module
    (func $impossible (export "impossible") (param i32) (result i32)
    local.get 0 ;;push param to the call stack
    local.get 0 ;;push param to the call stack
        (if (i32.const 0)
            (then (i32.add)) ;;consume two values from call stack 
                             ;;(replace with sum)
            (else (i32.sub)) ;;consume two values from call stack 
                             ;;(replace with difference)
        )
    )
)
```
We have tried to write a function that, depending on a condition (in this example always false), either substracts or adds the top two values on the call stack.
On first sight, it looks like this should work.
Starting from an empty stack, we push two values at the start of the function.
We then either execute add or substract, which both consume two values and push one value.
Thus we end up with a single result value on the stack, which is the return type of our function.

However, when we try to compile this, we get the following message:

```bash
$ wasmtime impossible.wat 
Error: failed to run main module `impossible.wat`

Caused by:
    0: WebAssembly failed to compile
    1: WebAssembly translation error
    2: Invalid input WebAssembly code at offset 49: type mismatch: expected i32 but nothing on stack
```

This error message complains that whenever we attempt to execute `i32.add`, there is nothing on the stack.
But didn't we push two values to the stack, right before the if-statement?
The problem is that structured instructions such as if-statements need to adhere to the function type `[] -> valtype`.
They are not allowed to consume values that were on the call stack before the invocation of the if-statement.
In other words, just like with function calls, we need to execute the branches of an if-statement as if we had started from an empty stack.
This explains the error message we have received.

## Loops

Time to increase the complexity.
We have rewritten our factorial function to work in an iterative fashion.
Here's a C-representation of our WebAssembly rewrite:

```c
int fact(int n){
  int res = 1;
  do {
    res = res * n;
  }
  while(--n > 1);
  return res;
}
```

Now look at the WebAssembly code and try to understand what is happening.
We have explicitly avoided the nested textual representation since our chosen representation allows us a clear view of the stack state at each execution point.

```wasm
(module
    (func $factorial (export "fact") (param i32) (result i32)
        (local $res i32) ;;stack = <empty> || declare local var res
        (local.set $res (i32.const 1)) ;;stack = <empty> || $res = 1
        (loop $fact (result i32)
            ;;stack: <empty> (start of block)
            local.get 0     ;;stack: n
            local.get 0     ;;stack: n, n
            local.get $res  ;;stack: $res, n, n
            i32.mul         ;;stack: n * $res, n
            local.set $res  ;;stack: n || $res = n * $res 
            i32.const 1     ;;stack: 1, n
            i32.sub         ;;stack: n - 1
            local.tee 0     ;;stack: n - 1 || n = n - 1
            i32.const 1     ;;stack: 1, n - 1
            i32.gt_s        ;;stack: n - 1 > 1
            br_if $fact     ;;stack: <empty>
            local.get $res  ;;stack: $res
            ;;stack: $res -> single i32, return type of block
        )
    )
)
```

The first new thing in this definition is the fact that we are now using local variables.
Using the `local` command we can create a local variable to use during function execution.

Next, notice what we have declared a `loop` block.
We specify that the block has the type `[] -> [i32]`, meaning it will produce a single `i32` on our call stack.
`loop` blocks do not have a loop condition.
In fact, all `loop` does is declare a labeled block to which we can jump back during it's execution.
To `loop`, we need to use a branching statement like `br_if` before ending the `loop`. At the end of the loop the local loop stack needs to contain exactly one `i32`.

One instruction in the `loop` might confuse you: the `local.tee` instruction.
This instruction sets the value of a local variable, just like `local.set`, but it does not consume a value from the stack while doing so.

Notice that `br_if` consumes the top value of the stack and branches if that value was non-zero.
`i32.gt_s` produces a `1` if `a > b` and a `0` otherwise.
At the end of our `loop` block we can verify that our local loop stack will indeed contain exactly one `i32` value.
The function passes the type checker.

* **Exercise** Rewrite your fibonnaci function as an iterative function using loops.

> :bulb: When writing WebAsssembly by hand it's a good idea to keep track of the state of your stack at all times. Comments are great way to do this.

## WebAssembly System Interface

Up until now we have been writing pure WebAssembly for the WebAssembly stack machine.
We have basically invoked functions by providing `wasmtime` with an initial stack state. `wasmtime` then printed the result value that remained on the stack at the end of the function execution.

Real life programs, however, interact with the system on which they are executed.
For example, a function might read or write to a file or the console.
The [WebAssembly System Interface (WASI)](https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-overview.md) is an interface meant to provide a standardized way for WebAssembly programs to interact with the system on which they are executed.
They define a number of system calls, the definitions of which can be found [here](https://github.com/WebAssembly/WASI/blob/master/phases/snapshot/docs.md).

Opening up this interface increases the capabilities of WebAssembly programs.
However, it has downsides.
Whenever you execute a system call you hand over control to the surrounding operating system.
These system calls, if implemented incorrectly, could potentially destroy the WebAssembly guarantees.
The system calls themselves could be implemented in an unsafe language and cause your machine to, for instance, crash, or your program to exhibit undefined behavior.
The same problems could of course occur simply by bugs in your WebAssembly runtime, even when sticking to pure WebAssembly.

On the other hand, the interface is carefully designed and hopefully carefully implemented as well.
And a program that cannot interact with the system on which it is executed is probably not a very useful program.
There is an obvious need for interaction.
So far, you have been interacting through a basic function call interace already.
Without this, you wouldn't be able to provide values or read results from the abstract WebAssembly stack machine.




### Hello world

To end this introduction, let's look at the simple *Hello, world!* example from the `wasmtime` [WASI Tutorial](https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-tutorial.md):

```wasm
(module
    ;; Import the required fd_write WASI function which will write the given io vectors to stdout
    ;; The function signature for fd_write is:
    ;; (File Descriptor, *iovs, iovs_len, nwritten) -> Returns number of bytes written
    (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

    (memory $mem 1)
    (export "memory" (memory $mem))

    ;; Write 'Hello, world!\n' to memory at an offset of 8 bytes
    ;; Note the trailing newline which is required for the text to appear
    (data (i32.const 8) "Hello, world!\n")

    (func $main (export "_start")
        ;; Creating a new io vector within linear memory
        (i32.store (i32.const 0) (i32.const 8))  ;; iov.iov_base - This is a pointer to the start of the 'hello world\n' string
        (i32.store (i32.const 4) (i32.const 14))  ;; iov.iov_len - The length of the 'hello world\n' string

        (call $fd_write
            (i32.const 1) ;; file_descriptor - 1 for stdout
            (i32.const 0) ;; *iovs - The pointer to the iov array, which is stored at memory location 0
            (i32.const 1) ;; iovs_len - We're printing 1 string stored in an iov - so one.
            (i32.const 24) ;; nwritten - A place in memory to store the number of bytes written
        )
        drop ;; Discard the number of bytes written from the top of the stack
    )
)
```

This example shows a few new concepts.
It defines a region of global memory.
Using the data command, the byte-representation of the string *Hello, World!\n* is written to this memory, starting at byte address 8.
Using `i32.store (i32.const 0) (i32.const 8)` the value 8 is written at byte addresses 0 - 3 in the defined memory (32 bit = 4 bytes). 
This value `8` of course represents the address in the same memory of the string *Hello, World!*.
At address `4` in memory, the length of the string is written.
The memory is thus prepared for a call to the system call `fd_write` defined in `WASI`.
Since the file descriptor `1` is chosen, the string is written to the `stdout`.


* **Exercise** In the Rust-module of CPL you were asked to implement *FizzBuzz*. We will ask you to do the same. Write a program that prints the numbers 1 to 100. For multiples of three, print *Fizz* instead of the number and for multiples of five print *Buzz*. For numbers which are multiples of both three and five, print *FizzBuzz*. 


# WebAssembly as a compilation target

Up until now we have been writing WebAssembly by hand.
Just like regular assembly, however, WebAssembly is mostly going to be used as a compilation target.

WebAssembly as a compilation target is supported by [`LLVM`](https://en.wikipedia.org/wiki/LLVM), making it possible to compile a wide variety of languages to WebAssembly.

This allows us to write programs in a wide variety of languages and execute these programs on our WebAssembly machine.


## WebAssembly from C

Using [`clang`](https://clang.llvm.org/) it is  possible to compile C programs to WebAssembly.
At the time of writing, however, the latest releases of `clang` do not yet support the WebAssembly System Interface. Without the System Interface it is only possible to compile pure C code that doesn't perform any system calls. 

Luckily, a special build of `clang` is available in the [`wasi-sdk`](https://github.com/WebAssembly/wasi-sdk).

On Ubuntu, the easiest way to install this version of `clang` would be to download a `.deb` installer from [the latest release](https://github.com/WebAssembly/wasi-sdk/releases/latest).
For other Linux and MacOS distributions you should be able to use the instructions on [their GitHub](https://github.com/WebAssembly/wasi-sdk).
Windows users will need to use [MinGW](http://www.mingw.org/), a release for MinGW is provided in the release page.

Once you have install clang, it is time to compile a simple *Hello, world!* program from C to WebAssembly.

```C
#include <stdio.h>
 
int main(){
    printf("Hello, world!\n");
} 
```
Now, compile it with your newly installed version of `clang`:

```bash
/opt/wasi-sdk/bin/clang hello_world.c -o hello_world.wasm
```
> :information_source: If you receive an error about `libtinfo.so.5` on Ubuntu, execute the command ```sudo apt install libtinfo5```.

> :information_source: If you are not on Ubuntu or performed a non-default install on Ubuntu, consult the Use instructions on the `wasi-sdk` [GitHub](https://github.com/WebAssembly/wasi-sdk).


We can confirm this works by executing our generated `wasm` file with `wasmtime`:

```bash
wasmtime hello_world.wasm 
Hello, world!
```

> :warning: Not all features of the C/C++ languages are supported. On the `wasi-sdk` [GitHub](https://github.com/WebAssembly/wasi-sdk) you can find some current limitations. The most notable one is probably support for multithreading. At the time of writing `WASI` does not yet include an interface for threading.

### Undefined behavior

In C it is possible to write some fun programs, for instance:

```c
#include <stdio.h>

int main(){
    int a = 0;
    int b = 0;
    int c = 0;
    int *p = &c;
    p -= 2;
    *p = 3;
    printf("(%p, %p, %p)\n", &a, &b, &c);
    printf("(%d, %d, %d)\n", a, b, c);
    return 0;
}
```
The output of this program compiled with `gcc` on my Ubuntu machine is as follows:
```bash
$ gcc fun.c -o fun
$ ./fun
(0x7fff65ca09e4, 0x7fff65ca09e8, 0x7fff65ca09ec)
(3, 0, 0)
```
The output on your machine might very well be completely different!
This program takes the address of a variable on the stack (`c`), modifies the address and writes to the new location.
On my machine this new modified address happened to correspond to the stack value `a`.
Funnily enough, if I *only* remove the *first* print statement I get the following output:

```bash
$ ./fun
(0, 0, 0)
```

Is this a bug in the `gcc` compiler?
No, this is completely intentional.
`gcc` is free to choose the order in which variables are pushed to the call stack.
It is the burden of the programmer to not write code that makes implicit assumptions about memory layouts.
The result the above C program all depends on choices the compiler is allowed to make.
This is a form of *undefined behavior*.
From a source code alone you cannot predict the output of this program.

> :bulb: What probably happens in gcc is that whenever we don't explicitly try to print the address of the local variables, it simply optimizes and keeps the local variables in registers. Thus, our random memory overwrite does not correspond to the stack value.

Let's see what happens if we compile to WebAssembly and execute our program:

```bash
$ /opt/wasi-sdk/bin/clang fun.c -o fun
$ wasmtime fun
(0x11278, 0x11274, 0x11270)
(0, 0, 0)
```
Interestingly enough, the call stack was not modified.
As you can see, however, our local variables were assigned addresses in decreasing order.
Let's flip the address math in our original C program and increment our pointer instead of decrementing:

```c
#include <stdio.h>

int main(){
    int a = 0;
    int b = 0;
    int c = 0;
    int *p = &c;
    p += 2;
    *p = 3;
    printf("(%p, %p, %p)\n", &a, &b, &c);
    printf("(%d, %d, %d)\n", a, b, c);
    return 0;
}
```

Trying this again:

```bash
$ /opt/wasi-sdk/bin/clang fun.c -o fun
$ wasmtime fun
(0x11278, 0x11274, 0x11270)
(3, 0, 0)
```

This works!
But, if you have been very attentive, this might alarm you.
Are we not directly overwriting values on our call stack?
That shouldn't be allowed in WebAssembly.
What if, instead of writing `p += 2`, we write `p += 3`.
Suddenly, aren't we overwriting values to which we should *never* have access to?

The answer is, luckily, no.
In this case, our C compiler used the WebAssembly heap to store these local variables, instead of the call stack.
When we use the `&`-operator on a local variable, a WebAssembly compiler has no choice but to allocate that local variable somewhere in the heap.
Stack variables in WebAssembly should be considered as having no address at all and they should be considered immmutable.
The only legal operations pop and push values to the stack according to the WebAssembly typing rules.

C compilers have a lot of freedom when translating C programs.
They only have to adhere to the C specifications, and a lot of behavior is left undefined.
Whenever behavior is undefined at the source level, a compiler is free to choose specific behavior for that code.

WebAssembly will *not* help with this in any way.
It is not a silver bullet.
The compiled WebAssembly program will have defined behavior (excluding these [exceptions])(https://github.com/WebAssembly/design/blob/master/Nondeterminism.md) but it might not behave exactly as the programmer expected when writing the source C program.

A lot of this unpredictable behavior is solved by recent languages such as Rust, as you've seen in the other module of CPL.

* **Exercise** Try to come up with a program that has a different output when you compile it to WebAssembly (e.g. using `clang`) vs when you compile it to your native machine code (e.g. using `gcc`).


# WebAssembly in the browser

Most WebAssembly tutorials will start off with a *Hello, world!* program directly in the browser.
In this tutorial we've explicitly avoided this approach, to not distract from the core WebAssembly concepts.
As a replacement, we have used `wasmtime` to execute our `.wasm` programs.

While WebAssembly is not limited to the browser, its main use case today is most certainly high-performance web applications.
Using JavaScript it is possible to instantiate WebAssembly modules and call functions from these modules directly.

A [great online tool](https://webassembly.github.io/wabt/demo/wat2wasm/) to explore integration of JavaScript and WebAssembly can be found in the demo of the `wat2wasm` tool of the [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt).

* **Exercise** Call your own factorial function from JavaScript using WebAssembly. The easiest toolchain to use is probably the [`wat2wasm` demo](https://webassembly.github.io/wabt/demo/wat2wasm/).

## WebAssembly from AssemblyScript

If you want to write WebAssembly programs from scratch efficiently in a higher level language than C/C++, a great choice of language would be (`AssemblyScript`)[https://www.assemblyscript.org/].
This is a source language specifically designed for compilation to WebAssembly.
The syntax of the language is heavily inspired by [`TypeScript`](https://www.typescriptlang.org/).

Here's a quote from the `AssemblyScript` website about the language:
> One can think of it as if TypeScript and C had a somewhat special child

If you are writing applications for the browser, `AssemblyScript` can be considered a good alternative to `JavaScript`.
You should in general expect higher performance for CPU intensive computations.
More info about when to use `AssemblyScript` vs `JavaScript` can be found [here](https://www.assemblyscript.org/frequently-asked-questions.html#is-webassembly-always-faster).

A tool to easily explore `AssemblyScript` can be found in [`WebAssembly studio`](https://webassembly.studio/).
This online tool internally uses the [`binaryen`](https://github.com/WebAssembly/binaryen) WebAssembly toolchain to compile `AssemblyScript` to `WebAssembly`.

* **Exercise** Rewrite FizzBuzz in `AssemblyScript`. You can choose to use an online editor like [`WebAssembly studio`](https://webassembly.studio) or to install [`binaryen`](https://github.com/WebAssembly/binaryen) and execute compile your `AssemblyScript` manually.

# Want more?

* [Developers guide](https://webassembly.org/getting-started/developers-guide/)
