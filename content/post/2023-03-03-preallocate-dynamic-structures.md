---
title: "Preallocate dynamic structures"
description: "Some dynamic structures can and should be preallocated"
author: "Anton Ohorodnyk"
date: "2023-03-03T19:30:35-08:00"
type: "post"
---
## Introduction

We live in a beautiful software development time, where every language contains dynamic structures. Therefore, we can think about only some memory allocation.
Differences between development performance are significantly decreasing between statically and dynamically typed languages.

We can write code on Go, Kotlin, Java, etc., almost like we write on statically typed languages like Python, JavaScript, PHP, etc. Of course, it's impressive, but let's discuss some things that can help us improve performance in a small, easy step.

This short article will explain why preallocation is beneficial, even for dynamic structures.

## Simplification in statically typed languages

The significant difference between statically typed languages and dynamically typed languages is mainly based on three main differences:

1. Memory management
2. Verbosity
3. Type conversion

Verbosity and type conversion parts will discuss in future articles. However, memory management is the topic we will discuss right now.

### Memory management

When dynamic languages were involved, all static languages required co-manage memory manually. Every developer had to consider array sizes, resizing, memory cleaning, etc.

Currently, every language (including C++) provides a way how to almost or entirely avoid memory management in these ways:

* Reference counters
* Garbage collectors

So, if we are doing right, we can use some `slice`[^slice], `ArrayList`, `vector` (similar structures from different languages), etc., to work with dynamic arrays.
So, in the current world, we can append whatever amount of data we want to build a `slice`[^slice].

Example with an array:

```go
package main

import "fmt"

func main() {
	const size = 10

	arr := [size]int{}
	fmt.Println(arr) // [0 0 0 0 0 0 0 0 0 0]

	for i := 0; i < size; i++ {
		arr[i] = 333
	}

	fmt.Println(arr) // [333 333 333 333 333 333 333 333 333 333]
}
```

The above example shows that we had a fixed array size where we could not add the eleventh element without some manipulations.

Example with a dynamic array data structure (`slice`[^slice] from Go):

```go
package main

import "fmt"

func main() {
	const size = 10

	arr := []int{}
	fmt.Println(arr) // []

	for i := 0; i < size; i++ {
		arr = append(arr, 333)
	}

	fmt.Println(arr) // [333 333 333 333 333 333 333 333 333 333]
}
```

As we can see, we created a slice with zero sizes. After that, we extended it from zero elements up to 10. After that, we had no issues adding one or hundreds of more pieces.

## Performance improvements

As we saw above, dynamic structures like `slice`[^slice] improve our life quality and help us write code comparably fast as on dynamic languages.

The example above provided an example where we created a slice with 0 sizes and allocated it up to ten elements. However, there is a minor performance issue here. However, we knew the expected size (in our use case, it was ten elements), so we could preallocate the slice and improve performance.

Let's create a small benchmark to see the difference between preallocated and non-allocated slices in Go:

```go
package slices_test

import (
	"testing"
)

func BenchmarkNonAllocated(b *testing.B) {
	slice := []int{}
	// run the allocate variable b.N times
	for n := 0; n < b.N; n++ {
		slice = append(slice, 333)
	}
}

func BenchmarkPreAllocated(b *testing.B) {
	slice := make([]int, 0, b.N)
	// run the allocate variable b.N times
	for n := 0; n < b.N; n++ {
		slice = append(slice, 333)
	}
}
```

Running result:

```bash
$ go test -benchmem -bench . github.com/aohorodnyk/gox/slices -benchtime=20s
goos: darwin
goarch: arm64
pkg: github.com/aohorodnyk/gox/slices
BenchmarkNonAllocated-8         1000000000              14.52 ns/op           42 B/op          0 allocs/op
BenchmarkPreAllocated-8         1000000000               3.918 ns/op           8 B/op          0 allocs/op
PASS
ok      github.com/aohorodnyk/gox/slices        19.872s
```

In the result, we can see that performance improvement is ~3.7 times.

## Conclusion

This article needs to describe how slices, ArrayList, or similar data structures work. Then, it's simple to find in your favorite search engine.

Meanwhile, this article imperatively shows that preallocation significantly improves performance. In the article, we touched only *dynamic arrays*, but it can be applied to every type like `slice`[^slice], `map` (`hash map`), etc.

Our applications can handle millions of requests. So if we can improve performance for every request ONLY by this improvement, it will be a massive step for us.

It's a small part of the improvement. We will discuss other options in future articles as well.

[^slice]: Some high-level internals about slices can be [read here](https://go.dev/blog/slices-intro).
