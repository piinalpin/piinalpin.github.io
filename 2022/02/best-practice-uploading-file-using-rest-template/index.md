# Best Practice Uploading File Using Spring RestTemplate


<!--more-->
### Overview

![Spring Boot Upload Files](/images/spring-boot-upload-files.png)

Rest Template is used to create applications that consume RESTful Web Services. You can use the exchange() method to consume the web services for all HTTP methods. The code given below shows how to create Bean for Rest Template to auto wiring the Rest Template object.

A little things but important when uploading files through REST template. It should send the filename in the correct format. A correct file upload request should be like this.

**HTTP Headers**
```
Content-Type: multipart/form-data; boundary=/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
```

**HTTP Body**
```
--/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
Content-Disposition: form-data; name="file"; filename="my-uploaded-file.png"
Content-Type: application/octet-stream
Content-Length: ...

<...file data in base 64...>
--/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB--
```

There can be multiple sections like this in the body with additional data, when more data needs to be posted to the server, like multiple files or other metadata. The Content-Type could also be adjusted. `application-octet-stream` is the default Spring uses for `byte[]` data.

So, I will create utility class to convert base64 string into http entity with file metadata.

```java
public class Base64Util {
    
    private Base64Util() {}
    
    public static String generateFilename(String base64String) {
        if (StringUtils.isBlank(base64String)) {
            return base64String;
        }
        String[] arrayString = base64String.split(",");
        String header = arrayString[0].split(";")[0];
        String uuid = UUID.randomUUID().toString();
        String filename = String.format("%s.%s", uuid, header.split("/")[1]);
        return filename;
    }

    public static String stripStartBase64(String base64String) {
        if (StringUtils.isBlank(base64String)) {
            return base64String;
        }
        return base64String.replaceAll("^data:image/[^;]*;base64,?", "");
    }

    public static HttpEntity<byte[]> convertToHttpEntity(String filename, String base64) {
        byte[] imageByte = Base64.decodeBase64(base64);
        ContentDisposition contentDisposition = ContentDisposition.builder("form-data")
                .name("myImage")
                .filename(filename)
                .build();

        MultiValueMap<String, String> fileMap = new LinkedMultiValueMap<>();
        fileMap.add(HttpHeaders.CONTENT_DISPOSITION, contentDisposition.toString());
        return new HttpEntity<>(imageByte, fileMap);
    }
}
```

And a service will send request template for another API like this.

```java
@Slf4j
@Service
public class FileUploadService {

    @Autowired
    private RestTemplate restTemplate;
    
    public void sendFile(String base64Image) {
        log.info("Start executing send file through rest template.");
        try {
            log.info("Sending files...");
            ResponseEntity<Object> responseEntity = restTemplate.postForEntity("/some-url-to-send-file", constructRequest(base64Image), Object.class);
            log.info("Done uploading files.");
        } catch (Exception e) {
            log.error("Error when uploading file. Error: {}", e.getMessage());
            throw e;
        }
    }

    private HttpEntity<MultiValueMap<String, Object>> constructRequest(String base64Image) throws IOException {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("myImage", Base64Util.convertToHttpEntity(Base64Util.generateFilename(base64Image), Base64Util.stripStartBase64(base64Image)));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        headers.add("Some-Header", "Some-Value");

        return new HttpEntity<>(body, headers);
    }

}
```

Most solutions on google search, you find will not use the embedded HttpEntity, but will just add two entries to the MultiValueMap for the body like so:

```java
MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
body.add("filename", "some-file-name.jpg");
body.add("file", new ByteArrayResource(someByteArray));
```

This produces a different request body, where the file and the filename are embedded in two different sections like this:

```
--/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
Content-Disposition: form-data; name="filename"
Content-Type: text/plain;charset=UTF-8
Content-Length: 6

some-file-name.jpg
--/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB
Content-Disposition: form-data; name="file"
Content-Type: application/octet-stream
Content-Length: ...

<...file data in base 64...>
--/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB--
```

The receiving server will most likely not see the filename in a different section. Some servers will reject the request entirely. So also work with the embedded HttpEntity, when uploading a file with Spring RestTemplate, to produce standard compliant multipart upload requests!

### Reference

- [Uploading a file with a filename with Spring RestTemplate](https://medium.com/red6-es/uploading-a-file-with-a-filename-with-spring-resttemplate-8ec5e7dc52ca)
