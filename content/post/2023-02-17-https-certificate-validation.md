---
title: "Improving security in HTTPS communication"
description: "Make backend<->backend integration through HTTPS is more secure by simple step"
author: "Anton Ohorodnyk"
date: "2023-02-17T23:40:42-07:00"
type: "post"
---
## Introduction

We are living in a world where almost not left self-sufficient products.
Almost every product has at least one integration into other services.

Different protocols can be used for communication between them, like `REST`, `gRPC`, `GraphQL`, etc.
However, all of them use some network-level protocol, and usually, as a network protocol, they use HTTP[^http].

HTTP[^http] is a great multi-level[^http_multi_level] communication protocol. It also provides secure options such as HTTP over SSL/TLS[^https].

> This article will touch on some high-level concepts with links as starting points to read about them.
> Something can be used with simplification to avoid detailed explanations, but provided links can be used to learn more details.
> I will use [Golang](https://go.dev) as a great language for backend services.

## HTTPS pros and cons

HTTPS[^https] provides good security that makes our internet safe and with a much better level of privacy.
Some details on how HTTPS's security works can be found [here](https://www.cloudflare.com/learning/ssl/why-is-http-not-secure/).

The protocol itself contains a couple of steps that help encryption in HTTPS be as secure as it is:

1. [TLS handshake](https://www.cloudflare.com/learning/ssl/what-happens-in-a-tls-handshake/)
2. Certificate verification
3. [Encrypted communication](https://www.cloudflare.com/learning/ssl/why-is-http-not-secure/)

We will focus on step number two - Certificate Verification.

### Certificate verification

Certificate verification is an important step that helps us to guarantee that we did a TLS handshake with a trusted actor without MITM[^mitm] attack.

#### When the client finishes with a TLS handshake, it still has a question, is the opponents public key belongs to an expected actor?

It's not a simple question. Security invented certificates for public keys[^cert_public_key].
By having a trusted certificate[^trusted_vertificate] we can sign the public key and verify that the certificate's owner generated the public key.

#### But how to deliver a certificate, since it's the same as a public key?

Public and private keys are secure parts, so we want to regenerate them as often as possible and keep the ability to reissue them, in case of potential compromises.

On the other hand, certificates can be distributed to a limited amount of trusted issuers that will guarantee us the security and truthfulness of all signed keys. So, the decision was to build a database of public parts of root certificates[^root_certificate].

A list of trusted certificates (root certificates) is agreed upon across the organizations and companies[^apple_list]. So they are delivered and updated from time to time. However, they are not updated so frequently, so companies and organizations can provide them to all customers in some acceptable gap during OS updates or browser updates.

#### The idea with the list of certificates looks fantastic. What could go wrong?

Root certificates authorities verified, and we can assume that we can trust them, but something can go wrong.
There are a couple of examples from [Wikipedia about Root Certificates](https://en.wikipedia.org/wiki/Root_certificate):

* DigiNotar hack of 2011 - In 2011, the Dutch certificate authority DigiNotar suffered a security breach.
* China Internet Network Information Center (CNNIC) Issuance of Fake Certificates.
* WoSign and StartCom: Issuing fake and backdating certificates.

Also, we can add new simplified ways to get a certificate like Let’s Encrypt, AWS, Cloudflare, GCP, etc. I do not want to say they are not secure, but they simplified how we generate certificates.

We can believe that one certificate issuer, like Cloudflare will generate exclusive certificates per domain because they can control certificates for how many domains they issue. Meanwhile, there is a small chance that a *hacker* can generate the certificate for the same domain from another authority.

## Specific root certificate verification

The initial goal was to secure our backend<->backend integration.
Let's assume that we want to integrate with some financial institution's API, where we will send some SPII[^spii] data.

There are a few agreements:

* We know that our API uses AWS.
* Also, we believe that AWS will not issue two certificates for the same domain for different accounts.
* We want to provide more guarantees than HTTPS for our customers.

Based on everything we have discussed and reviewed, we can assume that the solution would be used strictly ONE root certificate that belongs to our partner's provider. In our use case, it will be AWS.

### Test system's CA certificates

First of all, we need to test. Can we download a page, `https://aohorodnyk.com/`? It uses Cloudflare's certificate.

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	resp, err := http.Get("https://aohorodnyk.com/")
	if err != nil {
		log.Fatalln("Could not read the URL with error: ", err.Error())
	}

	fmt.Println("Status code:", resp.StatusCode) // Status code: 200
}
```

The code above works well because it uses ALL system's CA certificates.

In the next test, let's try to do the same for `https://aws.amazon.com/`. We will use the system's CA certificates as well.

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	resp, err := http.Get("https://aws.amazon.com/")
	if err != nil {
		log.Fatalln("Could not read the URL with error: ", err.Error())
	}

	fmt.Println("Status code:", resp.StatusCode) // Status code: 200
}
```

### Use only the AWS ROOT certificate

Before we will do that, we need to download the AmazonRootCA. For Amazon, it can be found in their [repository](https://www.amazontrust.com/repository/AmazonRootCA1.pem), but for every website, it simply can be done through OpenSSL app or firefox.

We downloaded Amazon's certificate, and it's content:

```plain
-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----
```

We need to modify the previous code that will ignore ALL system's CA certs but only use our custom's one.

```go
package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"log"
	"net/http"
)

func main() {
	// For the certificate, formatting is important. \n can be parsed as in the example, but
	// tabs or spaces that can be added before every line by IDE will break the cert.
	caCert := `-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----`

	rootCAs := x509.NewCertPool() // Create a new cert pool and ignore system's root certificates.

	ok := rootCAs.AppendCertsFromPEM([]byte(caCert)) // Add our custom CA cert.
	if !ok {
		log.Fatalln("Cannot append our root certificate")
	}

	// This custom client is not for production use.
	// For production, please, configure the client properly.
	httpClient := http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: rootCAs, // Set custom root CAs.
			},
		},
	}

	resp, err := httpClient.Get("https://aws.amazon.com/")
	if err != nil {
		log.Fatalln("Could not read the URL with error: ", err.Error())
	}

	fmt.Println("Status code:", resp.StatusCode) // Status code: 200
}
```

And now, let's try to fetch our domain `https://aohorodnyk.com/` that uses Cloudflare's certificate.

```go
package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"log"
	"net/http"
)

func main() {
	// For the certificate, formatting is important. \n can be parsed as in the example, but
	// tabs or spaces that can be added before every line by IDE will break the cert.
	caCert := `-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----`

	rootCAs := x509.NewCertPool() // Create a new cert pool and ignore system's root certificates.

	ok := rootCAs.AppendCertsFromPEM([]byte(caCert)) // Add our custom CA cert.
	if !ok {
		log.Fatalln("Cannot append our root certificate")
	}

	// This custom client is not for production use.
	// For production, please, configure the client properly.
	httpClient := http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: rootCAs, // Set custom root CAs.
			},
		},
	}

	resp, err := httpClient.Get("https://aohorodnyk.com/")
	if err != nil {
		log.Fatalln("Could not read the URL with error: ", err.Error()) // Could not read the URL with error: Get "https://aohorodnyk.com/": x509: certificate signed by unknown authority.
	}

	fmt.Println("Status code:", resp.StatusCode)
}
```

If will change the domain to `google.com`, the error will be the same `Could not read the URL with error: Get "https://google.com/": x509: certificate signed by unknown authority`.

## Conclusion

Small steps can help us to improve the security of services. Most crucial is that these improvements do not require vast time investments. So, let's make the web more secure!

I hope this article will motivate people to pay attention to these small details.

[^http]: [Hypertext Transfer Protocol (HTTP)](https://developer.mozilla.org/en-US/docs/Web/HTTP).
[^https]: [HyperText Transfer Protocol Secure (HTTPS)](https://developer.mozilla.org/en-US/docs/Glossary/HTTPS).
[^http_multi_level]: HTTP supports headers in requests and responses that help to keep an additional level of abstraction of internal protocols, for example [Accept mime headers]({{< ref "2021-07-03-mime-headers.md" >}}).
[^mitm]: [MITM (man-in-the-middle)](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) is the type of attack where someone can read and/or change traffic transferred between two parties.
[^cert_public_key]: Certificate for public keys provides a way to verify that a specific private certificate signed public key. Details are [here](https://en.wikipedia.org/wiki/Public_key_certificate).
[^trusted_vertificate]: Public information is the same as a public key. It can be published anywhere without any risks to the owner.
[^root_certificate]: The first-level certificate is secured as best as possible and used only by an authority to sign domain certificates. Details are [here](https://en.wikipedia.org/wiki/Root_certificate).
[^apple_list]: As an example, we can see the list of [certificates trusted by Apple](https://support.apple.com/en-us/HT213080) for all their products, like iOS, MacOS, TvOS, etc. Other organizations and companies can be simply found through your favorite search engine.
[^spii]: [SPII (Sensitive Personally Identifiable Information)](https://www.epa.gov/irmpoli8/protecting-sensitive-personally-identifiable-information-spii) like credit card data, SSN, passport data, etc.
