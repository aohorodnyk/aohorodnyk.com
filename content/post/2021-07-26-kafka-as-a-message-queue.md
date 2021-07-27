---
title: "Kafka as a message queue"
description: "Small, but very important part for people who wants to choose kafka as a message queue."
author: "Anton Ohorodnyk"
date: "2021-07-26T10:00:00-07:00"
type: "post"
mermaid: false
---
## Disclaimer
> Small, but very important part for people who wants to choose kafka as a message queue

Kafka is a great tool for data processing in streaming mode. It can help to build great tools, especially when we need to analyze some streaming data (like users analytics, some events, etc. Kafka as a storage with Kafka streams will help to process even some data that has name “big data”.

However this article will describe only one use case where Kafka can be used as well.

This task has name "message queue". It is an important part of every project I was involved. People try to solve this task in different ways:
- Use designed tool for that (like NSQ, RabbitMQ, Gearman, etc.)
- Build message queue on the top of their db (PostgreSQL, MySQL, Redis, etc.)
- Try to delegate all tasks required message queue to external services, to avoid an implementation

Kafka pretends to be used as a designed tool for this specific task as well as it provides awesome guarantees. We will review only this part. I hope it will help us to understand is Kafka right tool for a next project.

Also we will skip partitions[^main_concepts] part.

[^main_concepts]: [The main concepts of Kafka]([https://kafka.apache.org/documentation/#intro_concepts_and_terms](https://kafka.apache.org/documentation/#intro_concepts_and_terms)). I did not find direct link to Kafka documentation that explains only partitions part.

### Message queue (MSQ)

Before review implementation of the patter in Kafka, let's overview it is in general.

Simple message processing usually splits to two different parts:
- Producer (who sends message to a queue)
- Consumer (who consumes message from queue)

If we want to provide guarantees that message was processed at least once, we need to introduce some acknowledge method to our message processing pattern. Let's add commit method:
- Committer (sends acknowledge to message queue that message processed and we want to stop sending it to a consumer)

As a result we will have three methods for our message queue:
- Produce
- Consume
- Commit

Example with simple flow with one message:
- A producer sends a message to a queue
- A cunsumer received this message and try to process it
- If consumer fail (or after some time, depends on an implementation) and message was not committed, a consumer will receive this message one more time (go to option 2)
- Commit message (do not send it to a consumer anymore)

![Message Queue Diagram](/post/kafka-msq/msq-general.svg)

## Kafka message queue key features
First of all let's do an overview of the main features you will deal with, when you choose Kafka as a message queue.

This information we need to understand the main concepts we will work with. We will not only deal with an event publishing and consumption, there are more thinks we will deal with.

### Message stream
Message queue in Kafka build over Kafka message stream. Actually message stream is just storage with all messages sequently persisted. Data from the storage can be read by batches of them with specific size in bytes.

> Kafka can be used as a storage to read the data and build some decisions on top of it.
This solution is usually used in Data Science.
If we need to speed-up calculation over the data, we can use Kafka Streams[^kafka_streams].

[^kafka_streams]: [Kafka Streams](https://kafka.apache.org/documentation/streams/) is a solution to run code on data side to speed up processing. I'd tell it seem to be stored procedures from SQL.

When we want to use Kafka as message queue. We read batch of messages[^read_batch_message] with some shift, parse them and start to process.

[^read_batch_messages]: Actually, every time Kafka client reads data from Kafka with some size limit, as it works in file reading.

### Partitions
This article should not focus on partitions feature in Kafka, but unfortunately it's not possible to skip the topic in a consumer/producer context.

>  Warn: All messages with the same key (for example user_uuid) will be send to the same partition.
>
> BE CAREFUL!

When we create topic we can specify number of partitions (for example 3). Base on message key (usualy generated UUIDv4) Kafka client will choose one of the partition and send message to this partition.

![Kafka partitions](/post/kafka-msq/kafka-partitions.svg)

Diagram above shows an idea how Kafka client sort messages between partitions.
Partitions from topics used for Kafka distribution (add new nodes to a cluster) and consumer distribution as well [see consumer paragraph](#consumer).

### Producer
Producer works in the simplest way. We just produce message[^producer] (send it to Kafka). Nothing special we want to discuss.

[^producer]: It requires a message key to specify a partition. Usually client will provider some UUIDv4 by default, so, we can ignore it.

### Consumer
> As we agreed before, we will not review partitions part. In this stage we will work only with group readers.

Kafka provides _consumer groups_ feature. _Group ID_ should be provided[^consumer_group_id_partitions] by a consumer that reads from a topic.

[^consumer_group_id_partitions]: A consumer can avoid _group id_, if it will subscribe to specific partition. But it's not our case.

[Partitions](#partitions) used to distribute messages between consumers.
Group ID is used by Kafka to identify messages need to be delivered to specific consumer. It automatically distributes partitions between consumers from the same group (Group ID).

Two consumers from the same group will not receive the same message, becuase of every consumer will follow their specific partition(s) and receive message from them (if we use user_uuid as a message key, then all messages from the same user will always be sent to the same partition and processed by the same consumer).

![Consumer partitions](/post/kafka-msq/kafka-consumers-partitions.svg)

As we can see on diagram consumers automatically assign between partitions while they running.

> Warn: If we have more consumers than partitions, some of them will idle.

### Commit message
When we choose message queue pattern we expect to work with messages individually. We expect to commit messages individually.

![Commit messages unordered](/post/kafka-msq/commit-messages-unordered.svg)

On diagram above we can see the example of our expectation. If we do not commit some individual message, we will receive it again in near future, but it will not stop processing for next messages.

As we discussed, Kafka does not provide an API to work with messages individually, so, we will shift our pointer of read messages.
If we skip one message and do not want to commit it, we cannot move forward and we need to wait until this message will be processed or ignored to be ready to shift our pointer and move forward to next batch.

![Shift pointer](/post/kafka-msq/shift-pointer.svg)

Follow the diagram we can see that we have to process all messages in any way, if we want to move forward.


> Warn: Kafka will not solve us individual message processing task. We have to think about a use case when message cannot be processed.

## Conclusion
Kafka is powerful tool for message processing, but as any other tools it has some limitations.
It can solve a task with billions of messages and it's fast solution and  it's solution with fault-tolerance out of the box. However we have to pay for these great features by increased complexity.

When we choose Kafka for message queue task, instead of, for example, RabbitMQ, let's remember about limitations and architecture decisions to cover edge cases in our code itself to make our product the best.

The main point I would like to highlight one more time:
* Remember about limitations with partitions
* Do not forget that you cannot commit individual messages
* Do not forget to commit all messages to avoid stucking in a queue

I hope this article will help somone to avoid the main mistakes while working with Kafka at first time.
