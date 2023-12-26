# Why Clean Code is Important?


### What is Clean Code?
![Clean Code](/images/clean-code.png)

Clean code is term used to refer to code that **easy to read, understand, and maintain**. The goals of clean code is to create software that is not only functional but also **readable**, **maintainable**, and **eficient** throughout its lifecycle which can save time and reduce the risk of introducing errors.

### Benefits of Clean Code
1. ***Readability:*** Clean code is easy to read and understand, making it easier to maintain, debug and update. When code is well-organized and well-structured, it is more accessible to other developer who may need to work on the same codebase.

2. **Maintainability:** Clean code is designed to be easily maintainable over time. It can sace time and effort in the long run and can help prevent code from becoming obsolete. This makes it simpler to debug, modify and enhance the codebase.

3. **Scalability:** Clean code is more scalable, code base should be more easily extended and modified to support new features or requirements. This can help ensure that the codebase is flexible and adaptable to changing needs.

4. **Collaboration**: Clean code promotes effective cllaboration within development teams. When code is clean and readable, it becomes easier for teams member to review and providde feedback. It fosters a shared understandiung of the codebase and encourages knowledge sharing among developers and improving overall team productivity.

5. **Eficiency:** Clean code is should be eficient and it can run faster, use less memory and can improve the overall performance of an application. And can reduce the complexity of the codebase.

6. **Debugging:** Clean code is designed with clarity and simplicity, making it easier to locate and understand specific section of the codebase. Clean structure, meaningful variable names, and well-defined function make it easier to identify root cause and resolve issues.

7. **Reusability:** Clean code make our code is more reusable in other projects or part of the same project. This can help save time and effor by avoiding redundant or duplication code.

    ![Valid MEasurement](/images/valid-measurement.jpg)

### Clean Code Characteristic
**Easy to Understand**

- Don't do this ❌
  ```java
  double b = 125.0;
  int[] data = {2, 3, 5, 7};
  List<String> locations = List.of("New York", "Sydney", 
      "Texas", "San Francisco");

  locations.forEach((l) -> {
      doStuff();
      doSomeOtherStuff();
      ...
      // Wait, `l` for what?
      doAnotherThing(l);
  });
  ```
- Do this ✅
  ```java
  double balance = 125.0;
  int[] primeNumbers = {2, 3, 5, 7};
  List<String> locations = List.of("New York", "Sydney", 
      "Texas", "San Francisco");

  locations.forEach((location) -> {
      doStuff();
      doSomeOtherStuff();
      ...
      doAnotherThing(location);
  });
  ```
**Easy Spelling**

- Don't do this ❌
  ```java
  LocalDate localDate = LocalDate.parse("1991-12-21");
  String fName = "John Doe";
  int dvdr = 2;

  validateTransaction(localDate, dvdr);
  Thread.sleep(1000); // 1000 for what?
  ```
- Do this ✅
  ```java
  public static final Long MILLISECONDS_DELAY = 1000;

  LocalDate transactionDate = LocalDate.parse("1991-12-21");
  String fullName = "John Doe";
  int divider = 2;

  validateTransaction(transactionDate, divider);
  Thread.sleep(MILLISECONDS_DELAY);
  ```

**Consistent**

Our code should be consistent of naming convention.

- Don't do this ❌
  ```java
  getUserId();
  getCustomerName();
  validateTransaction();

  public static final String CLIENT_ID = "clientid";
  public static final String clientSecret = "secret";

  String songs[] = {"Hey Jude", "Nightmare", "What I've Done"};
  String Artists[] = {"The Beatles", "Avenged Sevenfold", "Linkin Park"};

  public void deleteById() {}
  public String get_full_name() {}

  public class car {}
  public class Book {}
  ```
- Do this ✅
  ```java
  getUserId();
  getCustomerName();
  validateTransaction();

  public static final String CLIENT_ID = "clientid";
  public static final String CLIENT_SECRET = "secret";

  String songs[] = {"Hey Jude", "Nightmare", "What I've Done"};
  String artists[] = {"The Beatles", "Avenged Sevenfold", "Linkin Park"};

  public void deleteById() {}
  public String getFullName() {}

  public class Car {}
  public class Book {}
  ```

**Avoid Adding Unnecessary Context**

- Don't do this ❌
  ```java
  public class Vehicle {
    private String vehicleModel;
    private String vehicleColor;
    private String vehicleType;

    // Setter getter method
  }

  public static void main(String args[]) {
    Vehicle vehicle = new Vehicle();
    vehicle.setVehicleModel("Fortuner");
    vehicle.setVehicleColor("Black");
    vehicle.setVehicleType("SUV");
  }
  ```
- Do this ✅
  ```java
  public class Vehicle {
    private String model;
    private String color;
    private String type;

    // Setter getter method
  }

  public static void main(String args[]) {
    Vehicle vehicle = new Vehicle();
    vehicle.setModel("Fortuner");
    vehicle.setColor("Black");
    vehicle.setType("SUV");
  }
  ```
**Use Naming Convention**

There is an example naming convention:
- Javascript : https://github.com/airbnb/javascript
- Python : https://google.github.io/styleguide/pyguide.html

**Code Formatting**

Standardize each project maybe different. Here is the example code formatting.
- Line width code 80-120
- One Class 300-500 lines
- Lines of code that are related to each other
- Keep the function close to its caller
- Declaration of adjacent variables to their users
- Pay attention to identation
- Using prettier or formatter

### Clean Code Principle
**KISS (Keep it So Simple)**

Avoid creating functions created to perform A, while modifying B, checking C functions, etc.
- Functions or classes should be small
- Functions created to perform a single task only
- Don't use too many arguments on functions
- Care must be taken to achieve a balanced, small and minimal number of conditions

Don't do this ❌
```java
public void validateDueDate(LocalDateTime dueDate) {
  LocalDateTime today = LocalDateTime.now();
  if (today < dueDate) {
    // Do another stuff
  } else {
    throw new Exception("Due date exception");
  }
}
```
<br/>

Do this ✅
```java
public void dueDateIsValid(LocalDateTime dueDate) {
  LocalDateTime today = LocalDateTime.now();
  if (today > dueDate) throw new Exception("Due date exception");
  
  // Do another stuff
}
```
<br/>

**DRY (Don't Repeat Yourself)**

Code duplication occurs because of frequent copy and paste. To avoid duplication of code create functions that can be used repeatedly.

Don't do this ❌
```java
public Transaction generateTransaction(TransactionRequest request) {
  Transaction transaction;
  if ("MEMBER".equals(request.getMemberType())) {
    transaction = new Transaction();
    transaction.setType(request.getType());
    transaction.setDiscount(25);
    transaction.setFullName(request.getFullName());
    transaction.setAmount(request.getAmount());
    transaction.setTransactionDate(LocalDateTime.now());
  } else {
    transaction = new Transaction();
    transaction.setType(request.getType());
    transaction.setDiscount(0);
    transaction.setFullName(request.getFullName());
    transaction.setAmount(request.getAmount());
    transaction.setTransactionDate(LocalDateTime.now());
  }
  return transaction;
}
``` 
<br/>

Do this ✅
```java
public Transaction generateTransaction(TrasnsactionRequest request) {
  Transaction transaction = new Transaction();
  transaction.setType(request.getType());
  transaction.setDiscount(0);
  transaction.setFullName(request.getFullName());
  transaction.setAmount(request.getAmount());
  transaction.setTransactionDate(LocalDateTime.now());

  if ("MEMBER".equals(request.getMemberType())) {
    transaction.setDiscount(25);
  }

  return transaction;
}
```

<br/>

**Error Handling**

Use appropriate try-catch blocks or error handling mechanisms in our code. This prevents unexpected crashes and provides valuable information for debugging. Do not suppress errors or simply log them without a proper response.

Don't do this ❌
```java
try {
  int numbers[] = new int[10];
  numbers[10] = 30 / 0;
  return numbers;
} catch (Exception e) {
  System.out.println("An error occured");
}
```
<br/>

Do this ✅
```java
try {
  int numbers[] = new int[10];
  numbers[10] = 30 / 0;
  return numbers;
} catch (ArithmeticException e) {
  System.out.println("Can not divide by zero");
} catch (ArrayIndexOutOfBoundsException e) {
  System.out.println("Index out of size of the array");
}
```
<br/>
We also can define custom exception to handling expected exception.

```java
public class TransactionInvalidException extends RuntimeException () {

  public TransactionInvalidException() {
    super("Transaction is invalid!");
  }

}

public static void main(String args[]) {
  try {
    if (!transactionIsValid) throw new TransactionInvalidException();

    // Do stuff
  } catch (TransactionInvalidException e) {
    System.out.println(e.getMessage());
    throw e;
  }
}
```

<br/>

**Refactoring**

Refactoring is the process of restructuring the code created, by changing the internal structure without changing the external behavior. The principle of `KISS` and `DRY` can be achieved by refactoring.

### Conclusion
Clean code is not just a set of rules but a mindset and a dicipline. Writing clean code is an important practice that can save time, reduce the risk of errors and make code easier to understand, maintain and modify. We can become a more proficient developer who produces high-quality code. Clean code is a continous journey and with practice. It becomes a habit, leading to more efficient and enjoyable software development.
