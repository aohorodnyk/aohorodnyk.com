---
title: "Parse time from different non timestamp formats"
description: "Parse timestamp from different clients and from different developers"
author: "Anton Ohorodnyk"
date: "2022-05-07T20:48:20-07:00"
type: "post"
aliases: ["/post/2022-05-06-parse-time-strings/"]
---
## Introduction

In previous article, we implemented the efficient solution to parse timestamps in [different timestamp formats (seconds, milliseconds, microseconds, nanoseconds)]({{< ref "/post/2022-05-06-parse-timestamp" >}} "Parse timestamp formats").

As I mentioned in the previous article, we can receive a string formatted date time from a client, when we expected string timestamp in seconds.

Obviously we hardcoded some solution to support the specific format on a server (as we are expecting to find this issue on production with a production client), but we still would like to make it more universan and forget about the problem for a while.

Let's implement the solution!

> I'll use [Golang](https://go.dev/) for all code examples, but you can use any other languages base on the provided algorithm.

## Issue overview

Before we will start writing code, we need to understand the issue.

### Expectations

To simplify current task, let's assume that we have a string field and we need to write a function that will support a multiple time formats.

There are our expectations:

1. We have a string field where we expect to receive a RFC339 date time information.
1. Our expectation is to see the timestamp in a range of dates and times between `current time - 3 days` and `current time + 3 days`.
1. We use a language with strict type checking. We accept ONLY string value in our JSON field.

### Issue identification

What do we unexpectedly see in our logs:

* In the log we have found an error like `0001-01-01 00:00:00 +0000 UTC parsing time "Sat, 07 May 2022 19:22:10 PDT" as "2006-01-02 15:04:05": cannot parse "Sat, 07 May 2022 19:22:10 PDT" as "2006"`
* And also we have found this type of errors `0001-01-01 00:00:00 +0000 UTC parsing time "05/07 07:22:54PM '22 -0700" as "2006-01-02 15:04:05": cannot parse "7 07:22:54PM '22 -0700" as "2006"`

### Possible wrong formats

After some investigation we found the following formats used by clients:

* `time.Layout` from Golang -> `01/02 03:04:05PM '06 -0700`
* `RFC1123` with a format `Mon, 02 Jan 2006 15:04:05 MST`

It means that some our clients uses wrong standardized formats, instead of expected RFC3339.
As well with identified formats we assumed that clients could use some more different formats and we need to communicate with all our client teams or partners to identify all possible formats.

### Issue solving steps

Based on our investigation to fix the issue for the most future cases we need to do these fixes:

* Support the most popular formats.
* Design the extensible API to support for additional formats.
* Try do not overcomplicate the solution, for this article.

### Known limitations

* Surely this function will not support all possible formats, so, we will need to extend it with more formats, when needed.
* We will use only formats from the predefined list in standard Golang library.
* There are possible conflicts between different formats. The order of provided formats is important.

## Solution

Before we start writing code, we need to do some preparations.

1. Understand on how to parse the date time in Golang.
1. Find the list of supported formats in standard Golang library.
1. Implement the function.

### How to parse the date time in Golang

Fortunately, Golang supports pretty simple API to parse the date time from a string in different formats.
However, It has unusual layout's format.

To parse the date time, we need to use `time.Parse` function.

```go
package main

import (
  "fmt"
  "time"
)

func main() {
  now := time.Now()                                                 // Get current date time.
  parsed, err := time.Parse(time.RFC3339, now.Format(time.RFC3339)) // Parse current date time in RFC3339 format.
  fmt.Println(parsed, err)                                          // 2022-05-07 20:07:11 -0700 PDT <nil>
}
```

In the example above, we parse the current date time in `RFC3339` format that contains the layout `2006-01-02T15:04:05Z07:00`.
As we can see, in golang we use the specific time date as a layout to specify the format that we will parse.
It's unusual, but since we are not going to write our own formats, the task will not require detailed knowledge of these internal implementations.

As we can see, there are two different parameters returned from `time.Parse` function: `time` and `error`.
If `error` is nil, then we sucessfully parsed the date time, otherwise something went wrong.

Let's see an example with different formats:

```go
package main

import (
  "fmt"
  "time"
)

func main() {
  now := time.Now()                                                 // Get current date time.
  parsed, err := time.Parse(time.RFC3339, now.Format(time.RFC1123)) // Parse current date time in RFC3339 format.
  fmt.Println(parsed, err)                                          // 0001-01-01 00:00:00 +0000 UTC parsing time "Sat, 07 May 2022 20:09:12 PDT" as "2006-01-02T15:04:05Z07:00": cannot parse "Sat, 07 May 2022 20:09:12 PDT" as "2006".
}
```

As we can see in the output, we got an empty date time `0001-01-01 00:00:00 +0000 UTC` and an error `parsing time "Sat, 07 May 2022 20:09:12 PDT" as "2006-01-02T15:04:05Z07:00": cannot parse "Sat, 07 May 2022 20:09:12 PDT" as "2006"` about wrong format.

We will use this behavior to parse the date time in different formats.

### List of supported formats

As I mentioned before, we need to support all formats from the standard Golang library.

All supported formats are listed in the time package of the standard library. We can find it in [the documentation](https://pkg.go.dev/time#pkg-constants).

I'll list all supported formats in the current latest Golang version:

```go
package time

const (
  Layout      = "01/02 03:04:05PM '06 -0700" // The reference time, in numerical order.
  ANSIC       = "Mon Jan _2 15:04:05 2006"
  UnixDate    = "Mon Jan _2 15:04:05 MST 2006"
  RubyDate    = "Mon Jan 02 15:04:05 -0700 2006"
  RFC822      = "02 Jan 06 15:04 MST"
  RFC822Z     = "02 Jan 06 15:04 -0700" // RFC822 with numeric zone
  RFC850      = "Monday, 02-Jan-06 15:04:05 MST"
  RFC1123     = "Mon, 02 Jan 2006 15:04:05 MST"
  RFC1123Z    = "Mon, 02 Jan 2006 15:04:05 -0700" // RFC1123 with numeric zone
  RFC3339     = "2006-01-02T15:04:05Z07:00"
  RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00"
  Kitchen     = "3:04PM"
  // Handy time stamps.
  Stamp      = "Jan _2 15:04:05"
  StampMilli = "Jan _2 15:04:05.000"
  StampMicro = "Jan _2 15:04:05.000000"
  StampNano  = "Jan _2 15:04:05.000000000"
)
```

### Efficient solution

For implementation we will use the simplest possible algorithm:

1. Iterate over all supported formats.
1. Parse the receved string with the current format.
1. If the returned error is equal to `nil`, then we found the correct format. We can return from the function.
1. Otherwise, we need to continue the iteration.

The intermediate solution:

```go
package main

import (
  "fmt"
  "time"
)

func main() {
  t := time.Date(2022, time.May, 23, 7, 3, 5, 734423, time.UTC)

  fmt.Println(parseTime(t.Format(time.RFC3339))) // 2022-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(t.Format(time.RFC1123))) // 2022-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(t.Format(time.Layout)))  // 0001-01-01 00:00:00 +0000 UTC could not parse time: 05/23 07:03:05AM '22 +0000
}

func parseTime(dt string) (time.Time, error) {
  var formats = []string{
    time.RFC3339,
    time.RFC1123,
  }

  for _, format := range formats {
    parsedTime, err := time.Parse(format, dt)
    if err == nil {
      return parsedTime, nil
    }
  }

  return time.Time{}, fmt.Errorf("could not parse time: %s", dt)
}
```

In the code with the example we iterated over two formats: `RFC3339` and `RFC1123`. We wrote the test where we tried to parse three different formats with the same date time string. As we can see both supported formats are parsed correctly.

There is the limitation that we can recognize based on the above example: we can't parse sequantly formats that are sub-formats of the next format.
So, we need to be sure that we provide time layouts in the list formats from the most specific to the most general.

Implementing the function that will cover all requirements we already specified:

```go
package main

import (
  "fmt"
  "time"
)

func main() {
  // Specify all formats in the specific order.
  formats := []string{
    time.RFC3339Nano,
    time.RFC3339,
    time.RFC1123Z,
    time.RFC1123,
    time.RFC850,
    time.RFC822Z,
    time.RFC822,
    time.Layout,
    time.RubyDate,
    time.UnixDate,
    time.ANSIC,
    time.StampNano,
    time.StampMicro,
    time.StampMilli,
    time.Stamp,
    time.Kitchen,
  }

  t := time.Date(2022, time.May, 23, 7, 3, 5, 234734423, time.UTC)

  fmt.Println(parseTime(formats, t.Format(time.RFC3339Nano))) // 2022-05-23 07:03:05.234734423 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC3339)))     // 2022-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC1123Z)))    // 2022-05-23 07:03:05 +0000 +0000 <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC1123)))     // 2022-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC850)))      // 2022-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC822Z)))     // 2022-05-23 07:03:00 +0000 +0000 <nil>
  fmt.Println(parseTime(formats, t.Format(time.RFC822)))      // 2022-05-23 07:03:00 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.Layout)))      // 2022-05-23 07:03:05 +0000 +0000 <nil>
  fmt.Println(parseTime(formats, t.Format(time.RubyDate)))    // 2022-05-23 07:03:05 +0000 +0000 <nil>
  fmt.Println(parseTime(formats, t.Format(time.UnixDate)))    // 2022-05-23 07:03:00 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.ANSIC)))       // 2022-05-23 07:03:00 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.StampNano)))   // 2022-05-23 07:03:05.234734423 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.StampMicro)))  // 0000-05-23 07:03:05.234734 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.StampMilli)))  // 0000-05-23 07:03:05.234 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.Stamp)))       // 0000-05-23 07:03:05 +0000 UTC <nil>
  fmt.Println(parseTime(formats, t.Format(time.Kitchen)))     // 0000-01-01 07:03:00 +0000 UTC <nil>
}

func parseTime(formats []string, dt string) (time.Time, error) {
  for _, format := range formats {
    parsedTime, err := time.Parse(format, dt)
    if err == nil {
      return parsedTime, nil
    }
  }

  return time.Time{}, fmt.Errorf("could not parse time: %s", dt)
}
```

Usually we see the implementation with all possible test cases to be sure that our algorithm is correct and it supports all required formats.

Looks like all formats were parsed without any issues and we will assume that this algorithm is correct and usable for our application.

## Conclusion

In this article we solved one more issue related to parsing date time string.
Now we can assume that our clients are covered and safe with all predefined formats.

Current implementation can be used without any restrictions in all your projects. But, pay more attention that you covered all required formats by your business. Probably, you will need to add more formats to the list.

I hope this article will save some time for you.
