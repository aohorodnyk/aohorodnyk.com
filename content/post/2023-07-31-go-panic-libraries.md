---
title: "Golang panics in libraries"
description: "Should we panic in libraries? And why not?"
author: "Anton Ohorodnyk"
date: "2023-07-31T21:32:14-07:00"
type: "post"
---

## Introduction

When I read about [Golang][golang] for the first time, I was an active user of languages with exceptions, like [Java][java], [PHP][php], [Python][python], [Ruby][ruby], etc.

It was obvious that big projects handle their behaviour through exceptions and we can control flow through `try/catch` blocks in parent call stack.

Outside languages with exceptions I had some experience with other languages like [C][clang] or codebases that prohibit exceptions.

Experience without exceptions, usually was less pleasant, because it applied many restrictions and limitations to the codebase.
Additionally, many of these codebases did not support return for multiple values, so the flow control had to be built through returning unsupported values (like `-1` for `int`s and null for references).
Because of these limitations, there were popular ways to handle these restrictions through reference parameters and *returning* results through them.

## Golang

There we are! We have met [Golang][golang] for the first time.
The documentation and articles and bool suggest to use `error` return value, instead of exceptions. More over, exceptions are not supported in Golang at all (or almost).

By going through [Golang][golang] documentation and the codebase, many people notice that there is a `panic` with `recover`, that can be used as exceptions. These people write many articles, posts, and comments about how `panic`s in [Go][golang].
But [Golang][golang] community always criticizes these thoughts and suggests to use `error` returned value instead of `panic`. Moreover, those people share an opinion that `error` handling in [Golang][golang] is much better than exceptions in other languages.

Let's try to understand why it is so.

## Error handling

Before we will compare exceptions and error handling from [Golang][golang], let's try to go through the main ways to handle errors.

There are three of them:

* Return error from the function.
* Throw error through current stack of calls until someone will catch it.
* Stop execution of the program.

All these ways are used in many different languages in parallel and non of them is better than others.

### Return error from the function

This way is the first way I've seen when I started to learn programming in [C][clang] and [Assembly][asm]. It is the most obvious way to handle errors, because we can just agree that some special value will be returned in case of error. In case of C it is `-1` for `int`s and `NULL` for references. Sometimes it cam be some `error` parameter that will be filled with error value by reference.

The best thing about this way is that it is very simple and easy to understand. It increases readability of the code and makes it easy to debug by printing a value or putting debugger on the line to see the scope of variables.
In case of C it was kinda confusing, since we did not have predictable way to work with errors and we had to check the documentation of each function to understand how it handles errors.

In case of *modern* languages like [Golang][golang], [Rust][rust], etc. we have a predefined way to work with error handling by specific `error` types and rules on how to use them. It improves readability and simplifies interfaces of functions.

Basically all of the changes around it are just cosmetic that make huge difference, but concept is still the same.

![Return error flow diagram](/post/go-panic-libraries/return-error-flow.svg)

In the diagram above we can see the flow of the program that uses this approach to handle errors.
Short explanation of the diagram:

* `main` function calls `func1` function.
* `func1` function calls `func2` function.
* `func2` function returns an error.
* `func1` function checks return values from `func2` function and returns an error based on `error` from `func1`.
* `main` function checks return values from `func1` function and handles the `error`.
* `main` function can continue execution of the program.

The main idea of this approach a software developer should handle errors in each function in the call stack. And they can handle errors on any level of the call stack. If we do not know what to do on a specific level, we can just return an error to the caller and let them handle it.

#### Pros

* Easy to understand.
* Easy to debug.
* Easy to use.

#### Cons

* In some cases this approach adds a boilerplate code.
* We need to thing about error handling in each call of a function.
* Every function in the call stack should handle errors and return them back to the caller, if needed.
* It can be simple to ignore an error without adding any handling for it.

This handle of errors is used to guarantee that an error won't be ignored and developer will always aware about an error.

### Throw error through current stack of calls until someone will catch it

The main idea of this approach is to throw an error from a function up to callers stack until someone will catch it.
This way is the most popular way to handle errors in languages with exceptions like [Java][java], [PHP][php], [Python][python], [Ruby][ruby], etc.

By using this approach we can send a `error` through call stack without adding any code and knowledge to intermediate levels. It simplifies development and removes requirements to thing about errors on the most levels of the call stack.

Languages that support exceptions have a special keyword to throw an exception and to catch it.

* In case of [Java][java] and [PHP][php] it is `throw` and `try/catch` blocks.
* In case of [Python][python] it is `raise` and `try/except` blocks.
* In case of [Ruby][ruby] it is `raise` and `begin/rescue` blocks.

But all of them have the same idea to control the execution flow: throw an exception and catch it on the level where we want handle it.

With [Go][golang] it is a bit different. We do not have exceptions, but we have `panic` and `recover` functions.
Panics by themself are not control-flow statements, they are closer to [Java][java] `Error` type or [PHP][php] `ErrorException` type. They are used to stop execution of the program in case of critical errors that are not related to business flow of the program.
In case of [Go][golang] we can use `panic` to throw an error and `recover` to catch it, but we can catch it only in [defer](https://go.dev/tour/flowcontrol/12) functions that are not linear execution code block and applies some limitations on top of it.

![Throw exception flow diagram](/post/go-panic-libraries/exception.svg)

In the diagram above we can find the flow of the program that uses this approach to handle errors.
Short explanation of the diagram:

* `main` function calls `func1` function.
* `func1` function calls `func2` function.
* `func2` function throws an `error`.
* `main` function catches an `error` and handles it.
* `main` function can continue execution of the program.

This way to handle errors is used to simplify code writing and to reduce boilerplate code on intermediate levels of the call stack.

#### Pros

* Easy to write new code.
* Zero boilerplate code on intermediate levels of the call stack.

#### Cons

* It is hard to understand where an error was thrown.
* It is hard to debug.
* It is hard to understand where an error will be caught, if it will be caught at all.
* If error was not caught, the program will be stopped during an execution.

### Stop execution of the program

The most radical way to handle errors is to stop execution of the program in case of any error.
In the most languages it is done by using `exit` function that stops execution of the program and returns an error code to the caller.
To handle errors there `assert` function that checks a condition and stops execution of the program if it is not met.

There is no way to recover the execution of the program after `exit` or `assert` functions were called. The one way error handling is used to stop execution in case of some critical errors that are not related to business flow of the program, but they also cannot be handled by the program.

The simplest example of such error is a unsupported value of a parameter in command line interface. In this case we can just stop execution of the program and print an error message to the user.

![Stop execution flow diagram](/post/go-panic-libraries/stop-execution.svg)

Let's review the flow of the program that uses this approach to handle errors. The diagram above shows the flow. In this diagram we added **OS level** that represents the operating system that runs the program from an [entry point](https://en.wikipedia.org/wiki/Entry_point)[^entry_point].

Short explanation of the diagram:

* `os` calls an entry point of a program, usually by calling the `main` function.
* `main` function calls `func1` function.
* `func1` function calls `func2` function.
* `func2` function checks a condition and stops execution of the program.
* `os` receives an error code from the program and handles it and stops execution.

This approach is used to stop execution of the program in case of critical errors that are not related to business flow of the program.

#### Pros

* Easy to stop an execution of the program.
* Guarantees that the program will not continue execution in case of critical errors.
* Application will stop very fast.

#### Cons

* Since the program stops execution with a code, it is hard to debug without logs.
* The program stops execution, that is not what we usually want.

## Panic and recover in Go

We went through different ways to handle errors in the program. We have successfully reviewed the flows and pros and cons of each approach.
During the review we also mentioned that [Go][golang] supports all of them, but it's important to jump a little bit deeper into it.

### Error type in Go

[Go][golang] has a special interface to represent an error. It is called `error` and it is defined in the [builtin package](https://golang.org/pkg/builtin/#error).
```go
type error interface {
	Error() string
}
```

We can use this interface to define our own error types and to use them in our programs.
```go
// NewMyError factory method that creates a new MyError.
func NewMyError(message string) error {
  return &MyError{message: message}
}

type MyError struct {
  message string
}

func (e *MyError) Error() string {
  return e.message
}
```

The `error` type is expected to be the latest return value of a function.
```go
func func1() error {
  return NewMyError("error message")
}

func func2() (int, string, bool, error) {
  return 0, "", false, NewMyError("error message")
}
```

And we also expect that the caller will check the error and handle it. There is a popular linter that checks it for us: [errcheck](https://github.com/kisielk/errcheck).

Also, errors can be stacked in a chain, wuth two interfaces:
```go
interface {
  Unwrap() error
}

interface {
  Unwrap() []error
}
```

With [errors](https://pkg.go.dev/errors) package that contains useful helpers to work with errors.

Errors is the main way to handle errors in [Go][golang] and it is used in most of the cases and suggested to be used when possible.

> Note: If you can use `error` type, use it. Do not even thing to use any other error handling approaches.

### Panic and recover

We went through *throw error* handling flow. Although exceptions are very popular in other languages, [Go][golang] does not support them.
In [Go][golang] we have `panic` and `recover` functions that are used to handle critical errors.

The code that uses `panic` usually means that something went wrong, very wrong.
When we throw `panic` we stop execution of current code and start to unwind the stack of the program, with no call stack code execution.
But all defers are still executed, even for functions that are not expecting to handle panics.
We will see it in the following example.

```go
package main

import "fmt"

func main() {
	defer func() { fmt.Println("Defer main") }()
	fmt.Println("Hello world")

	func1()

	fmt.Println("Not executed code main")
}

func func1() {
	defer func() { fmt.Println("Defer func1") }()

	func2()

	fmt.Println("Not executed code func1")
}

func func2() {
	defer func() { fmt.Println("Defer func2") }()

	panic("Test panic")

	fmt.Println("Not executed code func2")
}

// Output:
// Hello world
// Defer func2
// Defer func1
// Defer main
// panic: Test panic
//
// goroutine 1 [running]:
// main.func2()
// 	/tmp/sandbox493636343/prog.go:26 +0x49
// main.func1()
// 	/tmp/sandbox493636343/prog.go:19 +0x3f
// main.main()
// 	/tmp/sandbox493636343/prog.go:11 +0x7d
//
// Program exited.
```

Since we are using `panic` in `func2` function, we stop execution of the program and start to unwind the stack. All `defer`s are executed from `func2`, `func1` and `main`. Because we have not `recover`ed from the panic, the program stops execution and prints a panic message with stack trace.

We can use `recover` to handle panics and sometimes we will, but as good practice let's agree that we will not use `panic`s as a control flow of the program.

### Stop execution

Sometomes we want to just stop execution of the program. For example, we have a program that is a CLI tool and we want to stop execution of the program if the user provided wrong parameters.

We can use `os.Exit` to stop execution of the program.
```go
package main

import (
  "fmt"
  "os"
)

func main() {
  if len(os.Args) < 2 {
    fmt.Println("Please provide a name")
    os.Exit(1)
  }

  fmt.Println("Hello", os.Args[1])
}

// > ./main test
// Hello test
// > ./main
// Please provide a name
// exit status 1
```

`os.Exit` will close program emidiately and will not execute any `defer`s. This way is even more dangerous than `panic` and should be used only in cases when we know what do we do.

> Note: Do not use `os.Exit` unless you know what you are doing.

## Panic in libraries

Finally, let's talk about panics in libraries. We have already mentioned that we should not use `panic` as a control flow of the program.
But, why are libraries so unique?

Libraries are created to be used by other programs and people.
When people use libraries, they expect that the library will not stop execution of the program.
If there are any errors, library will return an error and the caller will know about it based on the interface and can handle it.

This approach helps to be sure that even without careful reading of the documentation, the caller will not be surprised by the behavior of the library. And it is a good practice to follow.
Error handling through return value helps to be [Go][golang] code more predictable and stable. This simple rule helps to make programs to be unfailable on production.

### One exception and informal agreement

Although we have a rule that we should not use `panic` in libraries, there is one exception.
Sometimes libraries return `error` value and we know that caller in the most cases will not handle it and just panic.

There are some examples:

  1. `regexp.Compile` - it is expected that the caller will provide a valid regular expression.
      * If the regexp is set in constant code `regexp.Compile("invalid regexp")`, we will just panic and fix the code.
      * If the regexp is provided as an input from the user, we should handle the error ro notify user and move forward with execution.
  2. `uuid.NewRandom` ([source code](https://github.com/google/uuid/blob/655bf50db9d265813a26b0fe2a5d1e80fb9e3c6b/version4.go#L13-L15))
     Where we create a random UUID generator. If we have a problem with the random generator, it will return an error.
      * In the most cases we will panic, because we expect that random generator will work.
      * In some cases we will handle the error and use some fallback generator (for example from an external service).

As you can see, there are some cases when we expect from the caller to panic in the most cases of using a library.
We **ALWAYS** provide the interface with `error` returned as a value, but since we know that in the most cases the caller will not handle the error, we can provide a *helper* function that will panic in case of error.

Let's see an example:
```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	fmt.Println(Compile("test"))     // Will return "test".
	fmt.Println(Compile(""))         // Will return the error.
	fmt.Println(MustCompile("test")) // Will return "test".
	fmt.Println(MustCompile(""))     // Will panic
}

func Compile(regexp string) (string, error) {
	if regexp == "" {
		return "", errors.New("critical error, empty regexp")
	}

	return regexp, nil
}

func MustCompile(regexp string) string {
	res, err := Compile(regexp)
	if err != nil {
		panic(err)
	}

	return res
}

// Output:
// test <nil>
//  critical error, empty regexp
// test
// panic: critical error, empty regexp
//
// goroutine 1 [running]:
// main.MustCompile(...)
// 	/tmp/sandbox2091129551/prog.go:26
// main.main()
// 	/tmp/sandbox2091129551/prog.go:12 +0x178
//
// Program exited.
```

There is a good practice or/and agreement that if we have a helper-function that throws a panic, we should name it with `Must` prefix. For example: `MustCompile`, `MustNew`, `MustOpen` and so on.

> Note: Do not use `panic` in libraries except you provide a helper function with `Must` prefix.

## Conclusion

In [Go][golang] we have all tools to handle errors. But the preferrable way to use errors is to return them as a value and handle them in the caller code.

If a developer of a library expects that in the most cases the caller will not handle the error, they can provide a helper function with `Must` prefix that will panic in case of error. But the main interface of the library **MUST** still return an error.

Let's follow good practices and make our code more stable and predictable.

[golang]: https://golang.org/
[rust]: https://www.rust-lang.org/
[java]: https://openjdk.org/
[php]: https://www.php.net
[python]: https://www.python.org/
[ruby]: https://www.ruby-lang.org/en/
[clang]: https://en.wikipedia.org/wiki/C_(programming_language)
[asm]: https://en.wikipedia.org/wiki/Assembly_language

[^entry_point]: In computer programming, an entry point is the place in a program where the execution of a program begins, and where the program has access to command line arguments.
