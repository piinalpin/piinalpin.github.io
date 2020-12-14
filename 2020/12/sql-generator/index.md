# SQL Insert Generator from Excel File using Python


<!--more-->

### Prerequisites
* [Python](https://www.python.org/)
* [Pandas](https://pandas.pydata.org/)
* [Click](https://click.palletsprojects.com/en/7.x/)

```bash
pip install pandas click
```

### Step to create a SQL insert generator using python

1. Create data in excel file, we'll create an example data

Sheet name : M_ACCOUNT

| ID      | FULLNAME | ADDRESS      | IDENTITY_NUMBER | IDENTITY_TYPE      | COUNTRY |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| 1      | John Doe       | Yogyakarta      | 34754354986       | KTP      | Indonesia       |
| 2      | Maverick       | Jakarta      | 43589743545       | KTP      | Indonesia       |
| 3      | Al Sah-Him       | Semarang      | 58479846645       | KTP      | Indonesia       |

Sheet name : M_USER

| ID      | USERNAME | PASSWORD      | M_ACCOUNT_ID |
| ----------- | ----------- | ----------- | ----------- |
| 1      | johndoe       | $2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC      | 1       |
| 2      | maverick       | $2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC      | 2       |
| 3      | alsahhim       | $2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC      | 3       |


2. Create python file call `sql_generator.py`

```python
import click
import errno
import os
import pandas as pd

@click.command()
@click.option('--generate', '-g', help='Change TEXT to generate excel file into SQL insert')
@click.option('--outputdir', '-o', help='Change TEXT to create directory output file')
def main(generate, outputdir):
	try:
		# Validate generate file can not be None
		if generate is None:
			raise TypeError

		# Check if outputdir is not None
		if outputdir != None:
			try:
				# Create a directory
			    os.makedirs(outputdir)
			    outputdir = "{}/".format(outputdir)
			except OSError as exc:
				# If directory is exists use this directory
				if exc.errno == errno.EEXIST:
					outputdir = "{}/".format(outputdir)
		file = pd.ExcelFile(generate)
		for sheet_name in file.sheet_names:
		    data = file.parse(sheet_name)
		    filename = "{}{}.sql".format(outputdir, sheet_name)
		    click.echo("### {}:".format(filename))
		    write_file = open(filename, "w")
		    for i, _ in data.iterrows():
		        field_names = ", ".join(list(data.columns))
		        rows = list()
		        for column in data.columns:
		            rows.append(str(data[column][i]))
		        row_values = "'" + "', '".join(rows) + "'"
		        click.echo("INSERT INTO {} ({}) VALUES ({});".format(sheet_name, field_names, row_values))
		        write_file.write("INSERT INTO {} ({}) VALUES ({});\n".format(sheet_name, field_names, row_values))
		    write_file.close()
	except TypeError as e:
		click.echo("Error: Unknown generate file! Type -h for help.")

if __name__ == "__main__":
    main()
```

This file will create command `sql_generator.py --generate filename.xlsx --outputdir dir`

Type `sql_generator.py --help` to show help command

3. Generator will be create a sql file according sheet name

File `M_ACCOUNT.sql`

```sql
INSERT INTO M_ACCOUNT (ID, FULLNAME, ADDRESS, IDENTITY_NUMBER, IDENTITY_TYPE, COUNTRY) VALUES ('1', 'John Doe', 'Yogyakarta', '34754354986', 'KTP', 'Indonesia');
INSERT INTO M_ACCOUNT (ID, FULLNAME, ADDRESS, IDENTITY_NUMBER, IDENTITY_TYPE, COUNTRY) VALUES ('2', 'Maverick', 'Jakarta', '43589743545', 'KTP', 'Indonesia');
INSERT INTO M_ACCOUNT (ID, FULLNAME, ADDRESS, IDENTITY_NUMBER, IDENTITY_TYPE, COUNTRY) VALUES ('3', 'Al Sah-Him', 'Semarang', '58479846645', 'KTP', 'Indonesia');
```

File `M_USER.sql`

```sql
INSERT INTO M_USER (ID, USERNAME, PASSWORD, M_ACCOUNT_ID) VALUES ('1', 'johndoe', '$2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC', '1');
INSERT INTO M_USER (ID, USERNAME, PASSWORD, M_ACCOUNT_ID) VALUES ('2', 'maverick', '$2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC', '2');
INSERT INTO M_USER (ID, USERNAME, PASSWORD, M_ACCOUNT_ID) VALUES ('3', 'alsahhim', '$2y$12$tRgbrmjdyytEyv8ceakIc.7vUCjLfpEi6K/Ube0hB5X4c7vPcMMQC', '3');
```

### Thankyou

[codeburst.io](https://codeburst.io/building-beautiful-command-line-interfaces-with-python-26c7e1bb54df) - Building Beautiful Command Line Interfaces with Python

[$ click_](https://click.palletsprojects.com/en/7.x/commands/) - Commands and Groups


