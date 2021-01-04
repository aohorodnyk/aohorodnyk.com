+++
title = "Quick Review of the Most Popular Ways to Implement Flags"
description = "Quick introduction to different type of flags with pros and cons"
author = "Anton Ohorodnyk"
date = "2021-1-3"
tags = []
+++

# Introduction
There are many ways to store flags and use them for communication between `client <-> backend service` or `service <-> service`. In the article we are going to review the most popular options and we will try to answer for the question: When should I use a type of flags storage and or communication way.
The most popular ways to work with flags are:
1. Store in separate [column in DB](https://en.wikipedia.org/wiki/Column_(database)) or separate [property in a class/struct](https://en.wikipedia.org/wiki/Property_(programming))
1. Store as an [array](https://en.wikipedia.org/wiki/Array_data_structure) or in a [set](https://en.wikipedia.org/wiki/Set_(abstract_data_type))
1. Store as a binary data in a variable

# Options
## Separate field
It means we would create separate column in DB for each flag.

### DB Example
In an example `is_new` will be a flag.
| id | username | is_new |
|----|----------|--------|
| 1  | test1    | true   |
| 2  | test2    | false  |

### JSON Example
In a code or in a NoSQL database representation would be:
```json
[
	{
		"id": 1,
		"username": "test1",
		"is_new": true
	},
	{
		"id": 2,
		"username": "test2",
		"is_new": false
	}
]
```

### Pros
* Simple to read
* Simple to understand
* Self documented
* In a code it can represent as typed properties
* Simple to convert between different representations, like `struct/class -> JSON -> protobuf -> MsgPack -> DB row -> struct/class`
* Simple to use in search and aggregaction requests in DB (for example by [SQL](https://en.wikipedia.org/wiki/SQL))
* Can be updated in DB in parallel, by [UPDATE query](https://en.wikipedia.org/wiki/Update_(SQL))

### Cons
* Takes up memory/storage space/traffic
* Could be expensive in development or risky to remove in case of dynamic typed languages
* Could be expensive in development to add or remove or update in case of microservice architecture
* Could be expensive in development to remove from [DB as a column](https://en.wikipedia.org/wiki/Column_(database))
* Could affect different limitation in case of bit number of flags

### Use Cases
In my opinion before using this approach, we should answer "yes" for all listed options in the *checklist*:
* I agree to extend add and remove columns in your database (or add fields to NoSQL database)?
* I understand it could take up resources in DB will be used
* I do not have memory and traffic sensitive clients or services

## Store In Array
In current implementation we will store all flags as `strings` in an array.

### DB Example
In a DB, we are going to store values in separate table as [one to many relationship](https://en.wikipedia.org/wiki/One-to-many_(data_model)).

Table `user`:
| id | username |
|----|----------|
| 1  | test1    |
| 2  | test2    |

Table `user_flag` table
| id | user_id | flag    |
|----|---------|---------|
| 1  | 1       | is_new  |
| 2  | 1       | is_test |

Every `user_flag` row is linked to a row in `user` table by `user_id` field.
It can be optimized to not store flag as a string, but in our current topic it is not so important.

### JSON Example
In a code or in a NoSQL database representation would be:
```json

[
	{
		"id": 1,
		"username": "test1",
		"flags": [
			"is_new",
			"is_test"
		]
	},
	{
		"id": 2,
		"username": "test2",
		"flags": []
	}
]
```

### Pros
* Simple to read
* Simple to understand
* Self documented
* Could be dynamicly extended in a code (does not need to update code to add new flag)
* Simple to convert between different representations, like `struct/class -> JSON -> protobuf -> MsgPack -> DB row -> struct/class`
* Pretty simple to use in search and aggregaction requests in DB (for example by [SQL](https://en.wikipedia.org/wiki/SQL))
* Can be updated in DB in parallel, by [INSERT query](https://en.wikipedia.org/wiki/Insert_(SQL)) and [DELETE query](https://en.wikipedia.org/wiki/Delete_(SQL))

### Cons
* Takes up memory/storage space/traffic
* Need to write additional code for `set` and `unset` and `find` functions
* Could affect different limitation in case of many flags
* Could affect performance, especially on a client side

### User Cases
In my opinion before using this approach, we should answer "yes" for all listed options in the *checklist*:
* I do not have performance and memory and traffic sensitive clients or services
* I understand it could take up resources on all sides it would be used

## Store In Bitmask
[Bitmask](https://en.wikipedia.org/wiki/Mask_(computing)) is a way when we use [bitwise operations](https://en.wikipedia.org/wiki/Bitwise_operation) to get access to specific *flag*. Every flag stores in a binary data in memory, for example it can be stored in: `byte`, `short`, `int`, `uint`, `long`, `[]byte`, `[]short`, `map[int]byte`, etc.

To see code in action, simply read [README.md from binflags library](https://github.com/aohorodnyk/binflags/blob/main/README.md).

### DB Example
In DB we can store bitmask in various types, like: `TINYINT`, `SMALLINT`, `MEDIUMINT`, `INT`, `BITINT`, `BLOB` types.
| id | username | flags  |
|----|----------|--------|
| 1  | test1    | 1      |
| 2  | test2    | 0      |

In current example, `flags` field has type `INT` and first bit is `is_new` flag.

### JSON Example
In a code or in a NoSQL database representation would be:
```json

[
	{
		"id": 1,
		"username": "test1",
		"flags": 1
	},
	{
		"id": 2,
		"username": "test2",
		"flags": 0
	}
]
```

### Pros
* Simple to understand
* The fastest implementation for all operations with flags
* Do not take up additional memory and traffic resources (always only 1 bit per flag)
* Can be used in search by DB (but cannot be efficiently used indexes)

### Cons
* In some cases flags cannot be updated in parallel
* Cannot search flags by index
* Have to be documented (name to bit mapping)
* Should be explained for some people

### Use Cases
In my opinion before using this approach, we should answer "yes" for all listed options in the *checklist*:
* I want to save memory/traffic/processor resources
* I understand all limitations

# Conclusion
As we can see, as usual, we do not have *silver bullet* for all use cases and systems. But provided list of implementations can help to find the best solution for a specific project.

If you want to use the most efficient option in [Go](https://golang.org), I would suggest to check [Go implementation of binary flags for various types](https://github.com/aohorodnyk/binflags).
