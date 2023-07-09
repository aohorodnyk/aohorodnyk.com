---
title: "How to Associate Multiple Mastodon Account Aliases with a Domain Using Cloudflare Pages"
description: "Instructions for Associating Multiple Mastodon Account Aliases with a Domain Using Cloudflare Pages, Without the Need for Workers or Extra Coding"
author: "Anton Ohorodnyk"
date: "2023-07-08T22:15:23-07:00"
type: "post"
---

## Preamble

I've started to use [Mastodon][mastodon] as my primary social media platform for technical questions. Everything looks good and nice, but Mastodon is Fediverse and has a decentralized nature. It means that every user can use their own instance, and the user's profile is associated with the instance's domain. It's similar to email addresses, where the domain is the server's address, and the username is the user's name.

I chose [Fosstodon][fosstodon] as a server with good community and target similar to my point of view. However, it would be great to resolve my [Fosstodon][fosstodon]'s account with my personal domain and username. In my case it should be `me@aohorodnyk.com`.

I use amazing [Hugo](https://gohugo.io) statis site generator and deploy it to CloudFlare Pages.
This solution is perfectly solves all my needs, but it doesn't have any server-side logic to resolve the name.

## The issue

When I started to search for a solution, I found the service with name [WebFinder](https://webfinger.net/). This service uses fediverse specification to resolve the name.

By simply putting my [Fosstodon][fosstodon]'s account `aohorodnyk@fosstodon.org` to a search field, it shows us how it resolves the name.

```
04:15:24 Looking up WebFinger data for acct:aohorodnyk@fosstodon.org
04:15:24 GET https://fosstodon.org/.well-known/webfinger?resource=acct%3Aaohorodnyk%40fosstodon.org
```

And what it resolves:

```
{
  "subject": "acct:aohorodnyk@fosstodon.org",
  "aliases": [
    "https://fosstodon.org/@aohorodnyk",
    "https://fosstodon.org/users/aohorodnyk"
  ],
  "links": [
    {
      "rel": "http://webfinger.net/rel/profile-page",
      "type": "text/html",
      "href": "https://fosstodon.org/@aohorodnyk"
    },
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://fosstodon.org/users/aohorodnyk"
    },
    {
      "rel": "http://ostatus.org/schema/1.0/subscribe",
      "template": "https://fosstodon.org/authorize_interaction?uri={uri}"
    }
  ]
}
```

Using this information, we can assume that this path `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com` should resolve the same JSON to be an alias to my [Fosstodon][fosstodon]'s account.

Additionally I tested not existed username to see the response. Is it some specific JSON or just 404 error. And fortunately it's just 404 error.

The simples solution is to create the file `/.well-known/webfinger` with the content from [Fosstodon][fosstodon] will be good enough. But the downside of this solution is that all users in my domain will be resolved with the same account.

To resolve the issue we need somehow resolve different files by different GET parameters to the same path.

## The solution

I've started to search the information on how to put a minimal logic to resolve different files by different GET parameters to the same path. And there are no solutions on the internet except using [CloudFlare Workers/CloudFlare Functions](https://developers.cloudflare.com/pages/platform/functions/).

I'm almost agreed to use functions, but serverless solutions always stops me because of unpredictable pricing. For my minimalistic needs, I don't want to pay for the serverless solution.

After that I've tried to create a file with the fulle name `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com`, but obviously it did not work (trying worth it).

And finally, I started to check different rewrite and redirect rules inside CloudFlare admin page. Suprisingly for myself I found [CloudFlare Transform Rules](https://developers.cloudflare.com/rules/transform/). This feature allows us to create a rule to transform requests to our server.

### CloudFlare Transform Rules

The idea was to create a rule that will parse `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com` and transform it to some unique file in CloudFlare Pages. And the main file `/.well-known/webfinger` won't exist at all, so all other requests will return 404 as expected.

#### Requirements for our rules

It could be not so important, but let's define the requirements for the solution:
* We need to resolve our JSON on the request `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com`
* We want to resolve the same JSON on the request `/.well-known/webfinger?resource=acct%3Ame%40aohorodnyk.com&format=json`
* On ALL other requests we want to return 404 error

#### Working solution

In CloudFlare's admin page, I've created a rule with the following settings:
* AND
* **URI PATH** equals `/.well-known/webfinger`
* AND
* **URI Query String** contains `resource=acct%3Ame%40aohorodnyk.com`
* OR
  * **URI PATH** equals `/.well-known/webfinger`
  * AND
  * **URI Query String** contains `resource=acct:me@aohorodnyk.com`

Expression preview: `(http.request.uri.path eq "/.well-known/webfinger" and http.request.uri.query contains "resource=acct:me@aohorodnyk.com") or (http.request.uri.path eq "/.well-known/webfinger" and http.request.uri.query eq "resource=acct%3Ame%40aohorodnyk.com")`.

![Working rules](/post/mastodon-alias-in-cloudflare/transform-rules.png)

And the action is to transform the request to the file `/.well-known/webfinger-aohorodnyk.json`.

![Transformation rules](/post/mastodon-alias-in-cloudflare/rewrite-parameters.png)

## Testing

After saving the rules, I've tested it with the requests from `curl` (I personally use `curlie` and fish shell):
```bash
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
```

And let's not forget about negative test cases:
```bash
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

I'm happy with the solution. It's simple, fast, free and it works. It scales well for multiple users on the same domain.


[mastodon]: https://joinmastodon.org/
[fosstodon]: https://fosstodon.org/
