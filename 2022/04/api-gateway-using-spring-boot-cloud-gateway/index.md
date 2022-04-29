# Api Gateway Using Spring Boot Cloud Gateway + Netflix Hystrix


![API Gateway Concept](/images/api-gateway.png)

An API gateway is an interface between clients and backend microservices. When a gateway is used, it becomes the single point of contact for clients; it receives their API calls and routes each one to the appropriate backend.

It facilitates microservice architectures. When an API gateway is used, clients do not know (nor should they know) the structure of the backend. Modern architectures discourage the use of large monolithic services; rather, numerous small microservices are preferred. This approach provides some compelling advantages, but it does introduce significant complexity. An API gateway mitigates this for the client.

### What is Spring Cloud Gateway?

Spring Cloud Gateway provides a library for building API gateways on top of Spring and Java. It provides a flexible way of routing requests based on a number of criteria, as well as focuses on cross-cutting concerns such as security, resiliency, and monitoring.

Spring Cloud allows developers to implement things such as distributed configuration, service registration, load balancing, the circuit breaker pattern, and more. It provides these tools to implement many common patterns in distributed systems.

Spring cloud gateway is working by clients make requests to Spring Cloud Gateway. If the Gateway Handler Mapping determines that a request matches a Route, it is sent to the Gateway Web Handler. This handler runs sends the request through a filter chain that is specific to the request. The reason the filters are divided by the dotted line, is that filters may execute logic before the proxy request is sent or after. All "pre" filter logic is executed, then the proxy request is made. After the proxy request is made, the "post" filter logic is executed.

### Project Setup and Dependency

I'm depending [Spring Initializr](https://start.spring.io/) for this as it is much easier.

We need import spring bloot cloud gateway dependencies, such as:
- `spring-cloud-starter-gateway`
- `spring-boot-starter-actuator`

Here the `pom.xml` like following below.

```xml
<dependencies>
  <dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
  </dependency>

  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
  </dependency>

  <dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
    </dependency>
</dependencies>
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.springframework.cloud</groupId>
      <artifactId>spring-cloud-dependencies</artifactId>
      <version>${spring-cloud.version}</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

Change configuration `application.properties` file to setup spring cloud gateway and actuator like following below.

```bash
server.port=8080
spring.application.name=api-gateway
spring.main.web-application-type=reactive

management.endpoints.web.exposure.include=*
management.endpoints.web.cors.allowed-origins=true
```
### Gateway Filter Factories

Route filters allow the modification of the incoming HTTP request or outgoing HTTP response in some manner. Route filters are scoped to a particular route. Spring Cloud Gateway includes many built-in GatewayFilter Factories.

In this step we will rewrite path from spring cloud gateway to another service, we will use my [Spring Boot Hello World](https://github.com/piinalpin/springboot-helloworld) project as a microservice. Clone and run the project by `mvn spring-boot:run` command. Or you can run the [Spring Boot Hello World Container](https://hub.docker.com/repository/docker/piinalpin/springboot-helloworld) and run with port `8081`.

Add gateway filter factory with creating new file `application.yml` inside main resources.

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: springboot-helloworld
          uri: http://localhost:8081
          predicates:
            - Path=/springboot-helloworld/**
          filters:
            - RewritePath=/springboot-helloworld/(?<segment>/?.*),/api/$\{segment}
```

Run spring boot cloud gateway `http://localhost:8080/springboot-helloworld/`. The result should be has response from `springboot-helloworld` service.

For more documentation of `GatewayFilterFactories` please visit [Spring Cloud Gateway](https://cloud.spring.io/spring-cloud-static/spring-cloud-gateway/2.2.0.RC2/reference/html/#gatewayfilter-factories).

### Resilience4j: Circuit Breaker Implementation

**What is circuit breaker?**

The concept of a circuit breaker is to prevent calls to microservice when it’s known the call may fail or time out. This is done so that clients don’t waste their valuable resources handling requests that are likely to fail. Using this concept, you can give the server some spare time to recover.

So, how do we know if a request is likely to fail? Yeah, this can be known by recording the results of several previous requests sent to other microservices. For example, 4 out of 5 requests sent failed or timeout, then most likely the next request will also encounter the same thing.

![Circuit Breaker State](/images/circuit-breaker-state.png)

In the circuit breaker, there are 3 states Closed, Open, and Half-Open.

- **Closed**: when everything is normal. Initially, the circuit breaker is in a Closed state.
- **Open**: when a failure occurs above predetermined criteria. In this state, requests to other microservices will not be executed and fail-fast or fallback will be performed if available. When this state has passed a certain time limit, it will automatically or according to certain criteria will be returned to the Half-Open state.
- **Half-Open**: several requests will be executed to find out whether the microservices that we are calling are working normally. If successful, the state will be returned to the Closed state. However, if it still fails it will be returned to the Open state.

**Prerequisites**

One of the libraries that offer a circuit breaker features is **Resilience4J** for reactive web flux. We will adding the dependency in `pom.xml`.

```xml
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
  <version>2.2.10.RELEASE</version>
</dependency>

<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-circuitbreaker-reactor-resilience4j</artifactId>
</dependency>
```

**Fallback Command**

In the main `Application` add annotation `@EnableHystrix`. And then create `FallbackController` and `ApiResponse` to handle when service backend is unavailable.

```java
@RestController
public class FallbackController {

    @GetMapping(value = "/fallback")
    public ResponseEntity<Object> fallback() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("message", "Gateway Timeout!");
        return new ResponseEntity<>(
            response, 
            HttpStatus.GATEWAY_TIMEOUT
        );
    }
    
}
```

So, that mean when service backend is unavailable will be redirected to `/fallback` as soon as possible.

And add `CircuitBreaker` to `application.yml` like following below.

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: springboot-helloworld
          uri: http://localhost:8081
          predicates:
            - Path=/springboot-helloworld/**
          filters:
            - RewritePath=/springboot-helloworld/(?<segment>/?.*),/api/$\{segment}
            - name: CircuitBreaker
              args:
                name: fallbackcmd
                fallbackUri: forward:/fallback
```

Let's try to shutdown the `springboot-helloworld` service, then go to `http://localhost:8080/springboot-helloworld/`

### Logging with Global Filter

**Global filters** are executed for every route defined in the API Gateway. The main difference between pre-filter and post-filter class is that the pre-filter code is executed before Spring Cloud API Gateway routes the request to a destination web service endpoint. While the post-filter code will be executed after Spring Cloud API Gateway has routed the HTTP request to a destination web service endpoint.

![Spring Cloud Gateway Global Filter Order](/images/spring-cloud-gateway-global-filter-order.webp)

**PreGlobalFilter**

Execute pre filter to call `RequestBodyRewriter` then can be used for logging.

```java
@Configuration
public class PreGlobalFilter implements GlobalFilter, Ordered {

    @Autowired
    private ModifyRequestBodyGatewayFilterFactory filterFactory;

    public static final String ORIGINAL_REQUEST_BODY = "originalRequestBody";

    @Override
    public int getOrder() {
        return NettyWriteResponseFilter.WRITE_RESPONSE_FILTER_ORDER;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        return filterFactory
            .apply(new ModifyRequestBodyGatewayFilterFactory.Config()
                .setRewriteFunction(String.class, String.class, (newExchange, body) -> {
                    String originalBody = null;
                    if (body != null) {
                        originalBody = body;
                    }

                    exchange.getAttributes().put(ORIGINAL_REQUEST_BODY, originalBody);
                    return Mono.just(originalBody);
                }))
            .filter(exchange, chain);
    }
    
}
```

**PostGlobalFilter**

Execute post filter to call `ResponseBodyRewriter` and construct the log message and then can be used for logging.

```java
@Slf4j
@Configuration
public class PostGlobalFilter implements GlobalFilter, Ordered {

    @Autowired
    private ModifyResponseBodyGatewayFilterFactory filterFactory;

    public static final String ORIGINAL_RESPONSE_BODY = "originalResponseBody";

    @Override
    public int getOrder() {
        return NettyWriteResponseFilter.WRITE_RESPONSE_FILTER_ORDER + 1;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        GatewayFilter delegate = filterFactory
            .apply(new ModifyResponseBodyGatewayFilterFactory.Config()
                .setRewriteFunction(byte[].class, byte[].class, (newExchange, body) -> {
                    String originalBody = null;
                    if (body != null) {
                        originalBody = new String(body);
                    }

                    exchange.getAttributes().put(ORIGINAL_RESPONSE_BODY, originalBody);
                    return Mono.just(originalBody.getBytes());
                }));
        return delegate
            .filter(exchange, chain)
            .then(Mono.fromRunnable(() -> {
                this.writeLog(exchange);
            }));
    }

    private void writeLog(ServerWebExchange exchange) {
        ServerHttpRequest request = exchange.getRequest();
        ServerHttpResponse response = exchange.getResponse();

        String requestBody = exchange.getAttribute(PreGlobalFilter.ORIGINAL_REQUEST_BODY);
        String responseBody = exchange.getAttribute(PostGlobalFilter.ORIGINAL_RESPONSE_BODY);

        StringBuilder sb = new StringBuilder();
        sb.append("\n");

        URI uri = exchange.getAttribute(ServerWebExchangeUtils.GATEWAY_REQUEST_URL_ATTR);
        sb.append("URI: ").append(uri).append("\n");
        sb.append("Method: ").append(request.getMethod()).append("\n");
        sb.append("Request Headers: ");

        request.getHeaders().forEach((key, value) -> {
            sb.append(key).append("=").append(value).append(", ");
        });
        sb.append("\n");
        sb.append("Request Body: ").append(requestBody).append("\n");

        sb.append("\n");
        sb.append("Response Status: ").append(response.getRawStatusCode()).append("\n");
        sb.append("Response Headers: ");
        response.getHeaders().forEach((key, value) -> {
            sb.append(key).append("=").append(value).append(", ");
        });
        sb.append("\n");
        sb.append("Response Body: ").append(responseBody).append("\n");
        
        log.info(sb.toString());
        exchange.getAttributes().remove(PreGlobalFilter.ORIGINAL_REQUEST_BODY);
        exchange.getAttributes().remove(PostGlobalFilter.ORIGINAL_RESPONSE_BODY);
    }
    
}
```

### Conclusion
In this article, we explored some of the features and components that are part of Spring Cloud Gateway. This new API provides out-of-the-box tools for gateway and proxy support.

### Reference
- [What is Spring Cloud Gateway?](https://tanzu.vmware.com/developer/guides/scg-what-is/)
- [Resilience4J: Circuit Breaker Implementation on Spring Boot](https://medium.com/bliblidotcom-techblog/resilience4j-circuit-breaker-implementation-on-spring-boot-9f8d195a49e0)
- [Spring Cloud API Gateway Global Filter Example](https://www.appsdeveloperblog.com/spring-cloud-api-gateway-global-filter-example/)
- [Microservices using SpringBoot | Full Example](https://www.youtube.com/watch?v=BnknNTN8icw)
- [Spring Cloud Gateway](https://cloud.spring.io/spring-cloud-gateway/reference/html/)
- [Spring Cloud Gateway - Proxy/Forward the entire sub part of URL](https://stackoverflow.com/questions/48865174/spring-cloud-gateway-proxy-forward-the-entire-sub-part-of-url)
- [Spring Cloud Circuit Breaker](https://cloud.spring.io/spring-cloud-circuitbreaker/reference/html/spring-cloud-circuitbreaker.html#default-configuration)
- [Writing Custom Spring Cloud Gateway Filters](https://www.baeldung.com/spring-cloud-custom-gateway-filters)
- [Get request body string from ServerHttpRequest / Flux<DataBuffer>](https://stackoverflow.com/questions/57562873/get-request-body-string-from-serverhttprequest-fluxdatabuffer)
- [How to get response body in Spring Gateway](https://stackoverflow.com/questions/64439102/how-to-get-response-body-in-spring-gateway)
