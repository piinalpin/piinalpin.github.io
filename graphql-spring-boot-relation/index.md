# GraphQL Server using Spring Boot with Relational Mapping


<!--more-->

### Prerequisites
* [GraphQL Server with Spring Boot](https://blog.piinalpin.com/2021/01/graphql-spring-boot/)

### Step to build GraphQL server using Spring Boot with Relational Mapping

**Note**: You should have done the previous step [GraphQL Server with Spring Boot](https://blog.piinalpin.com/2021/01/graphql-spring-boot/)

**Setting Up Model**

Create database migration `resource/db/migration/V2_2__Book.sql` see [Flyway Documentation](https://flywaydb.org/documentation/) for versioning migration.

```sql
SET AUTOCOMMIT = false;

START TRANSACTION;
    CREATE TABLE m_book (
        id                      BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        created_at              DATETIME NOT NULL,
        created_by              BIGINT NOT NULL,
        updated_at              DATETIME,
        deleted_at              DATETIME,
        author_id               BIGINT NOT NULL,
        title                   VARCHAR(255) NOT NULL,
        publisher               VARCHAR(255) NOT NULL,
        description             VARCHAR(255),
        release_date            DATETIME NOT NULL,
        FOREIGN KEY (author_id) REFERENCES m_person(id)
    );
COMMIT;
```

Create book model `com.maverick.graphql.model.BookModel` which is inheritence from `BaseModel`.

```java
@Entity
@Table(name = "M_BOOK")
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Where(clause = "deleted_at is null")
public class BookModel extends BaseModel {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Getter
    @Setter
    private Long id;

    @ManyToOne
    @Getter
    @Setter
    private PersonModel author;

    @Column(name = "TITLE", nullable = false)
    @Getter
    @Setter
    private String title;

    @Column(name = "PUBLISHER", nullable = false)
    @Getter
    @Setter
    private String publisher;

    @Column(name = "DESCRIPTION")
    @Getter
    @Setter
    private String description;

    @Column(name = "RELEASE_DATE", nullable = false)
    @Getter
    @Setter
    private Timestamp releaseDate;

}
```

Edit person model `com.maverick.graphql.model.PersonModel` for mapping one to many from `BookModel`, add this line into `PersonModel`

```java
@JsonIgnore
@OneToMany(cascade = CascadeType.ALL, fetch = FetchType.LAZY, mappedBy = "author")
@Getter
@Setter
private List<BookModel> authors;
```

Create repository `com.maverick.graphql.repository.BookRepository` extends from `JpaRepository`

```java
@Repository
@Transactional
public interface BookRepository extends JpaRepository<BookModel, Long> {

    @Query(value = "SELECT mb.* FROM m_book mb JOIN m_person mp ON mb.author_id = mp.id " +
            "WHERE UPPER(mp.first_name) = UPPER(?1)", nativeQuery = true)
    List<BookModel> findAllByAuthor(String name);

    @Query(value = "UPDATE m_book SET deleted_at = CURRENT_DATE WHERE id = ?1", nativeQuery = true)
    @Modifying
    void softDelete(Long id);

}
```

Create form `com.maverick.graphql.form.BookForm` for input request.

```java
@Data
public class BookForm {

    private Long authorId;

    private String title;

    private String publisher;

    private String description;

    private LocalDate releaseDate;

}
```

Create service `com.maverick.graphql.service.BookService` to store book model into database using repository.

```java
@Service
public class BookService {

    private final BookRepository bookRepository;

    @Autowired
    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    public BookModel save(BookModel book) {
        return bookRepository.save(book);
    }

    public List<BookModel> getAll() {
        return bookRepository.findAll();
    }

    public List<BookModel> getAllByAuthor(String name) {
        return bookRepository.findAllByAuthor(name);
    }

    public BookModel getById(Long id) {
        return bookRepository.findById(id).orElse(null);
    }

    public void delete(Long id) {
        bookRepository.softDelete(id);
    }

}
```

**Mutation Resolver**

Create mutation service `com.maverick.graphql.mutation.BookMutation` use for anychange data from GraphQL schema.

```java
@Service
public class BookMutation implements GraphQLMutationResolver {

    private final BookService bookService;
    private final PersonService personService;

    @Autowired
    public BookMutation(BookService bookService, PersonService personService) {
        this.bookService = bookService;
        this.personService = personService;
    }

    public BookModel addBook(BookForm form) {
        PersonModel author = personService.getById(form.getAuthorId()).orElse(null);

        if (author == null) throw new DataNotFoundException("author record: not found");
        BookModel book = BookModel.builder()
                .author(author)
                .description(form.getDescription())
                .publisher(form.getPublisher())
                .releaseDate(Timestamp.valueOf(form.getReleaseDate().atStartOfDay()))
                .title(form.getTitle())
                .build();
        return bookService.save(book);
    }

    public BookModel updateBook(BookForm form, Long id) {
        BookModel book = bookService.getById(id);
        if (book == null) throw new DataNotFoundException("book record: not found");

        PersonModel author = personService.getById(form.getAuthorId()).orElse(null);
        if (author == null) throw new DataNotFoundException("author record: not found");
        book.setAuthor(author);
        book.setDescription(form.getDescription());
        book.setPublisher(form.getPublisher());
        book.setReleaseDate(Timestamp.valueOf(form.getReleaseDate().atStartOfDay()));
        book.setTitle(form.getTitle());
        return bookService.save(book);
    }

    public Map<String, String> deleteBook(Long id) {
        BookModel book = bookService.getById(id);
        if (book == null) throw new DataNotFoundException("book record: not found");

        bookService.delete(id);
        Map<String, String> ret = new HashMap<>();
        ret.put("message", "ok");

        return ret;
    }

}
```

**QueryResolver**

Create query resolver `com.maverick.graphql.resolver.BookResolver` to handle query request.

```java
@Service
public class BookResolver implements GraphQLQueryResolver {

    private final BookService bookService;

    @Autowired
    public BookResolver(BookService bookService) {
        this.bookService = bookService;
    }

    public List<BookModel> getAllBook() {
        return bookService.getAll();
    }

    public List<BookModel> getAllBookByAuthor(final String author) {
        return bookService.getAllByAuthor(author);
    }

    public BookModel getBookById(final Long id) {
        BookModel book = bookService.getById(id);
        if (book == null) throw new DataNotFoundException("book record: not found");
        return book;
    }

}
```

**GraphQL Schema**

Add book into schema, edit `resource/schema.graphqls`.

```js
scalar Date

type Query {
    getAllPerson: [Person!]
    getPersonById(id: Int!): Person
    getPersonByIdentityNumber(identityNumber: String!): Person

    getAllBook: [Book!]
    getAllBookByAuthor(author: String!): [Book!]
    getBookById(id: Int!): Book!
}

type Mutation {
    createPerson(input: PersonInput!): Person!
    updatePerson(input: PersonInput!, id: Int!): Person!
    deletePerson(id: Int!): OkMessage!

    addBook(input: BookInput!): Book!
    updateBook(input: BookInput!, id: Int!): Book
    deleteBook(id: Int!): OkMessage!
}

type Book {
    id: Int!,
    author: Person!,
    title: String!,
    publisher: String!,
    description: String,
    releaseDate: Date!,
    createdAt: Date,
    createdBy: Int,
    updatedAt: Date
}

input BookInput {
    authorId: Int!,
    title: String!,
    publisher: String!,
    description: String,
    releaseDate: Date!
}
```

Try to run by typing `mvn spring-boot:run` then open Postman like below. You can edit any field you want.

`URL: http://localhost:8080/graphql (POST)`

**Add Book**

Query

```js
mutation AddBook($input: BookInput!){
    addBook(input: $input) {
        id
        title
        createdAt
        author {
            id
            firstName
            address
        }
    }
}
```

GraphQL Variables

```json
{
    "input": {
        "authorId": 2,
        "title": "Tutorial GraphQL",
        "publisher": "Github",
        "description": "How to build GraphQL server using Spring Boot",
        "releaseDate": "05-01-2021"
    }
}
```

Response

```json
{
    "data": {
        "addBook": {
            "id": 2,
            "title": "Tutorial GraphQL",
            "createdAt": "2021-01-05 15:06:15.846128",
            "author": {
                "id": 2,
                "firstName": "Maverick",
                "address": "Yogyakarta"
            }
        }
    }
}
```

**Get Book**

Query

```js
query {
    getBookById(id: 1) {
        id
        title
        releaseDate
        author {
            id
            firstName
            address
        }
        createdAt
    }
}
```

Response

```json
{
    "data": {
        "getBookById": {
            "id": 1,
            "title": "Tutorial GraphQL Spring Boot",
            "releaseDate": "2021-01-05 00:00:00.0",
            "author": {
                "id": 1,
                "firstName": "Alvinditya",
                "address": "Yogyakarta"
            },
            "createdAt": "2021-01-05 15:04:21.0"
        }
    }
}
```

**Update Book**

Query

```js
mutation UpdateBook($input: BookInput!){
    updateBook(input: $input, id: 2) {
        id
        title
        createdAt
        author {
            id
            firstName
            address
        }
    }
}
```

GraphQL Variables

```json
{
    "input": {
        "authorId": 2,
        "title": "Tutorial GraphQL Updated",
        "publisher": "Github",
        "description": "How to build GraphQL server using Spring Boot",
        "releaseDate": "06-01-2021"
    }
}
```

Response

```json
{
    "data": {
        "updateBook": {
            "id": 2,
            "title": "Tutorial GraphQL Updated",
            "createdAt": "2021-01-05 15:06:16.0",
            "author": {
                "id": 2,
                "firstName": "Maverick",
                "address": "Yogyakarta"
            }
        }
    }
}
```

**Delete Book**

Query

```js
mutation {
    deleteBook(id: 1) {
        message
    }
}
```

Response

```json
{
    "data": {
        "deleteBook": {
            "message": "ok"
        }
    }
}
```

### Clone or Download

You can clone or download this project
```bash
git@github.com:piinalpin/graphql-spring-boot.git
```

### Thankyou

[Medium](https://medium.com/supercharges-mobile-product-guide/graphql-server-using-spring-boot-part-i-722bdd715779) - GraphQL server using Spring Boot, Part I

[Baeldung](https://www.baeldung.com/spring-graphql) - Getting Started with GraphQL and Spring Boot

[Github](https://github.com/team-supercharge/spring-boot-graphql-tutorial) - Team Supercharge
