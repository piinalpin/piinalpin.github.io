# Messaging on Kafka-CLI With Spring Boot


### Overview

Kafka is a distributed system consisting of servers and clients that communicate via a high-performance TCP network protocol. It can be deployed on bare-metal hardware, virtual machines, and containers in on-premise as well as cloud environments.

Servers: Kafka is run as a cluster of one or more servers that can span multiple datacenters or cloud regions. Some of these servers form the storage layer, called the brokers. Other servers run Kafka Connect to continuously import and export data as event streams to integrate Kafka with your existing systems such as relational databases as well as other Kafka clusters. To let you implement mission-critical use cases, a Kafka cluster is highly scalable and fault-tolerant: if any of its servers fails, the other servers will take over their work to ensure continuous operations without any data loss.

Clients: They allow you to write distributed applications and microservices that read, write, and process streams of events in parallel, at scale, and in a fault-tolerant manner even in the case of network problems or machine failures. Kafka ships with some such clients included, which are augmented by dozens of clients provided by the Kafka community: clients are available for Java and Scala including the higher-level Kafka Streams library, for Go, Python, C/C++, and many other programming languages as well as REST APIs.

### Prerequisites

Requirement pre-installed `docker` and `docker-compose`

We use kafka server using `docker-compose` like following below, or you can use from original docs on [Quick Start for Apache Kafka using Confluent Platform (Docker)](https://docs.confluent.io/platform/current/quickstart/ce-docker-quickstart.html?utm_medium=sem&utm_source=google&utm_campaign=ch.sem_br.nonbrand_tp.prs_tgt.kafka_mt.xct_rgn.apac_lng.eng_dv.all_con.kafka-docker&utm_term=kafka%20docker&creative=&device=c&placement=&gclid=Cj0KCQjw0emHBhC1ARIsAL1QGNc1oMTRaNfsUp5j6FU_ca_cjDoeaGavPOgls2tmEg2l_q5c9keb_yAaAkccEALw_wcB)

```yaml
---
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:6.2.0
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
  kafka:
    image: confluentinc/cp-kafka:6.2.0
    hostname: kafka
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "29092:29092"
      - "9092:9092"
      - "9101:9101"
    restart: always
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost
```

And run on terminal with following command

```bash
docker-compose up -d
```

For stopping server with following command

```bash
docker-compose down -v
```

### Project Setup and Dependencies

I'm depending [Spring Initializr](https://start.spring.io/) for this as it is much easier. And we have to create two spring boot projects and started with maven project.

Our example application will be a Spring Boot application. So we need to add `spring-kafka` and `spring-boot-starter-web` dependency to our `pom.xml`.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
    <version>2.7.4</version>
</dependency>
```

We also need to create `application.yml` for configuration file.


```yaml
kafka:
  bootstrapAddress: "http://localhost:9092"
server:
  port: 8080
```

### Implementation

**Configuring Topics**

Create constant `com.piinalpin.kafkademo.constant.KafkaTopicConstant`.

```java
public class KafkaTopicConstant {

    public final static String HELLO_WORLD = "hello-world";

}
```

Create bean configuration `com.piinalpin.kafkademo.config.KafkaTopicConfiguration` to define topics on Kafka.

```java
@Configuration
public class KafkaTopicConfiguration {

    @Value("${kafka.bootstrapAddress:}")
    private String bootstrapAddress;

    @Bean
    public KafkaAdmin kafkaAdmin() {
        Map<String, Object> config = new HashMap<>();
        config.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddress);
        return new KafkaAdmin(config);
    }

    @Bean
    public NewTopic helloWorld() {
        return new NewTopic(KafkaTopicConstant.HELLO_WORLD, 0, (short) 1);
    }

}
```

**Producer Configuration**

Create bean configuration `com.piinalpin.kafkademo.config.KafkaProducerConfiguration` to define producer configuration bean on Kafka.

```java
@Configuration
public class KafkaProducerConfiguration {

    @Value("${kafka.bootstrapAddress:}")
    private String bootstrapAddress;

    @Bean
    public ProducerFactory<String, String> producerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddress);
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return new DefaultKafkaProducerFactory<>(configProps);
    }

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }

}
```

**Publisher Service**

Create service `com.piinalpin.kafkademo.service.KafkaPublisherService` to publish a message.

```java
@Service
public class KafkaPublisherService {

    public final static Logger log = LoggerFactory.getLogger(KafkaProducerService.class);

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    public void send(String message) {
        log.info("Sending message to Kafka...");
        log.info(String.format("Payload: %s, Topic: %s", KafkaTopicConstant.HELLO_WORLD, message));
        kafkaTemplate.send(KafkaTopicConstant.HELLO_WORLD, message);
    }

}
```

**Send Message**

Create rest controller `com.piinalpin.kafkademo.controller.KafkaDemoController` to send a message via rest.

```java
@RestController
public class KafkaDemoController {

    @Autowired
    private KafkaPublisherService kafkaPublisherService;

    @GetMapping(value = "/")
    public Map<String, String> main() {
        return okMessage("ok");
    }

    @PostMapping(value = "/greeting")
    public Map<String, String> greeting(@RequestBody Map<String, String> request) {
        if (null != request.get("greeting")) {
            kafkaPublisherService.send(request.get("greeting"));
        }
        return okMessage("Sending message...");
    }

    private Map<String, String> okMessage(String message) {
        Map<String, String> ret = new HashMap<>();
        ret.put("message", message);
        return ret;
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below.

`URL: http://localhost:8080/greeting (POST)`

Request Body

```json
{
    "greeting": "Hello my name is Maverick"
}
```

And log will display like below.

```js
2021-07-23 19:27:00.306  INFO 87879 --- [nio-8080-exec-4] c.p.k.service.KafkaProducerService       : Sending message to Kafka...
2021-07-23 19:27:00.307  INFO 87879 --- [nio-8080-exec-4] c.p.k.service.KafkaProducerService       : Payload: hello-world, Topic: Hello my name is Maverick
```

**Consumer Configuration**

For consuming messages, we need to configure a ConsumerFactory and a KafkaListenerContainerFactory. Once these beans are available in the Spring bean factory, POJO-based consumers can be configured using @KafkaListener annotation.

`@EnableKafka` annotation is required on the configuration class to enable detection of `@KafkaListener` annotation on spring-managed beans:

Create bean configuration `com.piinalpin.kafkademo.config.KafkaConsumerConfiguration` to define consumer or listener configuration bean on Kafka.

```java
@Configuration
@EnableKafka
public class KafkaConsumerConfiguration {

    @Value("${kafka.bootstrapAddress:}")
    private String bootstrapAddress;

    public ConsumerFactory<String, String> consumerFactory(String groupId) {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddress);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        return new DefaultKafkaConsumerFactory<>(props);
    }

    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory(String groupId) {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory(groupId));
        return factory;
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> greeting() {
        return kafkaListenerContainerFactory("greeting");
    }

}
```

**Consuming Messages**

Create service `com.piinalpin.kafkademo.service.KafkaConsumerService` as a listener to consume message from Kafka.

```java
@Service
public class KafkaConsumerService {

    private final static Logger log = LoggerFactory.getLogger(KafkaConsumerService.class);

    @KafkaListener(topics = KafkaTopicConstant.HELLO_WORLD, containerFactory = "greeting")
    public void greeting(String payload) {
        log.info(String.format("Received payload: %s", payload));
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below.

`URL: http://localhost:8080/greeting (POST)`

Request Body

```json
{
    "greeting": "Hello my name is Maverick"
}
```

And log will display like below.

```js
2021-07-23 20:57:09.511  INFO 8569 --- [nio-8080-exec-2] c.p.k.service.KafkaPublisherService      : Sending message to Kafka...
2021-07-23 20:57:09.511  INFO 8569 --- [nio-8080-exec-2] c.p.k.service.KafkaPublisherService      : Payload: hello-world, Topic: Hello my name is Maverick

2021-07-23 20:57:09.565  INFO 8569 --- [ad | producer-1] org.apache.kafka.clients.Metadata        : [Producer clientId=producer-1] Cluster ID: wlyOQ1ksRQ6eVAu6Q0JXYA
2021-07-23 20:57:09.798  INFO 8569 --- [ntainer#0-0-C-1] c.p.k.service.KafkaConsumerService       : Received payload: Hello my name is Maverick
```

### Clone or Download

You can clone or download this project
```bash
https://github.com/piinalpin/kafka-demo.git
```

### Thankyou

[Baeldung](https://www.baeldung.com/spring-kafka) - Intro to Apache Kafka with Spring

[Medium](https://medium.com/@TimvanBaarsen/apache-kafka-cli-commands-cheat-sheet-a6f06eac01b) - Apache Kafka CLI commands cheat sheet

[Github](https://github.com/eugenp/tutorials/tree/master/spring-kafka) - Spring Kafka

[Stack Overflow](https://stackoverflow.com/questions/56114299/how-to-set-groupid-to-null-in-kafkalisteners) - How to set groupId to null in @KafkaListeners

[Programmer Sought](https://www.programmersought.com/article/11374013179/) - Springboot integrated kafka-No group.id found in consumer config
