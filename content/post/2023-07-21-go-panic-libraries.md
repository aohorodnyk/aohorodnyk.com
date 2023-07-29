---
title: "Golang panics in libraries"
description: "Should we panic in libraries? And why not?"
author: "Anton Ohorodnyk"
date: "2023-07-21T21:32:14-07:00"
type: "post"
---

## Introduction

When I read about [Golang][golang] for the first time, I was an active user of languages with exceptions, like [Java][java], [PHP][php], [Python][python], [Ruby][ruby], etc.

It was obvious that big projects handles their behaviour through exceptions and we can control flow through `try/catch` blocks in parent call stack.

Outside languages with exceptions I had some experience with other languages like [C][clang] or codebases that prohibit exceptions.

Experience without exceptions, usually was less pleasant, because it applied many restrictions and limitations to the codebase.
Additionally, amny of these codebases did not support return for multiple values, so the flow control had to be built through returnin unsupported values (like `-1` for `int`s and null for references).
Because of these limitations, there were popular ways to handle these restrictions through reference parameters and *returning* results through them.

## Golang

There we are! We have met [Golang][golang] for the first time.
The documentation and articles and bool suggest to use `error` return value, instead of exceptions. More over, exceptions are not supported in Golang at all.

By going through [Golang][golang] documentation and the codebase, many people notice that there is a `panic` with `recover`, that can be used as an exception. These people write many articles, posts, and comments about how bad it is to use `panic` in libraries and how it is useful.
But [Golang][golang] community always criticizes these people and suggests to use `error` instead of `panic`. Moreover, those people share an opinion that `error` handling in [Golang][golang] is much better than exceptions in other languages.

Let's try to understand why it is so.

## Error handling

Befoer we will compare exceptions and error handling from [Golang][golang], let's try to go through the main ways to handle errors.

There are three the main ways to handle errors:

* Return error from the function.
* Throw error through current stack of calls until someone will catch it.
* Stop execution of the program.

All these ways are used in many different languages in parallel and non of them is better than others.

### Return error from the function

This way is the first way I've seen when I started to learn programming in [C][clang] and [Assembly][asm]. It is the most obvious way to handle errors, because we can just agree that some special value will be returned in case of error. In case of C it is `-1` for `int`s and `NULL` for references. Sometimes it cam be some `error` parameter that will be filled with error value by reference.

The best thing about this way is that it is very simple and easy to understand. It increases readability of the code and makes it easy to debug by printing a value or putting debugger on the line to see the scope of variables.
In case of C it was kinda confusing, since we did not have predictable way to work with errors and we had to check the documentation of each function to understand how it handles errors.

In case of *newer* languages like [Golang][golang], [Rust][rust], etc. we have a predefined way to work with error handling by specific `error` types and rules on how to use them. It improves readability and simplifies interfaces of functions.

#### Pros

* Easy to understand.
* Easy to debug.
* Easy to use.

#### Cons

* In some cases this approach adds a boilerplate code.
* We need to thing about error handling in each call of a function.
* Every function in the call stack should handle errors and return them back to the caller, if needed.

### Throw error through current stack of calls until someone will catch it

The main idea of this approach is to throw an error from a function up to callers stack until someone will catch it.
This way is the most popular way to handle errors in languages with exceptions like [Java][java], [PHP][php], [Python][python], [Ruby][ruby], etc.


[golang]: https://golang.org/
[rust]: https://www.rust-lang.org/
[java]: https://openjdk.org/
[php]: https://www.php.net
[python]: https://www.python.org/
[ruby]: https://www.ruby-lang.org/en/
[clang]: https://en.wikipedia.org/wiki/C_(programming_language)
[asm]: https://en.wikipedia.org/wiki/Assembly_language
