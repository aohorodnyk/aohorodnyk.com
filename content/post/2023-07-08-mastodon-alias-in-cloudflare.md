---
title: "How to link multiple mastodon account aliases to a domain via Cloudflare Pages"
description: "Step-by-step guide on associating multiple mastodon account aliases to a domain with Cloudflare Pages, eliminating the need for workers or extra coding"
author: "Anton Ohorodnyk"
date: "2023-07-08T22:14:23-07:00"
type: "post"
---

## Introduction

Recently, I've begun utilizing [Mastodon][mastodon] as my go-to social media platform for technical queries. I've found that while Mastodon's decentralized nature – a core aspect of the Fediverse – is attractive, it also brings about some complexities. Similar to how email addresses work, a user's profile on Mastodon is tied to their instance's domain.

In my journey, I discovered [Fosstodon][fosstodon], a server with a community that aligns with my perspectives. I wished to tie my [Fosstodon][fosstodon]'s account to my personal domain and username, essentially making it `me@aohorodnyk.com`. For my website, I use the superb Hugo static site generator and deploy it to CloudFlare Pages, but it doesn't have any server-side logic to resolve the name.
Following, this goal came with a challenge: I had to find a solution without any server-side logic to resolve the name.

## The Problem

I came across a service named [WebFinger][webfinger] in my search for a solution. [WebFinger][webfinger] utilizes the fediverse specification to resolve names. When I input my [Fosstodon][fosstodon]'s account `aohorodnyk@fosstodon.org`` into a search field, it demonstrates how the name gets resolved.

It does these two things:
```
04:15:24 Looking up WebFinger data for acct:aohorodnyk@fosstodon.org
04:15:24 GET https://fosstodon.org/.well-known/webfinger?resource=acct%3Aaohorodnyk%40fosstodon.org
```

From my analysis, I concluded that for an alias to my [Fosstodon][fosstodon]'s account, the same JSON should be resolved by this path: `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com`.

The simplest approach would be to create a file /.well-known/webfinger with the content from [Fosstodon][fosstodon]. The downside is that all users in my domain would be resolved with the same account. So, I needed to find a way to resolve different files by different GET parameters to the same path.

## The solution

My search for a way to apply minimal logic to resolve different files by different GET parameters to the same path was initially fruitless. The only available solutions online involved using [CloudFlare Workers/CloudFlare Functions](https://developers.cloudflare.com/pages/platform/functions/).

Reluctantly, I was considering using functions. However, the unpredictable pricing of serverless solutions was a deterrent. I didn't want to incur costs for my minimalist needs.

After several failed attempts, including trying to create a file with the full name `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com`, I found a ray of hope in [CloudFlare Transform Rules](https://developers.cloudflare.com/rules/transform/). This feature lets us create rules to transform requests to our server.

### CloudFlare Transform Rules

The concept was to develop a rule that could parse `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com` and transform it into a unique file in CloudFlare Pages. The main file `/.well-known/webfinger` wouldn't exist at all, ensuring all other requests returned a 404 as expected.

#### Rule Requirements

While it might not be overly critical, it's beneficial to lay down requirements for our solution:
* The request `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com` must resolve our JSON
* The same JSON should be resolved on the request `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com&format=json`
* For ALL other requests, a 404 error should be returned

#### Successful Implementation

In CloudFlare's admin page, I formulated a rule with specific settings and the action to transform the request to the file `/.well-known/webfinger-aohorodnyk.json`

Expression preview: `(http.request.uri.path eq "/.well-known/webfinger" and http.request.uri.query contains "resource=acct:me@aohorodnyk.com") or (http.request.uri.path eq "/.well-known/webfinger" and http.request.uri.query eq "resource=acct%3Ame%40aohorodnyk.com")`.

![Working rules](/post/mastodon-alias-in-cloudflare/transform-rules.png)

And the action is to transform the request to the file `/.well-known/webfinger-aohorodnyk.json`.

![Transformation rules](/post/mastodon-alias-in-cloudflare/rewrite-parameters.png)

## Evaluation

Upon saving the rules, I ran various positive and negative test cases using `curlie` and found the results to be successful:
```bash
# Positive test cases
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com"
HTTP/2 200
...
{
  ...
}
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct:me@aohorodnyk.com"
HTTP/2 200
...
{
  ...
}
# Negative test cases
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct%3Aame%40aohorodnyk.com" # wrong username with prefix `a`
HTTP/2 404
...
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct%3Amea%40aohorodnyk.com" # wrong username with suffix `a`
HTTP/2 404
...
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct%3Ame%40ohorodnyk.com" # wrong domain
HTTP/2 404
...
$ curlie "https://aohorodnyk.com/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.co" # wrong domain
HTTP/2 404
...
```

## Conclusion

Overall, the solution proved to be straightforward, efficient, cost-free, and operational. Moreover, it demonstrated excellent scalability for multiple users on the same domain.

By the way, since our topic is built around [Mastodon][mastodon], I invite you to subscribe on me and stay on touch. My account is [me@aohorodnyk.com (aohorodnyk@fosstodon.org)](https://fosstodon.org/@aohorodnyk)


[mastodon]: https://joinmastodon.org/
[fosstodon]: https://fosstodon.org/
[webfinger]: https://webfinger.net/
