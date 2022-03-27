# Spring Boot Web Socket Chat Bot


<!--more-->

### Overview

![Spring Boot Web Socket](/images/spring_boot_web_socket_chat_bot.png)

WebSocket is a computer communications protocol, providing full-duplex communication channels over a single TCP connection. The WebSocket protocol was standardized by the IETF as RFC 6455 in 2011, and the WebSocket API in Web IDL is being standardized by the W3C.

The WebSocket protocol enables interaction between a web browser (or other client application) and a web server with lower overhead than half-duplex alternatives such as HTTP polling, facilitating real-time data transfer from and to the server. This is made possible by providing a standardized way for the server to send content to the client without being first requested by the client, and allowing messages to be passed back and forth while keeping the connection open. In this way, a two-way ongoing conversation can take place between the client and the server.

### Project Setup and Dependencies

I'm depending [Spring Initializr](https://start.spring.io/) for this as it is much easier. And we have to create two spring boot projects and started with maven project.

Our example application will be a Spring Boot application. So we need to add `spring-kafka` and `spring-boot-starter-web` dependency to our `pom.xml`.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>

<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

This project will use existing chat bot python on previous documentation, see [Contextual Chat Bot using NLP](https://blog.piinalpin.com/2021/10/contextual-chat-bot/).

Change configuration file in `src/main/resources/application.properties` like following below.

```bash
server.port=8081
chatbot.url=http://localhost:8000
```

### Implementation

**Bean Configuration**

Create bean configuration that can be used for dependency injection at `com.piinalpin.websocketserver.config.BeanConfiguration` like following code.

```java
@Configuration
public class BeanConfiguration {

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        mapper.setDateFormat(new SimpleDateFormat(DateTimeFormat.DATE_TIME));
        mapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
        return mapper;
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

}
```

And also create `WebSocketConfiguration` on package `com.piinalpin.websocketserver.config` like following code.

```java
@Configuration
@EnableWebSocket
@Slf4j
public class WebSocketConfiguration implements WebSocketConfigurer {

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry webSocketHandlerRegistry) {
        webSocketHandlerRegistry.addHandler(getChatWebSocketHandler(), "/chat").setAllowedOrigins("*");
    }

    @Bean
    public WebSocketHandler getChatWebSocketHandler() {
        return new ChatWebSocketHandler();
    }

}
```

**Constant and Data Transfer Object**

Create constant `DateTimeFormat` in package `com.piinalpin.websocketserver.config` like following code.

```java
public class DateTimeFormat {

    private DateTimeFormat() {}

    public static final String DATE_TIME = "dd-MM-yyyy HH:mm:ss";

}
```

And create data transfer object in package `com.piinalpin.websocketserver.domain.dto`

Create `MessageDto` like following code.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonNaming(PropertyNamingStrategy.SnakeCaseStrategy.class)
public class MessageDto implements Serializable {

    private static final long serialVersionUID = -5912093781671152609L;

    private String message;

}
```

Create `MessageResponse` to mapping response from chat bot, like following code..

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonNaming(PropertyNamingStrategy.SnakeCaseStrategy.class)
public class MessageResponse<T extends  Serializable> implements Serializable {

    private static final long serialVersionUID = -7611957408262340406L;

    private String type;

    private T data;

}
```

Create `RiddlesDto` like following code.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonNaming(PropertyNamingStrategy.SnakeCaseStrategy.class)
public class RiddlesDto implements Serializable {

    private static final long serialVersionUID = 1146262887785483279L;

    private String question;

    private String answer;

}
```

**Message Handler**

Create chat web socket handler on package `com.piinalpin.websocketserver.handler`, we will create a class `ChatWebSocketHandler` like following code.

```java
@Slf4j
public class ChatWebSocketHandler extends TextWebSocketHandler {

    @Autowired
    private ObjectMapper mapper;

    @Autowired
    private RestTemplate restTemplate;

    @Value("${chatbot.url}")
    private String chatbotUrl;

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        super.handleTextMessage(session, message);
        log.info("Payload: " + message.getPayload());
        MessageDto messageDto = mapper.readValue(message.getPayload(), MessageDto.class);

        if (StringUtils.isEmpty(messageDto.getMessage())) return;

        ResponseEntity<MessageResponse> responseEntity;

        try {
            responseEntity = restTemplate.postForEntity(chatbotUrl, messageDto, MessageResponse.class);
        } catch (Exception e) {
            log.info("Session ID: " + session.getId());
            log.error("Happened error", e);
            session.sendMessage(new TextMessage(mapper.writeValueAsString(MessageDto.builder().message("Maaf bot tidak tersedia saat ini.").build())));
            return;
        }

        MessageResponse messageResponse = responseEntity.getBody();

        if (Objects.requireNonNull(messageResponse).getType().equalsIgnoreCase("riddles")) {
            RiddlesDto dto = mapper.convertValue(messageResponse.getData(), RiddlesDto.class);
            log.info("RiddlesDto:: " + dto);
            TextMessage question = new TextMessage(mapper.writeValueAsString(MessageDto.builder().message(dto.getQuestion()).build()));
            TextMessage answer = new TextMessage(mapper.writeValueAsString(MessageDto.builder().message(dto.getAnswer()).build()));
            session.sendMessage(question);
            TimeUnit.SECONDS.sleep(1);
            session.sendMessage(answer);
        } else {
            TextMessage response = new TextMessage(mapper.writeValueAsString(messageResponse.getData()));
            log.info("Response: " + response.getPayload());
            session.sendMessage(response);
        }

    }
```

**Create web socket client with javascript**

Basic usage web socket client with javascript with `web_socket.js` function like this.

```javascript
var socket = new WebSocket('ws://localhost:8081/chat');
socket.onopen = (event) => {
    console.log("Open connection: " + event);
};

socket.onmessage = (event) => {
    $('#starkIsTyping').show();
    setTimeout(function() {
        const data = JSON.parse(event.data);
        $("#messagesContent").append('<div class="message stark">' + data.message+ '</div>');
        $('#starkIsTyping').hide();
    }, 1000);
    chat.scrollTop = chat.scrollHeight - chat.clientHeight;
};

socket.onclose = (event) => {
    console.log("Close connection: " + event);
};
```

Now, we will create css for styling our client

```css
@import url("https://fonts.googleapis.com/css?family=Red+Hat+Display:400,500,900&display=swap");
body,
html {
  font-family: Red hat Display, sans-serif;
  font-weight: 400;
  line-height: 1.25em;
  letter-spacing: 0.025em;
  color: #333;
  background: #f7f7f7;
}

.center {
  position: absolute;
  top: 50%;
  left: calc(50%);
  transform: translate(-50%, -50%);
}

.pic {
  width: 4rem;
  height: 4rem;
  background-size: cover;
  background-position: center;
  border-radius: 50%;
}

.contact {
  position: relative;
  margin-bottom: 1rem;
  padding-left: 5rem;
  height: 4.5rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.contact .pic {
  position: absolute;
  right: 130px;
}
.contact .name {
  font-weight: 500;
  margin-bottom: 0.125rem;
}
.contact .message,
.contact .seen {
  font-size: 0.9rem;
  color: #999;
}
.contact .badge {
  box-sizing: border-box;
  position: absolute;
  width: 1.5rem;
  height: 1.5rem;
  text-align: center;
  font-size: 0.9rem;
  padding-top: 0.125rem;
  border-radius: 1rem;
  top: 0;
  left: 2.5rem;
  background: #333;
  color: white;
}

.contacts {
  position: absolute;
  top: 50%;
  left: 0;
  transform: translate(-6rem, -50%);
  width: 24rem;
  height: 32rem;
  padding: 1rem 2rem 1rem 1rem;
  box-sizing: border-box;
  border-radius: 1rem 0 0 1rem;
  cursor: pointer;
  background: white;
  box-shadow: 0 0 8rem 0 rgba(0, 0, 0, 0.1), 2rem 2rem 4rem -3rem rgba(0, 0, 0, 0.5);
  transition: transform 500ms;
}
.contacts h2 {
  margin: 0.5rem 0 1.5rem 5rem;
}
.contacts .fa-bars {
  position: absolute;
  left: 2.25rem;
  color: #999;
  transition: color 200ms;
}
.contacts .fa-bars:hover {
  color: #666;
}
.contacts .contact:last-child {
  margin: 0;
}
.contacts:hover {
  transform: translate(-23rem, -50%);
}

.chat {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  width: 24rem;
  height: 38rem;
  z-index: 2;
  box-sizing: border-box;
  border-radius: 1rem;
  background: white;
  box-shadow: 0 0 8rem 0 rgba(0, 0, 0, 0.1), 0rem 2rem 4rem -3rem rgba(0, 0, 0, 0.5);
}
.chat .contact {
  flex-basis: 3.5rem;
  flex-shrink: 0;
  margin: 1rem;
  box-sizing: border-box;
  position: relative;
}
.contact .bar {
    margin-top: 1rem;
    position: fixed;
    top: 0;
}
.chat .messages {
  flex-shrink: 2;
  overflow-y: auto;
}
.chat .messages .time {
  font-size: 0.8rem;
  background: #eee;
  padding: 0.25rem 1rem;
  border-radius: 2rem;
  color: #999;
  width: -webkit-fit-content;
  width: -moz-fit-content;
  width: fit-content;
  margin: 0 auto;
}
.chat .messages .message {
  box-sizing: border-box;
  padding: 0.5rem 1rem;
  margin: 1rem;
  background: #e4e4e4;
  border-radius: 1.125rem 1.125rem 1.125rem 0;
  min-height: 2.25rem;
  width: -webkit-fit-content;
  width: -moz-fit-content;
  width: fit-content;
  max-width: 66%;
  box-shadow: 0 0 2rem rgba(0, 0, 0, 0.075), 0rem 1rem 1rem -1rem rgba(0, 0, 0, 0.1);
}
.chat .messages .message.parker {
  margin: 1rem 1rem 1rem auto;
  border-radius: 1.125rem 1.125rem 0 1.125rem;
  background: #2884e4;
  color: white;
}
.chat .messages .message .typing {
  display: inline-block;
  width: 0.8rem;
  height: 0.8rem;
  margin-right: 0rem;
  box-sizing: border-box;
  background: #ccc;
  border-radius: 50%;
}
.chat .messages .message .typing.typing-1 {
  -webkit-animation: typing 3s infinite;
          animation: typing 3s infinite;
}
.chat .messages .message .typing.typing-2 {
  -webkit-animation: typing 3s 250ms infinite;
          animation: typing 3s 250ms infinite;
}
.chat .messages .message .typing.typing-3 {
  -webkit-animation: typing 3s 500ms infinite;
          animation: typing 3s 500ms infinite;
}
.chat .input {
  box-sizing: border-box;
  flex-basis: 4rem;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  padding: 0 0.5rem 0 1.5rem;
}
.chat .input i {
  font-size: 1.5rem;
  margin-right: 1rem;
  color: #666;
  cursor: pointer;
  transition: color 200ms;
}
.chat .input i:hover {
  color: #333;
}
.chat .input input {
  border: none;
  background-image: none;
  background-color: white;
  padding: 0.5rem 1rem;
  margin-right: 1rem;
  border-radius: 1.125rem;
  flex-grow: 2;
  box-shadow: 0 0 1rem rgba(0, 0, 0, 0.1), 0rem 1rem 1rem -1rem rgba(0, 0, 0, 0.2);
  font-family: Red hat Display, sans-serif;
  font-weight: 400;
  letter-spacing: 0.025em;
}
.chat .input input:placeholder {
  color: #999;
}

@-webkit-keyframes typing {
  0%, 75%, 100% {
    transform: translate(0, 0.25rem) scale(0.9);
    opacity: 0.5;
  }
  25% {
    transform: translate(0, -0.25rem) scale(1);
    opacity: 1;
  }
}

@keyframes typing {
  0%, 75%, 100% {
    transform: translate(0, 0.25rem) scale(0.9);
    opacity: 0.5;
  }
  25% {
    transform: translate(0, -0.25rem) scale(1);
    opacity: 1;
  }
}
.pic.stark {
  background-image: url("https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/7/73/SMH_Mentor_6.png");
}

.pic.banner {
  background-image: url("https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/4/4f/BruceHulk-Endgame-TravelingCapInPast.jpg");
}

.pic.thor {
  background-image: url("https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/9/98/ThorFliesThroughTheAnus.jpg");
}

.pic.danvers {
  background-image: url("https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/0/05/HeyPeterParker.png");
}

.pic.rogers {
  background-image: url("https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/7/7c/Cap.America_%28We_Don%27t_Trade_Lives_Vision%29.png");
}

#sendButton{
    color: #2884e4;
}
```

And also create `index.html`.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css" integrity="sha512-iBBXm8fW90+nuLcSKlbmrPcLa0OT92xO1BIsZ+ywDWZCvqsWgccV3gFoRBv0z+8dLJgyAHIhR35VZc2oM/gI1w==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    <title>Web Socket Demo</title>
</head>
<body>
    <div class="center">
        <div class="chat">
          <div class="contact">
              <div class="bar">
                <div class="pic stark"></div>
                <div class="name">
                  WebSocket Bot
                </div>
                <div class="seen">
                  Today at 12:56
                </div>
              </div>
          </div>
          <div class="messages" id="chat">
            <div id="messagesContent">

            </div>
            <div class="message stark" id="starkIsTyping">
              <div class="typing typing-1"></div>
              <div class="typing typing-2"></div>
              <div class="typing typing-3"></div>
            </div>
          </div>
          <div class="input">
            <input placeholder="Type your message here!" id="inputMessage" type="text" /><i class="fas fa-paper-plane" id="sendButton"></i>
          </div>
        </div>
      </div>
<script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
<!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/sockjs-client/1.5.2/sockjs.min.js" integrity="sha512-ayb5R/nKQ3fgNrQdYynCti/n+GD0ybAhd3ACExcYvOR2J1o3HebiAe/P0oZDx5qwB+xkxuKG6Nc0AFTsPT/JDQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script> -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/web-socket-js/1.0.0/web_socket.min.js" integrity="sha512-jtr9/t8rtBf1Sv832XjG1kAtUECQCqFnTAJWccL8CSC82VGzkPPih8rjtOfiiRKgqLXpLA1H/uQ/nq2bkHGWTQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.min.js" integrity="sha512-iKDtgDyTHjAitUDdLljGhenhPwrbBfqTKWO1mkhSFH3A7blITC9MhYon6SjnMhp4o0rADGw9yAC6EW4t5a4K3g==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script>
    // const baseURL = 'http://localhost:8081';

    // let socket = new SockJS(baseURL + '/chat');
    var socket = new WebSocket('ws://localhost:8081/chat');
    console.log(socket);

    socket.onopen = (event) => {
        console.log("Open connection: " + event);
    };

    socket.onmessage = (event) => {
        $('#starkIsTyping').show();
        setTimeout(function() {
            const data = JSON.parse(event.data);
            $("#messagesContent").append('<div class="message stark">' + data.message+ '</div>');
            $('#starkIsTyping').hide();
        }, 1000);
        chat.scrollTop = chat.scrollHeight - chat.clientHeight;
    };

    socket.onclose = (event) => {
        console.log("Close connection: " + event);
    };

    let chat = document.getElementById('chat');
    chat.scrollTop = chat.scrollHeight - chat.clientHeight;
    $('#starkIsTyping').hide();

    $("#inputMessage").keyup(function(event) {
        $('#starkIsTyping').hide();
        if (event.keyCode === 13) {
            $("#sendButton").click();
        }
    });

    $("#sendButton").click(function() {
        if ($("#inputMessage").val() != '') {
            socket.send(JSON.stringify({'message': $("#inputMessage").val()}));
            $("#messagesContent").append('<div class="message parker">' + $("#inputMessage").val() + '</div>');
            $("#inputMessage").val('');
            chat.scrollTop = chat.scrollHeight - chat.clientHeight;
        }
    });
</script>
</body>
</html>
```

Then access `index.html` on your favourite browser. And lets chat with chat bot. Our client running well should be like this.

![Example Spring Bot](/images/example-web-socket.gif)

### Clone or Download

You can clone or download this project at

```bash
https://github.com/piinalpin/springboot-websocket-chatbot.git
```

### Reference

[Wikipedia](https://en.wikipedia.org/wiki/WebSocket) - WebSocket

[Youtube](https://www.youtube.com/watch?v=r2tPEfVgsIE) - Spring Boot + Angular 8 + WebSocket Example Tutorial
