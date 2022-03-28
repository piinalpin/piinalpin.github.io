# Create Sequence Like Oracle in MySQL


<!--more-->

### Prerequisites
* [MySQL](https://www.mysql.com/)

### Step to create a custom sequence like Oracle in MySQL

1. Set global `log_bin_trust_function_creator` to 1
```mysql
SET GLOBAL log_bin_trust_function_creators = 1;
```

2. Create a sequence table
```mysql
CREATE TABLE IF NOT EXISTS SEQUENCE (name VARCHAR(255) PRIMARY KEY, value INT UNSIGNED);
```

3. Drop function `nextval()` if exists on your database
```mysql
DROP FUNCTION IF EXISTS nextval;
```

4. Create a custom sequence call `nextval('sequence_name')`, and will returns the next value. If name of sequence does not exists, it will created automatically by initial value 1.

```mysql
DELIMITER //

CREATE FUNCTION nextval (sequence_name VARCHAR(255))
RETURNS INT UNSIGNED
BEGIN
INSERT INTO SEQUENCE VALUES (sequence_name, LAST_INSERT_ID(1))
ON DUPLICATE KEY UPDATE value=LAST_INSERT_ID(value+1);
RETURN LAST_INSERT_ID();
END
//
```

5. Changing back delimiter to semicolon
```mysql
DELIMITER ;
```

6. Create table to test a custom sequence, default id defined by zero (0)
```mysql
CREATE TABLE IF NOT EXISTS HUMAN
(id int UNSIGNED NOT NULL PRIMARY KEY DEFAULT 0,
name VARCHAR(50));
```

7. Drop nextval trigger if exists.
```mysql
DROP TRIGGER IF EXISTS nextval;
```

8. Create a custom trigger for `nextval()` function
The trigger only generated a new id if 0 is inserted. So, if you create a new table and field id with default value by zero (0) that makes it implicit.
```mysql
CREATE TRIGGER nextval_human BEFORE INSERT ON HUMAN
FOR EACH ROW SET new.id=IF(new.id=0,nextval('ID_HUMAN_SEQ'),new.id);
```

9. Let's try a sample data on HUMAN table
```mysql
INSERT INTO HUMAN (name) VALUES ('Maverick'), ('John Doe'), ('Al Sah-Him');
```

10. Inserted data look likes

![HUMAN Data](/images/human_data.png)

11. Let's try another table `BOOK` to test a sequence
```mysql
CREATE TABLE IF NOT EXISTS BOOK
(id int UNSIGNED NOT NULL PRIMARY KEY DEFAULT 0,
name VARCHAR(50), code VARCHAR(50));
```

12. Create `ID_BOOK_SEQ` trigger to a new sequence
```mysql
CREATE TRIGGER nextval_book BEFORE INSERT ON BOOK
FOR EACH ROW SET new.id=IF(new.id=0,nextval('ID_BOOK_SEQ'),new.id);
```

13. Insert data into `BOOK` table
```mysql
INSERT INTO BOOK (name, code) VALUES ('Book 1', 'BK-01'), ('Book 2', 'BK-02'), ('Book 3', 'BK-03');
```

14. Show the data

![BOOK Data](/images/book_data.png)

15. Let's check generated custom sequence

![Custom Sequence](/images/custom_sequence.png)

### Thankyou

[Open Query](https://openquery.com.au/blog/implementing-sequences-using-a-stored-function-and-triggers) - Implementing Sequences using a Stored Function and Triggers

