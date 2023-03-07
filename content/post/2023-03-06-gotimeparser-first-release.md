---
title: "First release of gotimeparser"
description: "Open Source is important for future of software development. I am happy to announce GoTimeParser's first release."
author: "Anton Ohorodnyk"
date: "2023-03-06T23:34:35-07:00"
type: "post"
---
## Background

Many companies use service to service integration through different API porotocols.
I had the same situation in my production environment. At some point, clients of my service started to send me dates in different formats.

Some of them sent timestamps in int, some of them used ISO 8601, etc. But what was clear, these dates were valid and we could not request to change it in one day.

As a result of this issue, I implemented some solution that solved the issue and wrote a couple of articles that shared the issue and the approach:

1. [Parse timestamp formats](https://aohorodnyk.com/post/2022-05-06-parse-timestamp/)
1. [Parse time from different non timestamp formats](https://aohorodnyk.com/post/2022-05-07-parse-time-strings/)
1. [Universal time UnmarshalJSON implementation](https://aohorodnyk.com/post/2022-05-08-universal-time-unmarshaljson/)

But I did not want to create an Open Source package, because of I believe that Open Source cannot be just few lines of code. It's a right formatting of the code, some code coverage by tests, examples and the most important - is commitment to support it.

## First release

Today is a day when I decided to invest time and commit to a simplification of software development in Go.
Time parsing is a regular issue, especially in event-driven architecture and microservice arachitectures.

Feel free to use the zero-dependency library to solve all the main issues you could have with time parsing in Go.
