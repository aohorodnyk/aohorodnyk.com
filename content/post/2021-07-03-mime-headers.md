---
title: "Accept header parser and matcher"
description: "Every REST service MUST support Accept header"
author: "Anton Ohorodnyk"
date: "2021-07-03T19:09:05-07:00"
type: "post"
aliases: ["/blog/2021-07-03-mime-headers/"]
mermaid: false
---
## Introduction
It's not so evident that the `Accept` header is an essential part of HTTP and especially REST communication.
Usually people do not worry about `Accept` header, either I'm.

This short article will show how simple to add validation and matching to your HTTP router independently to the router and framework you use.

## About Accept header
`Accept` header is a simple list of mime types (`application/json`, `text/html`, etc.) or wildcard rules (`*/*`, `application/*`, etc.) that a client supports.
In the case of the provider `Accept` header, the client expects to respond with one of the matched mime types from the header.

This header also supports additional parameters that a client can provide per a mime type.

The main parameter is quality `q`, that defines order of rules to choose the best option for a client, for example: `*/*;q=0.1, application/json; q=1, application/xml; q=0.8`.
In this example, we prefer to receive a response in JSON. If it's not supported, return in XML; otherwise, it does not matter the response mime type.

The second example is character encoding `charset`. If a client sets some `charset`, it expects to receive a response encoded.

### Implementation notes
Following the description above. We can specify requirements for the `Accept` header parser
1. Split all mime types by `,` symbol;
1. Parse mime type and params;
1. Order mime types and rules by:
    1. Use `q` parameter to sort;
    1. More strict mime types have more priority than wildcards;
    1. More parameters have more priority.
1. Match supported mime types to `Accept` rules from the `Accept` header and find the best result for either for client and server.

## Creating middleware
Your router/framework can support this feature out of the box. If possible, do not spend time implementing your solution.
However, read the article in case of:
* You disagree with an implementation in your framework;
* You need to implement support of `Accept` header by yourself;
* You want to discover more about `Accept` header supporting.

### Background
* We will use [mimeheader](https://github.com/aohorodnyk/mimeheader) library to parse and match mime types;
* Our middleware will implement `http.HandlerFunc` type;
* It's ONLY for learning purposes, do not use it in real projects AS IS.

### Header parsing explanation
In this block we will review the main part of an example:
```go
header := r.Header.Get("Accept")

// Parse Accept header to build needed rules for matching.
ah := mimeheader.ParseAcceptHeader(header)

// We do not need default mime type.
mh, mtype, m := ah.Negotiate(acceptMimeTypes, "")
if !m {
  // If not matched accept mim type, return 406.
  rw.WriteHeader(http.StatusNotAcceptable)

  return
}

// Add matched mime type to context.
ctx := context.WithValue(r.Context(), "resp_content_type", mtype)
// Add charset, if exists.
chs, ok := mh.Params["charset"]
if ok {
  ctx = context.WithValue(ctx, "resp_charset", chs)
}
```

Actually the main magic happenes in two lines of code:
```go
// Parse Accept header to build needed rules for matching.
ah := mimeheader.ParseAcceptHeader(header)
// We do not need default mime type.
mh, mtype, m := ah.Negotiate(acceptMimeTypes, "")
```
That's precisely the whole code needed to parse and match mime types. Other logic is related to the processing of retrieved data.

### http/net middleware for http.HandleFunc
```go
package main

import (
 "context"
 "log"
 "net/http"

 "github.com/aohorodnyk/mimeheader"
)

func main() {
 r := http.NewServeMux()

 r.HandleFunc("/", acceptHeaderMiddleware([]string{"application/json", "text/html"})(handlerTestFunc))

 err := http.ListenAndServe(":8080", r)
 if err != nil {
  log.Fatalln(err)
 }
}

func acceptHeaderMiddleware(acceptMimeTypes []string) func(http.HandlerFunc) http.HandlerFunc {
 return func(next http.HandlerFunc) http.HandlerFunc {
  return func(rw http.ResponseWriter, r *http.Request) {
   header := r.Header.Get("Accept")
   ah := mimeheader.ParseAcceptHeader(header)

   // We do not need default mime type.
   mh, mtype, m := ah.Negotiate(acceptMimeTypes, "")
   if !m {
    // If not matched accept mim type, return 406.
    rw.WriteHeader(http.StatusNotAcceptable)

    return
   }

   // Add matched mime type to context.
   ctx := context.WithValue(r.Context(), "resp_content_type", mtype)
   // Add charset, if set
   chs, ok := mh.Params["charset"]
   if ok {
    ctx = context.WithValue(ctx, "resp_charset", chs)
   }


   // New requet from new context.
   rc := r.WithContext(ctx)

   // Call next middleware or handler.
   next(rw, rc)
  }
 }
}

func handlerTestFunc(rw http.ResponseWriter, r *http.Request) {
 mtype := r.Context().Value("resp_content_type").(string)
 charset, _ := r.Context().Value("resp_charset").(string)

 rw.Write([]byte(mtype + ":" + charset))
}
```

### Responses
```http request
GET http://localhost:8080/
Accept: text/*; q=0.9,application/json; q=1;

##HTTP/1.1 200 OK
##Date: Sat, 03 Jul 2021 23:55:41 GMT
##Content-Length: 17
##Content-Type: text/plain; charset=utf-8
##
##application/json:

####

GET http://localhost:8080/
Accept: text/*; q=1,application/json; q=1; charset=utf-8bm;

##HTTP/1.1 200 OK
##Date: Sat, 03 Jul 2021 23:56:14 GMT
##Content-Length: 24
##Content-Type: text/plain; charset=utf-8
##
##application/json:utf-8bm

####
GET http://localhost:8080/
Accept: text/html; charset=utf-8; q=1,application/*; q=1; charset=cp1251;

##HTTP/1.1 200 OK
##Date: Sat, 03 Jul 2021 23:54:20 GMT
##Content-Length: 14
##Content-Type: text/plain; charset=utf-8
##
##text/html:utf-8

####
GET http://localhost:8080/
Accept: text/*; q=1,application/*; q=0.9;

##HTTP/1.1 200 OK
##Date: Sat, 03 Jul 2021 23:56:33 GMT
##Content-Length: 10
##Content-Type: text/plain; charset=utf-8
##
##text/html:

####
GET http://localhost:8080/
Accept: text/plain; q=1,application/xml; q=1;

## HTTP/1.1 406 Not Acceptable
## Date: Sat, 03 Jul 2021 19:17:28 GMT
## Content-Length: 0
## Connection: close
```

## Conclusion
Let's try not to forget about the `Accept` header even if this feature is not implemented in the current framework.

If you use go and want to work with `Accept` header or mime types in general, you could try [mimeheader](https://github.com/aohorodnyk/mimeheader) library. I believe it will help with the task.
