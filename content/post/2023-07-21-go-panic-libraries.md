---
title: "Golang panics in libraries"
description: "Should we panic in libraries? And why not?"
author: "Anton Ohorodnyk"
date: "2023-07-21T21:32:14-07:00"
type: "post"
---

## Introduction

When I read about [Golang][golang] for the first time, I was an active user of languages with exceptions, like [Java](https://openjdk.org/), [PHP](https://php.net/), [Python](https://www.python.org/), [Ruby](https://www.ruby-lang.org/en/), etc.

It was obvious that big projects handles their behaviour through exceptions and we can control flow through `try/catch` blocks in parent call stack.

Outside languages with exceptions I had some experience with other languages like [C](https://en.wikipedia.org/wiki/C_(programming_language)) or codebases that prohibit exceptions.

Experience without exceptions, usually was less pleasant, because it applied many restrictions and limitations to the codebase.
Additionally, amny of these codebases did not support return for multiple values, so the flow control had to be built through returnin unsupported values (like `-1` for `int`s and null for references).
Because of these limitations, there were popular ways to handle these restrictions through reference parameters and *returning* results through them.

## Golang

There we are! We have met [Golang][golang] Golang for the first time.
The documentation and articles and bool suggest to use `error` return value, instead of exceptions. More over, exceptions are not supported in Golang at all.

By going through [Golang][golang] documentation and the codebase, everypone

[golang]: https://golang.org/
