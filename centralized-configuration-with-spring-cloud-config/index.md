# Centralized Configuration with Spring Cloud Config


### What is Configuration as a Service

![Spring Cloud Config](/images/spring-cloud-config-roadmap.jpg)

In micro-service world, managing configurations of each service separately is a tedious and time-consuming task. In other words, if there are many number of modules, and managing properties for each module with the traditional approach is very difficult.

Central configuration server provides configurations (properties) to each micro service connected. As mentioned in the above diagram, Spring Cloud Config Server can be used as a central cloud config server by integrating to several environments.

**Environment Repository** — Spring uses environment repositories to store the configuration data. it supports various of authentication mechanisms to protect the configuration data when retrieving.

**Spring Cloud Config** is Spring's client/server approach for storing and serving distributed configurations across multiple applications and environments.

This configuration store is ideally versioned under Git version control and can be modified at application runtime. While it fits very well in Spring applications using all the supported configuration file formats together with constructs like Environment, PropertySource or @Value, it can be used in any environment running any programming language.

In this write-up, we'll focus on an example of how to setup a Git-backed config server, use it in a simple REST application server and setup a secure environment including encrypted property values.

### Project Setup and Dependencies

I'm depending [Spring Initializr](https://start.spring.io/) for this as it is much easier. And we have to create two spring boot projects and started with maven project.

- config-server
- config-client

To get ready for writing some code, we create two new Maven projects first. The server project is relying on the `spring-cloud-config-server` module, as well as the `spring-boot-starter-security` and `spring-boot-starter-web` starter bundles.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
    <version>2.5.2</version>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-server</artifactId>
    <version>3.0.4</version>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

However for the client project we're going to only need the `spring-cloud-starter-config`, `spring-cloud-starter-bootstrap` and the `spring-boot-starter-web` modules.

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
    <version>3.0.4</version>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bootstrap</artifactId>
    <version>3.0.3</version>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

### Config Server Implementation

The main part of the application is a config class – more specifically a @SpringBootApplication – which pulls in all the required setup through the auto-configure annotation `@EnableConfigServer`.

```java
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {

	public static void main(String[] args) {
		SpringApplication.run(ConfigServerApplication.class, args);
	}

}
```

We also need to set a username and a password for the Basic-Authentication in our `application.properties` to avoid an auto-generated password on every application restart.

```bash
spring.cloud.config.server.git.uri=<CHANGE YOUR GITHUB REPOSITORY>
spring.cloud.config.server.git.clone-on-start=true
spring.security.user.name=root
spring.security.user.password=secret
spring.application.name=config-server
server.port=8080
```

### Git Repository as Configuration Storage
To complete our server, we have to initialize a Git repository under the configured url, create some new properties files and popularize them with some values.

We will use a configuration yaml file lika a normal Spring `application.yml`, but instead of the word ‘application' a configured name, e.g. the value of the property ‘spring.application.name' of the client is used, followed by a dash and the active profile. We will create 3 yaml files of configuration.

- config-client-local.yml
- config-client-development.yml
- config-client-production.yml

**config-client-local.yml**

```yaml
app:
  name: "spring-cloud-config-client.local"
  website: "http://piinalpin.com"
config:
  profile: "local"
server:
  port: 8081
```

**config-client-development.yml**

```yaml
app:
  name: "spring-cloud-config-client.dev"
  website: "http://piinalpin.com"
config:
  profile: "development"
server:
  port: 7001
```

**config-client-production.yml**

```yaml
app:
  name: "spring-cloud-config-client.prod"
  website: "http://piinalpin.com"
config:
  profile: "production"
server:
  port: 9001
```

### Querying the Configuration

Now we're able to start our server. The Git-backed configuration API provided by our server can be queried using the following paths.

```bash
/{application}/{profile}[/{label}]
/{application}-{profile}.yml
/{label}/{application}-{profile}.yml
/{application}-{profile}.properties
/{label}/{application}-{profile}.properties
```

In which the {label} placeholder refers to a Git branch, {application} to the client's application name and the {profile} to the client's current active application profile.

So we can retrieve the configuration for our planned config client running under local profile in branch `master` via.

```bash
 curl http://root:secret@localhost:8080/config-client/local/master
```

Then we got a response like below.

```json
{
  "name": "config-client",
  "profiles": [
    "local"
  ],
  "label": "master",
  "version": "de4a15d886d53050ec4bbe80e939106259614803",
  "state": null,
  "propertySources": [
    {
      "name": "https://github.com/piinalpin/spring-cloud-config.git/config-client-local.yml",
      "source": {
        "app.name": "spring-cloud-config-client.local",
        "app.website": "http://piinalpin.com",
        "config.profile": "local",
        "server.port": 8081
      }
    }
  ]
}
```

### Client Implementation

Next, let's take care of the client. This will be a very simple client application, consisting of a REST controller with one GET method.

Now, We will create a controller in `com.maverick.configclient.controller.ConfigClientController` like below.

```java
@RestController
public class ConfigClientController {

    @Value("${config.profile:}")
    private String profile;

    @Value("${app.name:}")
    private String appName;

    @GetMapping(path = "/")
    public Map<String, String> main() {
        Map<String, String> map = new HashMap<>();
        map.put("activeProfile", profile);
        map.put("appName", appName);
        return map;
    }

}
```

The configuration, to fetch our server, must be placed in a resource file named `bootstrap.application`, because this file (like the name implies) will be loaded very early while the application starts.

```bash
spring.application.name=config-client
spring.cloud.config.uri=http://localhost:8080
spring.cloud.config.username=root
spring.cloud.config.password=secret
spring.profiles.active=local
```

To test, if the configuration is properly received from our server and the role value gets injected in our controller method, we simply `curl` it after booting the client.

```bash
curl http://localhost:<PORT_ACTIVE_PROFILE>
```

If the response is as follows, our Spring Cloud Config Server and its client are working fine for now.

```json
{"activeProfile":"local","appName":"spring-cloud-config-client.local"}
```

### Clone or Download

You can clone or download this project
```bash
https://github.com/piinalpin/spring-cloud-config.git
```

### Thankyou

[Medium](https://medium.com/@ijayakantha/microservices-centralized-configuration-with-spring-cloud-f2a1f7b78cc2) - Microservices Centralized Configuration with Spring Cloud

[Baeldung](https://www.baeldung.com/spring-cloud-configuration) - Quick Intro to Spring Cloud Configuration

[Github](https://github.com/chuchip/servercloudconfig) - Servidor Configuraciones en Spring Cloud
