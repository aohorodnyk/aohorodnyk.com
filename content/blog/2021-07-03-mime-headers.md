+++
title = "Accept header parser and matcher"
description = "Every REST service MUST support Accept header"
author = "Anton Ohorodnyk"
date = "2021-07-03"
tags = []
+++

# Introduction
It's not so obvious that `Accept` header is important part of HTTP and especially REST communication.
I was a part of multiple projects in different fields where people did not worry about accept header, either I'm.

In this short article I will show how simple to add accept validation and matching to your HTTP router, independently to router and framework you use.

# About Accept header
`Accept` header is simple list of mime types (`application/json`, `text/html`, etc.) or wildcard rules (`*/*`, `application/*`, etc.) that are supported by a client.
In case of provider `Accept` header, client expects to receive a response with one of matched mime types from the header.

This header also supports additional parameters can be provider per a mime type.

The main parameter is quality `q`, that defines order of rules to choose the best option for a client, for example: `*/*;q=0.1, application/json; q=1, application/xml; q=0.8`.
In this example we prefer to receive a response in JSON, if it's not supported, then  return in XML otherwise does not matter the response mime type.

The second example is character encoding `charset`. If client sets some `charset`, it expects to receive a response encoded by requested encoding.

# Creating our own middleware
Your router/framework can support this feature out of the box, then just use it and do not spend time to implement your own solution, if possible.
However, read the article in case of:
* You do not agree with an implementation in the framework;
* You need to implement support of `Accept` header by yourself;
* You want to discover more about `Accept` header supporting.

## Background
We will use [mimeheader](https://github.com/aohorodnyk/mimeheader) library to parse and match

## http/net middleware for http.HandleFunc
