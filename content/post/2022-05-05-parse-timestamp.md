---
title: "Parse timestamp on backend"
description: "Parse timestamp from different clients and from different developers"
author: "Anton Ohorodnyk"
date: "2022-05-06T03:46:23Z"
type: "post"
mermaid: false
---
## Introduction

Have you ever had a situation when different clients send milliseconds in requests to a back-end that expects timestamp in seconds?

If not, you are lucky person. Unfortunately, it's so popular issue in my experience.
I even cannot count a number of bugs related to the specific issue.

Every time we find this issue on a client, we need to find the best on how to solve it.
If a front-end is web-site, it's littery not an issue and can be simply fixed and redeliver to all users in short period of time.
But, if the front-end is a client application, it could be much more complicated to redeliver the fix to all clients in some predictable period of time.

In my point of view the best way to fix the issue in this specific situation is to fix everything on backend and support two different types of payload.
We have predictable time expectations when we can fix the issue, we know how can we deliver the fix to ALL users, etc.

In the current example when we expect to receive the unix timestamp in seconds, but receive it in milliseconds.
We can fix it by adding support for both possible values to our parser.

Moreover, we know about the situations when a client sets the RFC3339 as a string field type, instead of int with a timestamp.

So, we have fixed the issues for our production, let's relax.
But, as we discussed, this issue have happened multiple time, let's try to think about the solution to prevent this issue in future?

> I'll use [Golang](https://go.dev/) for all code examples, but you can use any other language base on the provided algorithm.

## Issue overview

Before we will start writing code, we need to understand the issue.

### Expectations

There are our expectations:

1. We have an `int64` field where we expect to receive the unix timestamp in seconds.
1. We expect to see always possitive int numbers in this field.
1. Our expectation is to see the timestamp in a range of dates and times between `current time - 3 days` and `current time + 3 days`.
1. We use a language with strict type checking. We accept ONLY int value in our JSON field.

### Issue identification

What do we unexpectedly see in our stored data or logs:

1. Instead of `2022-05-05T10:43:27-07:00` we see `54312-08-04T05:24:35-07:00` in our storage.
1. Instead of processed requests we see some errors in logs that JSON could not be parsed, because of string provided in a field, instead of expected int.

### Possible wrong formats

After some investigation we found that the both issues are related to the following wrong values:

1. We see in the storage the future date `54313-06-15T01:03:45Z`, instead of the current date `2022-05-06T01:16:23Z`, because of the client used milliseconds instead of seconds during timestamp generation.
1. We see in logs an error that JSON could not be parsed, because of string provided in a field, instead of expected int, because of the client sent us some string value in the field.
    1. The client set the timestamp in a string field, instead of int, during JSON generation.
    1. The client sent us the date time in an `RFC3339` format, instead of unix timestamp in seconds.
    1. The client used some other date time format to send us the date time.

### Issue solving steps

Based on our investigation to fix the issue for the most future cases we need to do these fixes:

1. Add support of all possible values for our timestamp field: `seconds`, `milliseconds`, `microseconds`, `nanoseconds`.
1. Add support of the timestamp field in a string type (we will not solve it in this article).
1. Add support of the date time formats like: `RFC3339`, `RFC3339Nano`, etc (we will not solve it in this article).

### Known limitations

1. In this document we will use Golang language for all code examples.
1. We will solve the issue with write the functions that will parse .
1. As we are fixing the specific use case with a timestamp, we are not going to support all range of possible date times.
    1. We will surely support the range between `1970-04-17T18:02:52Z` and `2262-04-11T23:47:16Z` years.
    1. If you need dates after `2262-04-11T23:47:16Z` year or before `1970-04-17T18:02:52Z`, you will need to adjust the solution for your specific use case.
    1. We are not going to support negative timestamp. All of them will be parsed as a timestamp in seconds. If you need the negative numbers, you can adjust the solution with the same algorithm.
1. We will solve only timestamp parsing issue, without string dates parsing.

[^is_the_most_popular]: I do not have any statistics that proves this claim. These words are based on my own experience.

Looks like we are done with the issue formalization, let's move to the implementation side.

## Solution

To write the code we need to understand on how the timestamp works with different time formats.
What can we use and how to identify the edges of the time range?

First of all let's try to understand on how timestamp for different time formats works.

### Timestamp

[Timestamp](https://en.wikipedia.org/wiki/Unix_time) is a number of seconds since January 1, 1970 UTC.
To use more granular time we just add more digits to the timestamp. For example, to store a timestamp in milliseconds we add 3 digits to the timestamp (multiple seconds to 1000 to get milliseconds).

All modern implementation for the timestamp format uses `int64` type, to solve the issue of 2038 year's problem[^y2k38].
Tht meximum date for `int64` is `292277026596-12-04T15:30:07Z`. We can assume that we will never met this limit.

To collect data in milliseconds, microseconds and nanoseconds we uses `int64` as well in many cases.
The max date time for `int64` is `2262-04-11T23:47:16Z`.
It's too far in the future to be a problem as well.

[^y2k38]: Year 2038 is the problem when the max value of `int32` in seconds will be reached on `2038-01-19T03:14:07Z`.

### Golang introduction

So, now we know how the timestamp works, but what the next?

Before we will start, let's see on how to parse dates in Golang, if we are going to work with this language in the further steps.

In Golang we use the [time](https://pkg.go.dev/time) package to parse dates and times.

To convert `int64` timestamp in seconds to `time.Time` we use the [time.Unix(int64, 0)](https://pkg.go.dev/time#Unix) function. Let's convert `int64` timestamp in seconds to `time.Time` and print it in RFC3339 format.

```go
package main

import "time"

func main() {
  t := time.Unix(1651804700, 0) // Convert inte64 timestamp in seconds to time.Time
  str := t.Format(time.RFC3339) // Convert time.Time to RFC3339 format in string.
  println(str)                  // 2022-05-05T19:38:20-07:00
```

Now let's see how to print the same timestamp in nanoseconds.

```go
package main

import "time"

func main() {
  nanosecondMultiplier := int64(time.Second)
  t := time.Unix(0, 1651804700*nanosecondMultiplier) // Convert inte64 timestamp in seconds to time.Time
  str := t.Format(time.RFC3339)                      // Convert time.Time to RFC3339 format in string.
  println(str)                                       // 2022-05-05T19:38:20-07:00
```

All timestamps in microseconds and milliseconds we will convert to nanoseconds and use the sacond example to parse it.

### Identify the edges of the time range

We already know how to parse the dates, but the question, how to identify the edges of the time range?

The simplest solution would be just to parse the timestamp in a loop and check the timeframes to identify the right date time.
We will parse numbers as nanoseconds and if the number less than the magic year (let's choose 1980), then divide it by 1000 and try again. Let's see the code:

```go
package main

import "time"

func main() {
  timestamp := int64(1651804700000) // timestamp in milliseconds.
  for timestamp > 0 { // If int will overflow, we will get 0.
    t := time.Unix(0, timestamp) // Try to parse the timestamp in nanoseconds.
    if t.Year() > 1980 && t.Year() < 2100 {
      println(t.Format(time.RFC3339)) // Print the timestamp in RFC3339 format.

      return // Exit the loop.
    }

    timestamp *= 1000 // Try to convert to the next level (seconds -> milliseconds -> microseconds -> nanoseconds) and try again.
  }
}
```

It will work, but this algorithm is not the most efficient, because of:

* It can go overflow.
* We do multiple covertions int to time.
* We perform multiple calculations.
* We need to choose more accurate magic years.

### Efficient solution

First of all, instead of multiple calculations we can precalculate the most efficient timestamps and just verify with them.
And if we find the required range, do one time calculation.

To find the most efficient timestamps, let's try to find the maximum year we can effort with the most granular format.
Our the most granular format is nanoseconds. Let's see:

```go
package main

import (
  "time"
  "math"
)

func main() {
  timestamp := int64(math.MaxInt64) // Maximum available timestamp.
  t := time.Unix(0, timestamp) // Parse the maximum timestamp.
  println(t.Format(time.RFC3339)) // 2262-04-11T23:47:16Z
  println(timestamp) // 9223372036854775807
}
```

As we can see the maximum available `int64` timestamp is `9223372036854775807` and it equals to `2262-04-11T23:47:16Z` date time.

Based on our previous knowledge if we will devide this number by 1000 we will get the next less granular format.
Let's see it in the example:

```go
package main

import (
  "math"
  "time"
)

func main() {
  nano := int64(math.MaxInt64)
  micro := int64(nano / 1000)
  milli := int64(micro / 1000)
  sec := int64(milli / 1000)

  // Print all timestamps.
  println("seconds: ", sec)        // seconds:  9223372036
  println("milliseconds: ", milli) // milliseconds:  9223372036854
  println("microseconds: ", micro) // microseconds:  9223372036854775
  println("nanoseconds: ", nano)   // nanoseconds:  9223372036854775807

  // Parse seconds.
  println(time.Unix(sec, 0).UTC().Format(time.RFC3339)) // 2262-04-11T23:47:16Z
  // Parse seconds by converting it to nanoseconds.
  println(time.Unix(0, sec*int64(time.Second)).UTC().Format(time.RFC3339)) // 2262-04-11T23:47:16Z
  // Let's see what time will we see if we try to parse the seconds as milliseconds.
  println(time.Unix(0, sec*int64(time.Millisecond)).UTC().Format(time.RFC3339)) // 1970-04-17T18:02:52Z
  // Parse milliseconds.
  println(time.Unix(0, milli*int64(time.Millisecond)).UTC().Format(time.RFC3339)) // 2262-04-11T23:47:16Z
  // Let's see what time will we see if we try to parse the milliseconds as microseconds.
  println(time.Unix(0, milli*int64(time.Microsecond)).UTC().Format(time.RFC3339)) // 1970-04-17T18:02:52Z
  // Parse microseconds.
  println(time.Unix(0, micro*int64(time.Microsecond)).UTC().Format(time.RFC3339)) // 2262-04-11T23:47:16Z// Let's see what time will we see if we try to parse the microseconds as nanoseconds.
  println(time.Unix(0, micro).UTC().Format(time.RFC3339)) // 1970-04-17T18:02:52Z
  // Parse nanoseconds.
  println(time.Unix(0, nano).UTC().Format(time.RFC3339)) // 2262-04-11T23:47:16Z
}
```

As we can see the simple and pretty efficient solution is to just base max timestamps on max int64.
Let's write the function that will efficiently parse the timestamps independent of the format.

```go
package main

import (
  "math"
  "time"
)

const (
  maxNanoseconds  = int64(math.MaxInt64)
  maxMicroseconds = int64(maxNanoseconds / 1000)
  maxMilliseconds = int64(maxMicroseconds / 1000)
  maxSeconds      = int64(maxMilliseconds / 1000)
)

func main() {
  now := time.Now()
  sec := time.Now().Unix()
  rfc := parseTimestamp(sec).UTC().Format(time.RFC3339)
  println(sec) // 1651808102
  println(rfc) // 2022-05-06T03:35:02Z

  millisec := now.UnixMilli()
  rfc = parseTimestamp(millisec).UTC().Format(time.RFC3339)
  println(millisec) // 1651808102363
  println(rfc)      // 2022-05-06T03:35:02Z

  microsec := now.UnixMicro()
  rfc = parseTimestamp(microsec).UTC().Format(time.RFC3339)
  println(microsec) // 1651808102363368
  println(rfc)      // 2022-05-06T03:35:02Z

  nanosec := now.UnixMicro()
  rfc = parseTimestamp(nanosec).UTC().Format(time.RFC3339)
  println(nanosec) // 1651808102363368
  println(rfc)     // 2022-05-06T03:35:02Z
}

func parseTimestamp(timestamp int64) time.Time {
  switch {
  case timestamp < maxSeconds:
    return time.Unix(timestamp, 0)
  case timestamp < maxMilliseconds:
    return time.Unix(0, timestamp*int64(time.Millisecond))
  case timestamp < maxMicroseconds:
    return time.Unix(0, timestamp*int64(time.Microsecond))
  case timestamp < maxNanoseconds:
    return time.Unix(0, timestamp*int64(time.Nanosecond))
  }

  return time.Time{}
}
```

## Conclusion

In this article we solved a real-world problem, surely affected more than one person.
I hope this solution will help someone to improve their product and improve user-experience of their API.

Do not forget, that every complicated problem can be solved with a simple and efficient[^efficient] solution.

[^efficient] By efficient I mean that the solution has efficient cpu and memory consumption. It will help to save money, improve user and developer experience as well as saving the world by decreasing electrycity consumption.
