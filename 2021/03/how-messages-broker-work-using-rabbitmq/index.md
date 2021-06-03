# How Messages Broker Work Using RabbitMQ


<!--more-->

### What is Message Broker?

![GraphQL Modelling](/images/exchanges-topic-fanout-direct.png)

A message broker is software that enables applications, systems, and services to communicate with each other and exchange information. The message broker does this by translating messages between formal messaging protocols. This allows interdependent services to “talk” with one another directly, even if they were written in different languages or implemented on different platforms.

Message brokers are software modules within messaging middleware or message-oriented middleware (MOM) solutions. This type of middleware provides developers with a standardized means of handling the flow of data between an application’s components so that they can focus on its core logic. It can serve as a distributed communications layer that allows applications spanning multiple platforms to communicate internally.

### Step to create message broker using RabbitMQ

**First thing**

You already have a RabbitMQ server and activate RabbitMQ management, please follow this link [Install RabbitMQ](https://www.rabbitmq.com/download.html)

**Starting with spring initializr**

Generate two project maven from [Spring Initializr](https://start.spring.io/). First is `rabbitmq` and second is `rabbitmq-listener`.

Here my `pom.xml` from `rabbitmq` project.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		 xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.3.4.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.example</groupId>
	<artifactId>rabbitmq</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>rabbitmq</name>
	<description>Demo project for Spring Boot</description>
	<properties>
		<java.version>11</java.version>
	</properties>
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
			<exclusions>
				<exclusion>
					<groupId>org.springframework.boot</groupId>
					<artifactId>spring-boot-starter-tomcat</artifactId>
				</exclusion>
			</exclusions>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-undertow</artifactId>
		</dependency>

		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>

		<!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-amqp -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-amqp</artifactId>
			<version>2.4.1</version>
		</dependency>

		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
			<artifactId>jackson-databind</artifactId>
		</dependency>

	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<excludes>
						<exclude>
							<groupId>org.projectlombok</groupId>
							<artifactId>lombok</artifactId>
						</exclude>
					</excludes>
				</configuration>
			</plugin>
		</plugins>
	</build>

</project>
```

And here is `pom.xml` from `rabbitmq-listener` project.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.4</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.example.</groupId>
	<artifactId>rabbitmq-listener</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>rabbitmq-listener</name>
	<description>Demo project for Spring Boot</description>
	<properties>
		<java.version>11</java.version>
	</properties>
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-amqp</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>

		<dependency>
			<groupId>org.springframework.amqp</groupId>
			<artifactId>spring-rabbit-test</artifactId>
			<scope>test</scope>
		</dependency>

		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>

		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
			<artifactId>jackson-databind</artifactId>
		</dependency>

	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<excludes>
						<exclude>
							<groupId>org.projectlombok</groupId>
							<artifactId>lombok</artifactId>
						</exclude>
					</excludes>
				</configuration>
			</plugin>
		</plugins>
	</build>

</project>
```

### Working with `rabbitmq` as a producers

Update your `application.properties` like below.

```
info.app.name=RabbitMQ Example
info.app.description=RabbitMQ Example
info.app.version=1.0.0
spring.jmx.enabled=false
spring.rabbitmq.host=localhost
spring.rabbitmq.username=guest
spring.rabbitmq.password=guest
spring.rabbitmq.port=5672
server.port=8080
```

Create constant value for queue name in package `com.example.rabbitmq.constant`.

```java
public class QueueConstant {

    public final static String HELLO_WORLD = "hello-world";
    public final static String EMAIL = "email-sender";

}
```

Create bean configuration to register queue in package `com.example.rabbitmq.configuration`.

```java
@Configuration
public class QueueConfiguration {

    @Bean
    public Queue helloWorld() {
        return new Queue(QueueConstant.HELLO_WORLD);
    }

    @Bean
    public Queue sendEmail() {
        return new Queue(QueueConstant.EMAIL);
    }

}
```

Create message sender to send a message to RabbitMQ `com.example.rabbitmq.service`.

```java
@Service
public class MessagesSender {

    private final static Logger log = LoggerFactory.getLogger(MessagesSender.class);

    @Autowired
    private RabbitTemplate rabbitTemplate;

    public void send(String name) {
        log.info("Sending message to RabbitMQ...");
        rabbitTemplate.convertAndSend(QueueConstant.HELLO_WORLD, String.format("Hello my name is %s", name));
    }

}
```

Create endpoint to send message dinamically from REST `com.example.rabbitmq.controller`.

```java
@RestController
public class ApplicationController {

    private final MessagesSender messagesSender;

    @Autowired
    public ApplicationController(MessagesSender messagesSender) {
        this.messagesSender = messagesSender;
    }

    @PostMapping(value = "/hello-world", name = "Hello World")
    public Map<String, String> hello(@RequestBody Map<String, String> request) {
        messagesSender.send(request.get("name"));

        Map<String, String> ret = new HashMap<>();
        ret.put("message", "sending message...");
        return ret;
    }

}
```

Run spring boot by typing `mvn spring-boot:run` then open Postman like below.

`URL: http://localhost:8080/hello-world (POST)`

![Hello world request and response](/images/rabbitmq-1.png)

```js
2021-03-28 02:02:54.952  INFO 54639 --- [  XNIO-1 task-1] c.e.rabbitmq.service.HelloWorldSender    : Sending message to RabbitMQ...
2021-03-28 02:02:54.957  INFO 54639 --- [  XNIO-1 task-1] o.s.a.r.c.CachingConnectionFactory       : Attempting to connect to: [localhost:5672]
2021-03-28 02:02:55.107  INFO 54639 --- [  XNIO-1 task-1] o.s.a.r.c.CachingConnectionFactory       : Created new connection: rabbitConnectionFactory#4adc663e:0/SimpleConnection@43156916 [delegate=amqp://guest@127.0.0.1:5672/, localPort= 53933]
2021-03-28 02:02:55.124  INFO 54639 --- [  XNIO-1 task-1] o.s.amqp.rabbit.core.RabbitAdmin         : Auto-declaring a non-durable, auto-delete, or exclusive Queue (hello-world) durable:false, auto-delete:false, exclusive:false. It will be redeclared if the broker stops and is restarted while the connection factory is alive, but all messages will be lost.
```

And go to RabbitMQ management by accessing `http://localhost:15672` by default username and password is `guest` then go to `Queues` tab.

![Hello world queues](/images/rabbitmq-2.png)

Scroll down to `Get Message` menu, make sure the message is exists in the queue. Should be like below.

![Hello world messages](/images/rabbitmq-3.png)

Try another message to RabbitMQ, we will send a json string message. Update `com.example.rabbitmq.service.MessageSender.java` like below.

```java
@Service
public class MessagesSender {

    private final static Logger log = LoggerFactory.getLogger(MessagesSender.class);

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private ObjectMapper mapper;

    public void send(String name) {
        log.info("Sending message to RabbitMQ...");
        rabbitTemplate.convertAndSend(QueueConstant.HELLO_WORLD, String.format("Hello my name is %s", name));
    }

    public void sendEmail(Map<String, String> map) {
        log.info("Sending message to RabbitMQ...");
        try {
            rabbitTemplate.convertAndSend(QueueConstant.EMAIL, mapper.writeValueAsString(map));
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }

}
```

Update rest controller `com.example.rabbitmq.controller.ApplicationController.java`.

```java
@RestController
public class ApplicationController {

    private final MessagesSender messagesSender;

    @Autowired
    public ApplicationController(MessagesSender messagesSender) {
        this.messagesSender = messagesSender;
    }

    @PostMapping(value = "/hello-world", name = "Hello World")
    public Map<String, String> hello(@RequestBody Map<String, String> request) {
        messagesSender.send(request.get("name"));

        Map<String, String> ret = new HashMap<>();
        ret.put("message", "sending message...");
        return ret;
    }

    @PostMapping(value = "/sendEmail", name = "Send Email")
    public Map<String, String> sendEmail(@RequestBody Map<String, String> request) {
        messagesSender.sendEmail(request);

        Map<String, String> ret = new HashMap<>();
        ret.put("message", "sending your email...");
        return ret;
    }

}
```

Run spring boot by typing `mvn spring-boot:run` then open Postman like below.

`URL: http://localhost:8080/sendEmail (POST)`

![Send email request and response](/images/rabbitmq-4.png)

```js
2021-03-28 02:33:35.980  INFO 60764 --- [  XNIO-1 task-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 10 ms
2021-03-28 02:33:36.051  INFO 60764 --- [  XNIO-1 task-1] c.example.rabbitmq.service.EmailSender   : Sending message to RabbitMQ...
```

And go to RabbitMQ management then go to `Queues` tab.

![Send email queues](/images/rabbitmq-5.png)

Scroll down to `Get Message` menu, make sure the message is exists in the queue. Should be like below.

![Send email messages](/images/rabbitmq-6.png)

### Working with `rabbitmq-listener` as a concumers

Update your `application.properties` like below.

```
info.app.name=RabbitMQ Listener Example
info.app.description=RabbitMQ Listener Example
info.app.version=1.0.0
spring.jmx.enabled=false
spring.rabbitmq.host=localhost
spring.rabbitmq.username=guest
spring.rabbitmq.password=guest
spring.rabbitmq.port=5672
```

Create bean configuration to inject `ObjectMapper` dependencies in package `com.example.rabbitmqlistener.config`.

```java
@Configuration
public class BeanConfiguration {

    @Bean
    public ObjectMapper mapper() {
        return new ObjectMapper();
    }

}
```

Create constant value for queue name in package `com.example.rabbitmqlistener.constant`.

```java
public class QueueConstant {

    public final static String HELLO_WORLD = "hello-world";
    public final static String EMAIL = "email-sender";

}
```

Create bean configuration to register queue in package `com.example.rabbitmqlistener.configuration`.

```java
@Configuration
public class QueueConfiguration {

    @Bean
    public Queue helloWorld() {
        return new Queue(QueueConstant.HELLO_WORLD);
    }

    @Bean
    public Queue sendEmail() {
        return new Queue(QueueConstant.EMAIL);
    }

}
```

Create model `com.example.rabbitmqlistener.model.EmailModel` used mapping message into class object.

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmailModel {

    private String from;

    private String to;

    private String subject;

    private String message;

    private String name;

}
```

Create listener `com.example.rabbitmqlistener.service.MessageListenerService` to listen message from RabbitMQ by queues name.

```java
@Service
public class MessageListenerService {

    private final static Logger log = LoggerFactory.getLogger(MessageListenerService.class);

    private final ObjectMapper mapper;

    @Autowired
    public MessageListenerService(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    @RabbitListener(queues = QueueConstant.HELLO_WORLD)
    public void greeting(String message) {
        log.info("Receiving message...");
        log.info("Message is: " + message);
    }

    @RabbitListener(queues = QueueConstant.EMAIL)
    public void sendEmail(String message) {
        log.info("Receiving message: " + message);
        try {
            EmailModel email = mapper.readValue(message, EmailModel.class);
            log.info("Converting to model...");
            log.info("EmailModel:: " + email.toString());
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
    }

}
```

Run spring boot by typing `mvn spring-boot:run` and see the logs.

```js
2021-03-28 11:11:56.224  INFO 67938 --- [ntContainer#0-1] c.e.r.service.MessageListenerService     : Receiving message...
2021-03-28 11:11:56.226  INFO 67938 --- [ntContainer#0-1] c.e.r.service.MessageListenerService     : Message is: Hello my name is Maverick
2021-03-28 11:13:18.721  INFO 68207 --- [ntContainer#1-1] c.e.r.service.MessageListenerService     : Receiving message: {"to":"maverick@test.com","from":"calvinjoe@test.com","message":"Hello, you got message from RabbitMQ","subject":"RabbitMQ Information","name":"Maverick"}
2021-03-28 11:13:18.787  INFO 68207 --- [ntContainer#1-1] c.e.r.service.MessageListenerService     : Converting to model...
2021-03-28 11:13:18.813  INFO 68207 --- [ntContainer#1-1] c.e.r.service.MessageListenerService     : EmailModel:: EmailModel(from=calvinjoe@test.com, to=maverick@test.com, subject=RabbitMQ Information, message=Hello, you got message from RabbitMQ, name=Maverick)
```

### Clone or Download

You can clone or download this project
```bash
https://github.com/piinalpin/rabbitmq.git
```

### Thankyou

[IBM](https://www.ibm.com/cloud/learn/message-brokers) - Message Brokers

[Baeldung](https://www.baeldung.com/spring-amqp) - Messaging with Spring AMQP