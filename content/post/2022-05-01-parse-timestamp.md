---
title: "Parse timestamps on backend"
description: "Parse timestamp from different clients and from different developers"
author: "Anton Ohorodnyk"
date: "2022-05-01T18:29:09Z"
type: "post"
mermaid: false
---
## Introduction

Have you ever had a situation when different clients send milliseconds in requests to a back-end that expects timestampsin seconds?

If not, you are lucky person. Unfortunately, it's so popular issue in my experience.
I even cannot count a number of bugs related to the specific issue.

Every time we find this issue on a client, we need to find the best on how to solve it.
If a front-end is web-site, it's littery not an issue and can be simply fixed and redeliver to all users in short period of time.
But, if the front-end is a client application, it could be much more complicated to redeliver the fix to all clients in some predictable period of time.

In my point of view the best way to fix the issue in this specific situation is to fix everything on backend and support two different types of payload.
We have predictable time expectations when we can fix the issue, we know how can we deliver the fix to ALL users, etc.

In the current example when we expect to receive the unix timestamp in seconds, but receive it in milliseconds.
We can fix it by adding support for both possible values to our parser.

So, we have fixed the issue, let's relax.
But, asr we discussed that this issue have happened multiple time, let's try to think about the solution to prevent this issue in future?

## Issue overview

Before we will start writing code, we need to understand the issue.

### Use case with milliseconds instead of seconds in INT field


