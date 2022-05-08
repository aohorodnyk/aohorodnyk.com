---
title: "Unversal time UnmarshalJSON implementation"
description: "The final implementation for the unviersal time parser that implements the UnmarshalJSON interface"
author: "Anton Ohorodnyk"
date: "2022-05-08T13:01:24-07:00"
type: "post"
---
## Introduction

We have done with two complecated steps:

1. Wrote a function that [parses time from different timestamp formats]({{< ref "/post/2022-05-06-parse-timestamp" >}}).
1. Wrote a function that [parses time from different non timestamp formats like RFC3339]({{< ref "/post/2022-05-07-parse-time-strings" >}})

The next and final step will be to write a real world function that solves the real and actual problem.
We need to parse the JSON field from different formats with different data types.

And, as usual, I will go though couple of investigation steps before we will write the real code.

> I'll use [Golang](https://go.dev/) for all code examples, but you can use any other languages base on the provided algorithm.

## Task overview

Current task is to write a Golang type that can be used in JSON parsing pipeline.
This field should support couple of use cases that we already reviewed in previous articles:

1. We received a JSON field with numeric type and we expect to parse it as a some type to timestamp.
1. We received a JSON field with string type and we expect to parse it as a some type to timestamp.
1. We received a JSON field with string type and we expect to parse it as a some layout from the provided list.

### Expectations

Based on the above use cases, we expect the see the following list of JSON fields:

```json
{
  "num_seconds": 1651808102,
  "num_milliseconds": 1651808102363,
  "num_microseconds": 1651808102363368,
  "num_nanoseconds": 1651808102363368423,

  "hex_seconds": "0x62749766",

  "str_seconds": "1651808102",
  "str_milliseconds": "1651808102363",
  "str_microseconds": "1651808102363368",
  "str_nanoseconds": "1651808102363368423",

  "str_rfc3339": "2022-05-06T03:35:02Z",
  "str_rfc3339_nano": "2022-05-06T03:35:02.363368423Z",
  "str_rfc1123": "Fri, 06 May 2022 03:35:02 UTC",
  "str_rfc850": "Friday, 06-May-22 03:35:02 UTC",
  "str_rfc822": "06 May 22 03:35 UTC"
}
```

Obviously it's not full list of types, but as we already tests more complete list of cases before, we can simplify it right now.

We added hex seconds field, just in to see it works as well, because of the magic of `strconv.ParseInt` function.

### UnmarshalJSON interface overview

Before the implementation we need to consider the Golang way of custom JSON data types implementation.

Golang contains the interface [Unmarshaler](https://pkg.go.dev/encoding/json#Unmarshaler) with one method `UnmarshalJSON([]byte) error`.
It means that we need to implement only one method to parse the JSON field.

There is an example of the simple implementation of the interface where we just need to separate the string in a JSON field to 2 variables separated by underscore `_`:

```go
package main

import (
  "encoding/json"
  "errors"
  "strings"
)

type unmarshaled struct {
  part1 string
  part2 string
}

func (u *unmarshaled) UnmarshalJSON(text []byte) error {
  str := string(text)
  parts := strings.Split(str, "_")
  if len(parts) != 2 {
    return errors.New("invalid format")
  }

  u.part1 = parts[0]
  u.part2 = parts[1]

  return nil
}

type jsonType struct {
  T unmarshaled `json:"t"`
}

func main() {
  var jt jsonType

  json1 := `{"t": "one_two"}`

  err := json.Unmarshal([]byte(json1), &jt)
  if err != nil {
    panic(err)
  }

  println(jt.T.part1, jt.T.part2)

  json2 := `{"t": "onetwo"}`

  err = json.Unmarshal([]byte(json2), &jt)
  if err != nil {
    panic(err)
  }

  println(jt.T.part1, jt.T.part2)
}
```

Output:

```plain
"one two"
panic: invalid format

goroutine 1 [running]:
main.main()
        /Users/aohorodnyk/projects/anton.ohorodnyk.name/main.go:47 +0x13c
exit status 2
```

As we can see it parsed first input, but failed on the second input.

## Implementation

The final implementation will contain the following steps:

1. Check if the JSON field is a numeric, because of it's the fastest condition.
    1. If it's a numeric, we can parse it as a timestamp.
    1. Use the `strconv.ParseInt` function to parse it.
    1. The `strconv.ParseInt` function will parse the type based on the prefix of the string. If the prefix is `0x`, it will be parsed as a hexadecimal number. 0b as a binary number, etc. By default it will be parsed as a decimal number.
    1. If we can't prase the numeric value as an integer, then return the error, since we do not know waht to do with the value.
    1. Otherwise set the time and finish the processing.
1. Otherwise the value is a string. For strings we need to trim quotes to make the value a plain string.
1. Try to parse the string with all supported layouts.
1. If we successfuly parsea the string with a some listed layouts, then set the time and finish the processing.
1. If we did not find the needed layout, try to parse the string as a timestamp.
1. If we successfuly parse the string as a timestamp, then set the time and finish the processing.
1. Otherwise return the error.

The next code implements the algorithm described above.

```go
package main

import (
  "encoding/json"
  "errors"
  "fmt"
  "math"
  "strconv"
  "strings"
  "time"
)

// List of supported time layouts.
var formats = []string{
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

const (
  maxNanoseconds  = int64(math.MaxInt64)
  maxMicroseconds = int64(maxNanoseconds / 1000)
  maxMilliseconds = int64(maxMicroseconds / 1000)
  maxSeconds      = int64(maxMilliseconds / 1000)

  minNanoseconds  = int64(math.MinInt64)
  minMicroseconds = int64(minNanoseconds / 1000)
  minMilliseconds = int64(minMicroseconds / 1000)
  minSeconds      = int64(minMilliseconds / 1000)
)

type InternalTime struct {
  time.Time
}

func (it *InternalTime) UnmarshalJSON(data []byte) error {
  // Make sure that the input is not empty
  if len(data) == 0 {
    return errors.New("empty value is not supported")
  }

  // If the input is not a string, try to parse it as a number, otherwise return an error.
  if data[0] != '"' {
    timeInt64, err := strconv.ParseInt(string(data), 0, 64)
    if err != nil {
      return err
    }

    it.Time = parseTimestamp(timeInt64)
  }

  // If the input is a string, trim quotes.
  str := strings.Trim(string(data), `"`)

  // Parse the string as a time using the supported layouts.
  parsed, err := parseTime(formats, str)
  if err == nil {
    it.Time = parsed

    return nil
  }

  // As the final attempt, try to parse the string as a timestamp.
  timeInt64, err := strconv.ParseInt(str, 0, 64)
  if err == nil {
    it.Time = parseTimestamp(timeInt64)

    return nil
  }

  return errors.New("Unsupported time format")
}

type jsonType struct {
  NumSeconds      InternalTime `json:"num_seconds"`
  NumMilliseconds InternalTime `json:"num_milliseconds"`
  NumMicroseconds InternalTime `json:"num_microseconds"`
  NumNanoseconds  InternalTime `json:"num_nanoseconds"`

  HexSeconds InternalTime `json:"hex_seconds"`

  StrSeconds      InternalTime `json:"str_seconds"`
  StrMilliseconds InternalTime `json:"str_milliseconds"`
  StrMicroseconds InternalTime `json:"str_microseconds"`
  StrNanoseconds  InternalTime `json:"str_nanoseconds"`

  StrRFC3339     InternalTime `json:"str_rfc3339"`
  StrRFC3339Nano InternalTime `json:"str_rfc3339_nano"`
  StrRFC1123     InternalTime `json:"str_rfc1123"`
  StrRFC850      InternalTime `json:"str_rfc850"`
  StrRFC822      InternalTime `json:"str_rfc822"`
}

func main() {
  var jt jsonType

  json1 := `{
    "num_seconds": 1651808102,
    "num_milliseconds": 1651808102363,
    "num_microseconds": 1651808102363368,
    "num_nanoseconds": 1651808102363368423,

    "hex_seconds": "0x62749766",

    "str_seconds": "1651808102",
    "str_milliseconds": "1651808102363",
    "str_microseconds": "1651808102363368",
    "str_nanoseconds": "1651808102363368423",

    "str_rfc3339": "2022-05-06T03:35:02Z",
    "str_rfc3339_nano": "2022-05-06T03:35:02.363368423Z",
    "str_rfc1123": "Fri, 06 May 2022 03:35:02 UTC",
    "str_rfc850": "Friday, 06-May-22 03:35:02 UTC",
    "str_rfc822": "06 May 22 03:35 UTC"
  }`

  err := json.Unmarshal([]byte(json1), &jt)
  if err != nil {
    panic(err)
  }

  fmt.Println(jt) // {2022-05-05 20:35:02 -0700 PDT 2022-05-05 20:35:02.363 -0700 PDT 2022-05-05 20:35:02.363368 -0700 PDT 2022-05-05 20:35:02.363368423 -0700 PDT 2022-05-05 20:35:02 -0700 PDT 2022-05-05 20:35:02 -0700 PDT 2022-05-05 20:35:02.363 -0700 PDT 2022-05-05 20:35:02.363368 -0700 PDT 2022-05-05 20:35:02.363368423 -0700 PDT 2022-05-06 03:35:02 +0000 UTC 2022-05-06 03:35:02.363368423 +0000 UTC 2022-05-06 03:35:02 +0000 UTC 2022-05-06 03:35:02 +0000 UTC 2022-05-06 03:35:00 +0000 UTC}
}

func parseTimestamp(timestamp int64) time.Time {
  switch {
  case timestamp < minMicroseconds:
    return time.Unix(0, timestamp) // Before 1970 in nanoseconds.
  case timestamp < minMilliseconds:
    return time.Unix(0, timestamp*int64(time.Microsecond)) // Before 1970 in microseconds.
  case timestamp < minSeconds:
    return time.Unix(0, timestamp*int64(time.Millisecond)) // Before 1970 in milliseconds.
  case timestamp < 0:
    return time.Unix(timestamp, 0) // Before 1970 in seconds.
  case timestamp < maxSeconds:
    return time.Unix(timestamp, 0) // After 1970 in seconds.
  case timestamp < maxMilliseconds:
    return time.Unix(0, timestamp*int64(time.Millisecond)) // After 1970 in milliseconds.
  case timestamp < maxMicroseconds:
    return time.Unix(0, timestamp*int64(time.Microsecond)) // After 1970 in microseconds.
  }

  return time.Unix(0, timestamp) // After 1970 in nanoseconds.
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

The above code provides positive test cases that proves the algorithm works and implementation are correct.

## Conclusion

In the latest three articles we wrote the universal time parser that can be used to improve clients' developer experience.
It will also decrease amount of production bugs and errors.

I hope these articles will be helpful to you and your team.
