---
title: "Is Redis merely caching system?"
description: "The article explains why Redis and Memcache should be considered as matured full-fledged databases, rather than just caching systems, and why this distinction is important for software engineers."
author: "Anton Ohorodnyk"
date: "2023-03-17T21:00:00-07:00"
type: "post"
---
## Background

Improving the performance of distributed applications is a common task for backend software engineers, especially when multiple servers use a database to retrieve data and generate responses. Communication among engineers occurs frequently and often revolves around work-related topics and technology.

Redis and Memcache are commonly referred to as caching systems or cache services, even by experienced individuals, but they should be recognized as full-fledged databases due to their maturity and functionality. This article will explore the reasons why it is important to recognize Redis and Memcache as databases.

## Defintions

In order to review the topic, it is necessary to establish clear definitions.

### Cache

In my understanding, cache refers to a software layer that stores precalculated results from previous computations, which can be utilized to avoid repeated calculations. Although some people view it as a quick storage solution, I believe this is debatable, as the primary objective of caching is to enhance performance by using a tool that provides adequate speed to achieve significant improvements.

For instance, consider Full Page Cache[^full_page_cache] as an example. Some websites may take a considerable amount of time[^seconds_to_render] to load a page. To enhance performance, developers may include an extra table in MySQL[^mysql], where they can save fully rendered pages. This strategy reduced the load time from 15 seconds to 100ms, which is a significant improvement that negates the need for high-speed storage solutions.

#### Cache definitions from Wiki and AI

There is a definition from [Wikipedia](https://en.wikipedia.org/wiki/Cache_(computing)).

> In computing, a **cache** (*/kæʃ/* (listen) *KASH*) is a hardware or software component that stores data so that future requests for that data can be served faster; the data stored in a cache might be the result of an earlier computation or a copy of data stored elsewhere. A cache hit occurs when the requested data can be found in a cache, while a cache miss occurs when it cannot. Cache hits are served by reading data from the cache, which is faster than recomputing a result or reading from a slower data store; thus, the more requests that can be served from the cache, the faster the system performs.

And let's follow trends and ask Chat-GPT what is cache.

> A cache is a temporary storage area that stores frequently accessed or recently accessed data, which helps to reduce the time it takes to access that data in the future. Caches can be found at various levels in a computer system, such as within a CPU, on a hard disk, or in a web browser. They function by keeping a copy of frequently used data or instructions closer to the processor or application, which decreases the time it takes to retrieve them from their original location. Caches can be hardware or software-based and can be designed to work with various types of data. By using a cache, a system can minimize the time it takes to retrieve data from slower storage devices or networks, leading to faster overall performance and a better user experience.

### Database

A software program, known as a database[^db_dbms] or a DBMS[^db_dbms], is capable of storing data and allowing users to access it for reading and writing purposes through an API[^db_api].

#### Database definitions from Wiki and AI

There is a definition from [Wikipedia](https://en.wikipedia.org/wiki/Database).

> In computing, a **database** is an organized collection of data stored and accessed electronically. Small databases can be stored on a file system, while large databases are hosted on computer clusters or cloud storage. The design of databases spans formal techniques and practical considerations, including data modeling, efficient data representation and storage, query languages, security and privacy of sensitive data, and distributed computing issues, including supporting concurrent access and fault tolerance.

And let's follow trends and ask Chat-GPT what is database.

> A database is a digital collection of organized data that is stored and accessed electronically. It is designed to efficiently store and manage large amounts of information. Typically, a database consists of one or more tables, each containing rows and columns of data. A row represents a single record, while each column represents a different attribute or field of the record. Databases have a wide range of applications, including business operations, scientific research, e-commerce, and social media. To create, modify, and query the data, specialized software called database management systems (DBMS) is used.

## Redis and Memcache

As stated in our definitions, caching is a methodology rather than a particular service. This means that we have the flexibility to utilize any storage solution that suits our requirements in order to construct a cache. Whether it's MySQL, MSSQL, MongoDB, Cassandra, CockroachDB, Redis, Memcached, or simply a hash map in memory within the application, the choice is not significant as long as it meets our needs and assists us in accomplishing our goals.

Redis and Memcache are databases, as they are capable of storing data (primarily in memory) and offering an API for data access. Although they are limited to a predefined storage capacity, they may be suitable as the primary storage for our applications in specific scenarios that align with our requirements. In addition, Redis offers a range of features beyond storage, making it useful for a wide range of tasks.

## Imprortance of naming

Although it may seem that naming is not crucial and we can assign any name we desire, using inaccurate names and definitions for tools may often create biases in our minds.

By enhancing our understanding and naming conventions for various technologies, we can eliminate biases from our perspective, leading to more efficient problem-solving.

## Conclusion

In conclusion, it is crucial to communicate more and ask questions when in doubt. Reading documentation and technical resources can also be helpful in gaining a better understanding of a topic. By doing so, we can avoid biases that can complicate our lives. It's essential to create a culture where asking questions is encouraged, and everyone feels comfortable enough to seek clarity. In this way, we can increase our knowledge, improve our work, and work towards a more inclusive and unbiased environment. So, let's be curious and open to learning, and not let biases hinder our progress.

[^full_page_cache]: Full page cache is a technique when full rendered response of some service (event full website page) are saved after the first render to not rerender it for every request.
[^seconds_to_render]: I've seen websites that spent more than 15 seconds to render a page.
[^mysql]: MySQL is an open-source relational database management system. Link to [Wikipedia](https://en.wikipedia.org/wiki/MySQL).
[^db_dbms]: Within our topic database, there is a DBMS (Database Management System) present. However, since the term "database" is too granular and not relevant to the user experience aspect, it is not of our interest.
[^db_api]: When we speak about DB API we mean any interface that can be used to access data, like Golang interfaces, Java interfaces, SQL, CQL, MQL, etc.
