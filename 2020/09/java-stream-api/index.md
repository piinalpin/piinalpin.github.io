# Java 8 Stream API Tutorial


### Prerequisites
Basic knowledge of Java 8 (lambda expressions, Optional, method references) of the Stream API. This tutorial is using Gson to pretty print JSON string.

### Object and Data Sampling
Create class `Pojo.java`
```java
public class Pojo {

    private String numberId;

    private String name;

    private String gender;

    public Pojo(String numberId, String name, String gender) {
        this.numberId = numberId;
        this.name = name;
        this.gender = gender;
    }

    public String getNumberId() {
        return numberId;
    }

    public void setNumberId(String numberId) {
        this.numberId = numberId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

}
```

In main application, create list pojo.
```java
public static void main(String[] args) {
	Gson gson = new GsonBuilder().setPrettyPrinting().create();
	List<Pojo> pojoList = new ArrayList<Pojo>();

	// Define object
	Pojo pojo1 = new Pojo("1", "John Doe", "M");
	Pojo pojo2 = new Pojo("2", "Maverick", "M");
	Pojo pojo3 = new Pojo("3", "Natalie", "F");
	Pojo pojo4 = new Pojo("4", "Gracia", "F");
	Pojo pojo5 = new Pojo("5", "Patrick", "M");

	// Add to array list
	pojoList.add(pojo1);
	pojoList.add(pojo2);
	pojoList.add(pojo3);
	pojoList.add(pojo4);
	pojoList.add(pojo5);

}
```

The json data is :

```json
[
  {
    "numberId": "1",
    "name": "John Doe",
    "gender": "M"
  },
  {
    "numberId": "2",
    "name": "Maverick",
    "gender": "M"
  },
  {
    "numberId": "3",
    "name": "Natalie",
    "gender": "F"
  },
  {
    "numberId": "4",
    "name": "Gracia",
    "gender": "F"
  },
  {
    "numberId": "5",
    "name": "Patrick",
    "gender": "M"
  }
]
```

### Grouping Collection

Using `import static java.util.stream.Collectors.groupingBy;` fo grouping array list pojo.

```java
Map<String, List<Pojo>> groupingPojo = pojoList.stream().collect(groupingBy(Pojo::getGender));
```

It will give an output :
```json
{
  "F": [
    {
      "numberId": "3",
      "name": "Natalie",
      "gender": "F"
    },
    {
      "numberId": "4",
      "name": "Gracia",
      "gender": "F"
    }
  ],
  "M": [
    {
      "numberId": "1",
      "name": "John Doe",
      "gender": "M"
    },
    {
      "numberId": "2",
      "name": "Maverick",
      "gender": "M"
    },
    {
      "numberId": "5",
      "name": "Patrick",
      "gender": "M"
    }
  ]
}
```

### Filtering Collection
Let's try filter the collection by Number ID and if not finding data then return null or you can fill new object from Pojo
```java
Pojo filterByNumber = pojoList.stream().filter(v -> v.getNumberId().equalsIgnoreCase("2")).findAny().orElse(null);
```

It will give an output :
```json
{
  "numberId": "2",
  "name": "Maverick",
  "gender": "M"
}
```

### Counting Collection
Let's try counting object by Gender.
```java
Long countByGender = pojoList.stream().filter(v -> v.getGender().equalsIgnoreCase("M")).count();
```

It will give an output :
```string
3
```

### Convert ArrayList to String
Let's try convert ArrayList to String and output it.
```java
String listToString = pojoList.stream().map(Pojo::getName).collect(Collectors.joining(", ", "", ""));
```

It will give an output :
```string
John Doe, Maverick, Natalie, Gracia, Patrick
```

### Returning Boolean using Any Match
Let's try using anyMatch on java Stream API.
```java
boolean findMaverick = pojoList.stream().anyMatch(v -> v.getName().equalsIgnoreCase("Maverick"));
```

It will give an output :
```string
true
```

### Thankyou
[Baeldung](https://www.baeldung.com/java-8-streams) - The Java 8 Stream API Tutorial