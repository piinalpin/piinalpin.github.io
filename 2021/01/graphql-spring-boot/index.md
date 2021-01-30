# GraphQL Server with Spring Boot


<!--more-->

### Prerequisites
* [MySQL Database](https://www.mysql.com/)
* [Spring Initializr](https://start.spring.io/)
* [GraphQL Spring Boot Starter](https://mvnrepository.com/artifact/com.graphql-java-kickstart/graphql-spring-boot-starter)
* [Flyway Database Migration](https://flywaydb.org/)
* [MySQL-Connector](https://mvnrepository.com/artifact/mysql/mysql-connector-java/8.0.22)
* [Lombok Annotation](https://mvnrepository.com/artifact/org.projectlombok/lombok/1.18.16)

### What is GraphQL?

![GraphQL Modelling](/images/graphql-model.png)

GraphQL is a query language for APIs and a runtime for fulfilling those queries with your existing data. GraphQL provides a complete and understandable description of the data in your API, gives clients the power to ask for exactly what they need and nothing more, makes it easier to evolve APIs over time, and enables powerful developer tools.

**Note**: This tutorial assumes that you are familiar with the Java programming language, the Spring Boot framework, and REST APIs in general. No prior GraphQL experience is required.

GraphQL is a new specification (originally developed by Facebook for internal use, later open-sourced in 2015) that describes how to implement APIs. Unlike REST, which uses different endpoints to retrieve different types of data (e. g. users, comments, blog posts…), GraphQL exposes a single endpoint that receives a query from the front-end as part of the request, returning exactly the requested pieces of data in a single response. The server defines a schema describing what queries are available.

**Note**: Unlike REST, GraphQL as a specification is not tied to the HTTP protocol, however, HTTP is most commonly used. In this case, GraphQL queries are simple HTTP GET or POST requests with special query parameters or request bodies, respectively. You can use [Postman](https://www.getpostman.com/) which recently received GraphQL support.

### Step to build GraphQL server using Spring Boot

**Starting with spring initializr**

For all Spring applications, you should start with the [Spring Initializr](https://start.spring.io/). The Initializr offers a fast way to pull in all the dependencies you need for an application and does a lot of the set up for you. This example needs the Spring Batch. And we will started with maven project.
	
The following listing shows the `pom.xml` file created when you choose Maven. And here my `pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.1</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.maverick</groupId>
	<artifactId>graphiql</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>graphiql</name>
	<description>Demo project for Spring Boot with GraphQL</description>

	<properties>
		<java.version>11</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter</artifactId>
		</dependency>

		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<scope>runtime</scope>
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

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>

		<!-- https://mvnrepository.com/artifact/com.graphql-java-kickstart/graphql-spring-boot-starter -->
		<dependency>
			<groupId>com.graphql-java-kickstart</groupId>
			<artifactId>graphql-spring-boot-starter</artifactId>
			<version>6.0.1</version>
		</dependency>

		<!-- https://mvnrepository.com/artifact/org.flywaydb/flyway-core -->
		<dependency>
			<groupId>org.flywaydb</groupId>
			<artifactId>flyway-core</artifactId>
			<scope>runtime</scope>
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

Edit `application.properties`

```
#Basic Spring Boot Config for Oracle
spring.jmx.enabled=false
info.app.name=GraphQL Example
info.app.description=GraphQL Example
info.app.version=1.0.0
management.security.enabled=false
spring.http.multipart.max-file-size=10485760
spring.jackson.serialization.FAIL_ON_EMPTY_BEANS=false
spring.jpa.properties.hibernate.dialect = org.hibernate.dialect.MySQL5Dialect
graphql.servlet.enabled=true
graphql.servlet.exception-handlers-enabled=true
graphql.servlet.contextSetting= PER_REQUEST_WITH_INSTRUMENTATION
spring.jpa.hibernate.use-new-id-generator-mappings=false
```

And here my `project/application.yml` for external configuration of database connection, flyway migration, etc.

```js
app:
  name: "Maverick GraphQL Example"
  website: "blog.piinalpin.com"
  origin: "http://localhost:3000"
  upload_dir: "./tmp/"
  production: false
spring:
  datasource:
    url: "jdbc:mysql://localhost:3306/DB_NAME?allowPublicKeyRetrieval=true&useSSL=false"
    username: DB_USERNAME
    password: DB_PASSWORD
    driverClassName: com.mysql.cj.jdbc.Driver
flyway:
  enabled: true
  baselineOnMigrate: true
  url: jdbc:mysql://localhost:3306/DB_NAME?allowPublicKeyRetrieval=true&useSSL=false
  user: DB_USERNAME
  password: DB_PASSWORD
  validateOnMigrate: false
server:
  port: 8080
```

Create `resource/db/migration/V1_1__Initial_Commit.sql` for initial migration script

Edit project main application and add annotation `@EnableJpaRepositories`. The file should be like below.

```java
@SpringBootApplication
@EnableJpaRepositories
public class GraphqlApplication {

	public static void main(String[] args) {
		SpringApplication.run(GraphqlApplication.class, args);
	}

}
```

**Data Scalar**

Create bean configuration `com.maverick.graphql.configuration.DataScalarConfiguration` to define scalar for GraphQL schema.

```java
@Configuration
public class DataScalarConfiguration {

    @Bean
    public GraphQLScalarType dateScalar() {
        return GraphQLScalarType.newScalar()
                .name("Date")
                .description("Java 8 LocalDate as Scalar")
                .coercing(new Coercing<LocalDate, String>() {
                    @Override
                    public String serialize(Object dataFetcherResult) throws CoercingSerializeException {
                        if (dataFetcherResult instanceof Timestamp) return dataFetcherResult.toString();
                        else throw new CoercingSerializeException("Expected a Timestamp object.");
                    }

                    @Override
                    public LocalDate parseValue(Object input) throws CoercingParseValueException {
                        try {
                            if (input instanceof String) return LocalDate.parse((String) input, DateTimeFormatter.ofPattern("dd-MM-yyyy"));
                            else throw new CoercingParseValueException("Expected a String");
                        } catch (DateTimeParseException e) {
                            throw new CoercingParseValueException(String.format("Not a valid date: %s", input), e);
                        }
                    }

                    @Override
                    public LocalDate parseLiteral(Object input) throws CoercingParseLiteralException {
                        if (input instanceof StringValue) {
                            try {
                                return LocalDate.parse(((StringValue) input).getValue());
                            } catch (DateTimeParseException e) {
                                throw new CoercingParseLiteralException();
                            }
                        } else throw new CoercingParseLiteralException("Expected a StringValue");
                    }
                }).build();
    }

}
```

**Create Person**

Create GraphQL schema on `resource/schema.graphqls`

```js
scalar Date

type Mutation {
    createPerson(input: PersonInput!): Person!
}

input PersonInput {
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String
}

type Person {
    id: Int!
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String,
    createdAt: Date,
    createdBy: Int,
    updatedAt: Date
}

```

Create table on database migration `resource/db/migration/V2_1__Person.sql` see [Flyway Documentation](https://flywaydb.org/documentation/) for versioning migration.

```sql
SET AUTOCOMMIT = false;

START TRANSACTION;
    CREATE TABLE m_person (
        id                      BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        created_at              DATETIME NOT NULL,
        created_by              BIGINT NOT NULL,
        updated_at              DATETIME,
        deleted_at              DATETIME,
        first_name              VARCHAR(255) NOT NULL,
        last_name               VARCHAR(255) NOT NULL,
        date_of_birth           DATETIME NOT NULL,
        identity_type           VARCHAR(255) NOT NULL,
        identity_number         VARCHAR(255) NOT NULL,
        address                 VARCHAR(1000)
    );
COMMIT;
```

Create abstract class `com.maverick.graphql.model.BaseModel` first which aim can be inheritence for another model.

```java
@NoArgsConstructor
@MappedSuperclass
abstract class BaseModel {

    @JsonProperty("created_at")
    @Column(name = "CREATED_AT", nullable = false)
    @Getter
    @Setter
    private Timestamp createdAt;

    @JsonProperty("created_by")
    @Column(name = "CREATED_BY", nullable = false)
    @Getter
    @Setter
    private Long createdBy;

    @JsonProperty("updated_at")
    @Column(name = "UPDATED_AT")
    @Getter
    @Setter
    private Timestamp updatedAt;

    @JsonIgnore
    @Column(name = "DELETED_AT")
    @Getter
    @Setter
    private Timestamp deleted_at;

    @PrePersist
    void onCreate() {
        createdAt = Timestamp.valueOf(LocalDateTime.now());
        if (createdBy == null) createdBy = 0L;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Timestamp.valueOf(LocalDateTime.now());
    }

}
```

Create person model `com.maverick.graphql.model.Person` which is inheritence from `BaseModel`.

```java
@Entity
@Table(name = "M_PERSON")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Where(clause = "deleted_at is null")
public class PersonModel extends BaseModel {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Getter
    @Setter
    private Long id;

    @Column(name = "FIRST_NAME", nullable = false)
    @Getter
    @Setter
    private String firstName;

    @Column(name = "LAST_NAME", nullable = false)
    @Getter
    @Setter
    private String lastName;

    @Column(name = "DATE_OF_BIRTH", nullable = false)
    @Getter
    @Setter
    private Timestamp dateOfBirth;

    @Column(name = "IDENTITY_TYPE", nullable = false)
    @Getter
    @Setter
    private String identityType;

    @Column(name = "IDENTITY_NUMBER", nullable = false)
    @Getter
    @Setter
    private String identityNumber;

    @Column(name = "ADDRESS")
    @Getter
    @Setter
    private String address;

}
```

Create repository `com.maverick.graphql.repository.PersonRepository` for transactional query which extends from `JpaRepository`

```java
@Repository
public interface PersonRepository extends JpaRepository<PersonModel, Long> {

}
```

Create form `com.maverick.graphql.form.PersonForm`

```java
@Data
public class PersonForm {

    private String firstName;

    private String lastName;

    private LocalDate dateOfBirth;

    private String identityType;

    private String identityNumber;

    private String address;

}
```

Create service `com.maverick.graphql.service.PersonService` to store person model into database using repository.

```java
@Service
public class PersonService {

    private final PersonRepository personRepository;

    @Autowired
    public PersonService(PersonRepository personRepository) {
        this.personRepository = personRepository;
    }

    public PersonModel save(PersonModel person) {
        return personRepository.save(person);
    }

}
```

Create mutation service `com.maverick.graphql.mutation.PersonMutation` use for anychange data from GraphQL schema.

```java
@Service
public class PersonMutation implements GraphQLMutationResolver {

    private final PersonService personService;

    @Autowired
    public PersonMutation(PersonService personService) {
        this.personService = personService;
    }

    public PersonModel createPerson(PersonForm form) {
        PersonModel person = PersonModel.builder()
                .address(form.getAddress())
                .dateOfBirth(Timestamp.valueOf(form.getDateOfBirth().atStartOfDay()))
                .firstName(form.getFirstName())
                .lastName(form.getLastName())
                .identityType(form.getIdentityType())
                .identityNumber(form.getIdentityNumber())
                .build();
        return personService.save(person);
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below.

`URL: http://localhost:8080/graphql (POST)`

Query

```js
mutation CreatePerson($input: PersonInput!){
    createPerson(input: $input) {
        id
        firstName
        identityNumber
        address
    }
}
```

GraphQL Variables

```json
{
    "input": {
        "firstName": "Alvinditya",
        "lastName": "Saputra",
        "dateOfBirth": "10-11-1996",
        "identityType": "KTP",
        "identityNumber": "346343723744",
        "address": "Yogyakarta"
    }
}
```

Response should be like below.

```json
{
    "data": {
        "createPerson": {
            "id": 1,
            "firstName": "Alvinditya",
            "identityNumber": "346343723744",
            "address": "Yogyakarta"
        }
    }
}
```

**Get Person Data**

Edit `resource/schema.graphqls`, code should be like below.

```js
scalar Date

type Query {
    getAllPerson: [Person!]
    getPersonById(id: Int!): Person
    getPersonByIdentityNumber(identityNumber: String!): Person
}

type Mutation {
    createPerson(input: PersonInput!): Person!
}

input PersonInput {
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String
}

type Person {
    id: Int!
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String,
    createdAt: Date,
    createdBy: Int,
    updatedAt: Date
}
```

Edit `com.maverick.graphql.repository.PersonRepository` add line to get person data by identity number.

```java
@Repository
@Transactional
public interface PersonRepository extends JpaRepository<PersonModel, Long> {

    @Query(value = "SELECT * FROM m_person WHERE identity_number = ?1", nativeQuery = true)
    PersonModel findByIdentityNumber(String identityNumber);

}
```

Edit `com.maverick.graphql.service.PersonService` to process logic get data from repository. Code should be like below.

```java
@Service
public class PersonService {

    private final PersonRepository personRepository;

    @Autowired
    public PersonService(PersonRepository personRepository) {
        this.personRepository = personRepository;
    }

    public PersonModel save(PersonModel person) {
        return personRepository.save(person);
    }

    public List<PersonModel> getAll() {
        return personRepository.findAll();
    }

    public PersonModel getByIdentityNumber(String identityNumber) {
        return personRepository.findByIdentityNumber(identityNumber);
    }

    public Optional<PersonModel> getById(Long id) {
        return personRepository.findById(id);
    }

}
```

Create exception `com.maverick.graphql.exception.DataNotFoundException` to handle when record not found.

```java
@ResponseStatus(value = HttpStatus.NOT_FOUND, reason = "data: not found")
@NoArgsConstructor
public class DataNotFoundException extends RuntimeException {

    @Getter
    @Setter
    private String message = "data: not found";

    public DataNotFoundException(String message) {
        super();
        this.message = message;
    }

}
```

Create query resolver `com.maverick.graphql.resolver.PersonResolver` to handle query request.

```java
@Service
public class PersonResolver implements GraphQLQueryResolver {

    private final PersonService personService;

    @Autowired
    public PersonResolver(PersonService personService) {
        this.personService = personService;
    }

    public List<PersonModel> getAllPerson() {
        return personService.getAll();
    }

    public PersonModel getPersonById(final Long id) {
        PersonModel person = personService.getById(id).orElse(null);
        if (person == null) throw new DataNotFoundException("person record: not found");
        return person;
    }

    public PersonModel getPersonByIdentityNumber(final String identityNumber) {
        PersonModel person = personService.getByIdentityNumber(identityNumber);
        if (person == null) throw new DataNotFoundException("person record: not found");
        return person;
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below. You can edit any field you want.

`URL: http://localhost:8080/graphql (POST)`

Query

```js
query {
    getAllPerson {
        id
        firstName
        identityNumber
    }
}
```

Response should be like below.

```json
{
    "data": {
        "getAllPerson": [
            {
                "id": 1,
                "firstName": "Calvin",
                "identityNumber": "2263246348434"
            },
            {
                "id": 2,
                "firstName": "Calvin 2",
                "identityNumber": "237384374233"
            }
        ]
    }
}
```

Query

```js
query {
    getPersonById(id: 4) {
        id
        firstName
        identityNumber
    }
}
```

Response should be like below.

```json
{
    "data": {
        "getPersonById": {
            "id": 4,
            "firstName": "Alvinditya",
            "identityNumber": "346343723744"
        }
    }
}
```

Query

```js
query {
    getPersonByIdentityNumber(identityNumber: "346343723744") {
        id
        firstName
        lastName
        identityNumber
    }
}
```

Response should be like below.

```json
{
    "data": {
        "getPersonByIdentityNumber": {
            "id": 4,
            "firstName": "Alvinditya",
            "lastName": "Saputra",
            "identityNumber": "346343723744"
        }
    }
}
```

**Update Person**

Edit `resource/schema.graphqls`, code should be like below.

```js
scalar Date

type Query {
    getAllPerson: [Person!]
    getPersonById(id: Int!): Person
    getPersonByIdentityNumber(identityNumber: String!): Person
}

type Mutation {
    createPerson(input: PersonInput!): Person!
    updatePerson(input: PersonInput!, id: Int!): Person!
}

input PersonInput {
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String
}

type Person {
    id: Int!
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String,
    createdAt: Date,
    createdBy: Int,
    updatedAt: Date
}
```

Edit mutation `com.maverick.graphql.mutation.PersonMutation` to process logic save updated data. Code should be like below.

```java
@Service
public class PersonMutation implements GraphQLMutationResolver {

    private final PersonService personService;

    @Autowired
    public PersonMutation(PersonService personService) {
        this.personService = personService;
    }

    public PersonModel createPerson(PersonForm form) {
        PersonModel person = PersonModel.builder()
                .address(form.getAddress())
                .dateOfBirth(Timestamp.valueOf(form.getDateOfBirth().atStartOfDay()))
                .firstName(form.getFirstName())
                .lastName(form.getLastName())
                .identityType(form.getIdentityType())
                .identityNumber(form.getIdentityNumber())
                .build();
        return personService.save(person);
    }

    public PersonModel updatePerson(PersonForm form, Long id) {
        PersonModel person = personService.getById(id).orElse(null);
        if (person == null) throw new DataNotFoundException("person record: not found");
        person.setAddress(form.getAddress());
        person.setDateOfBirth(Timestamp.valueOf(form.getDateOfBirth().atStartOfDay()));
        person.setFirstName(form.getFirstName());
        person.setLastName(form.getLastName());
        person.setIdentityNumber(form.getIdentityNumber());
        person.setIdentityType(form.getIdentityType());
        return personService.save(person);
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below. You can edit any field you want.

`URL: http://localhost:8080/graphql (POST)`

Query

```js
mutation UpdatePerson($input: PersonInput!){
    updatePerson(input: $input, id: 2) {
        id
        firstName
        lastName
        createdAt
        identityNumber
        address
    }
}
```

GraphQL Variables

```json
{
    "input": {
        "firstName": "Maverick",
        "lastName": "Johnson",
        "dateOfBirth": "10-11-1996",
        "identityType": "KTP",
        "identityNumber": "346322723744",
        "address": "Yogyakarta"
    }
}
```

Response should be like below.

```json
{
    "data": {
        "updatePerson": {
            "id": 2,
            "firstName": "Maverick",
            "lastName": "Johnson",
            "createdAt": "2021-01-05 11:32:23.0",
            "identityNumber": "346322723744",
            "address": "Yogyakarta"
        }
    }
}
```

**Delete Person**

Edit `resource/schema.graphqls`, code should be like below.

```js
scalar Date
scalar Timestamp

type Query {
    getAllPerson: [Person!]
    getPersonById(id: Int!): Person
    getPersonByIdentityNumber(identityNumber: String!): Person
}

type Mutation {
    createPerson(input: PersonInput!): Person!
    updatePerson(input: PersonInput!, id: Int!): Person!
    deletePerson(id: Int!): OkMessage!
}

input PersonInput {
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String
}

type Person {
    id: Int!
    firstName: String!,
    lastName: String!,
    dateOfBirth: Date,
    identityType: String!,
    identityNumber: String!,
    address: String,
    createdAt: Date,
    createdBy: Int,
    updatedAt: Date
}

type OkMessage {
    message: String!
}
```

Edit `com.maverick.graphql.repository.PersonRepository` add line to update deleted_at for soft delete.

```java
@Repository
@Transactional
public interface PersonRepository extends JpaRepository<PersonModel, Long> {

    @Query(value = "SELECT * FROM m_person WHERE identity_number = ?1", nativeQuery = true)
    PersonModel findByIdentityNumber(String identityNumber);

    @Query(value = "UPDATE m_person SET deleted_at = CURRENT_DATE WHERE id = ?1", nativeQuery = true)
    @Modifying
    void softDelete(Long id);

}
```

Edit `com.maverick.graphql.service.PersonService` to process logic delete data from repository. Code should be like below.

```java
@Service
public class PersonService {

    private final PersonRepository personRepository;

    @Autowired
    public PersonService(PersonRepository personRepository) {
        this.personRepository = personRepository;
    }

    public PersonModel save(PersonModel person) {
        return personRepository.save(person);
    }

    public List<PersonModel> getAll() {
        return personRepository.findAll();
    }

    public PersonModel getByIdentityNumber(String identityNumber) {
        return personRepository.findByIdentityNumber(identityNumber);
    }

    public Optional<PersonModel> getById(Long id) {
        return personRepository.findById(id);
    }

    public void deletePerson(Long id) {
        personRepository.softDelete(id);
    }

}
```

Edit mutation `com.maverick.graphql.mutation.PersonMutation` to process logic save updated data. Code should be like below.

```java
@Service
public class PersonMutation implements GraphQLMutationResolver {

    private final PersonService personService;

    @Autowired
    public PersonMutation(PersonService personService) {
        this.personService = personService;
    }

    public PersonModel createPerson(PersonForm form) {
        PersonModel person = PersonModel.builder()
                .address(form.getAddress())
                .dateOfBirth(Timestamp.valueOf(form.getDateOfBirth().atStartOfDay()))
                .firstName(form.getFirstName())
                .lastName(form.getLastName())
                .identityType(form.getIdentityType())
                .identityNumber(form.getIdentityNumber())
                .build();
        return personService.save(person);
    }

    public PersonModel updatePerson(PersonForm form, Long id) {
        PersonModel person = personService.getById(id).orElse(null);
        if (person == null) throw new DataNotFoundException("person record: not found");
        person.setAddress(form.getAddress());
        person.setDateOfBirth(Timestamp.valueOf(form.getDateOfBirth().atStartOfDay()));
        person.setFirstName(form.getFirstName());
        person.setLastName(form.getLastName());
        person.setIdentityNumber(form.getIdentityNumber());
        person.setIdentityType(form.getIdentityType());
        return personService.save(person);
    }

    public Map<String, String> deletePerson(Long id) {
        PersonModel person = personService.getById(id).orElse(null);
        if (person == null) throw new DataNotFoundException("person record: not found");

        personService.deletePerson(person.getId());
        Map<String,String> ret = new HashMap<>();
        ret.put("message", "ok");

        return ret;
    }

}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below. You can edit any field you want.

`URL: http://localhost:8080/graphql (POST)`

Query

```js
mutation {
    deletePerson(id: 2) {
        message
    }
}
```

Response should be like below.

```json
{
    "data": {
        "deletePerson": {
            "message": "ok"
        }
    }
}
```

If data not found, should be like below.

Query

```js
mutation {
    deletePerson(id: 3) {
        message
    }
}
```

Response should be like below.

```json
{
    "errors": [
        {
            "message": "person record: not found"
        }
    ],
    "data": null
}
```

### Clone or Download

You can clone or download this project
```bash
https://github.com/piinalpin/graphql-spring-boot.git
```

### Thankyou

[Medium](https://medium.com/supercharges-mobile-product-guide/graphql-server-using-spring-boot-part-i-722bdd715779) - GraphQL server using Spring Boot, Part I

[Baeldung](https://www.baeldung.com/spring-graphql) - Getting Started with GraphQL and Spring Boot

[Github](https://github.com/team-supercharge/spring-boot-graphql-tutorial) - Team Supercharge