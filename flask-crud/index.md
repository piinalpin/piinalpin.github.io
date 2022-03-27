# Simple CRUD App with Flask And SQL-Alchemy

### Prerequisites

Make sure you have installed Python 3 on your device

### Project structure
```
* flask-project/
  |--- app/
  |    |--- module/
  |    |    |--- __init__.py
  |    |    |--- controller.py
  |    |    |--- models.py
  |    |--- templates/ (html file)
  |    |--- __init__.py
  |--- venv/
  |--- run.py
```

### Step to create flask crud

A step by step series of examples that tell you how to get a development env running

1. Install virtual environment
```
pip install virtualenv
```
2. Create virtual environment and activate inside your flask-crud directory according the above structure
```
virtualenv venv
> On windows -> venv\Scripts\activate
> On linux -> . env/bin/activate
```
3. Install some third party librares on your virtual environment with pip
```
pip install flask sqlalchemy flask-sqlalchemy
```
4. Create `run.py` directory inside flask-project according the above structure
```python
from app import app
app.run(debug=True, host='127.0.0.1', port=5000)
```
5. Create `controller.py` according the abpove structure `flask-crud/app/module/`
```python
from flask import render_template, request
from app import app

@app.route('/')
def index():
    return "My CRUD Flask App"
```
6. Create `__init__.py` inside app directory according the above structure `flask-crud/app/`
```python
from flask import Flask

app = Flask(__name__)

from app.module.controller import *
```
7. Run first this application to make sure can running with terminal or command promt
```
python run.py
```
9. Access `localhost:5000` according port that created in `run.py`

![Sample 1](https://raw.githubusercontent.com/piinalpin/flask-crud/master/Image-1.PNG)

10. Create an input form called `home.html` inside `templates` directory according the above structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Flask Crud</title>
</head>
<body>
<h3>Form Add Mahasiswa</h3>
<form action="/" method="POST">
    <table>
        <tr>
            <td>Nama Lengkap</td>
            <td>:</td>
            <td><input type="text" name="name"></td>
        </tr>
        <tr>
            <td>Nomor Induk Mahasiswa</td>
            <td>:</td>
            <td><input type="text" name="nim"></td>
        </tr>
        <tr>
            <td><button type="submit">Save</button></td>
        </tr>
    </table>
</form>
</body>
</html>
```
11. Change `return "My CRUD Flask App"` in `controller.py` to `return render_template("home.html")` 
```python
from flask import render_template, request
from app import app

@app.route('/')
def index():
    return render_template("home.html")
```

![Sample 2](https://raw.githubusercontent.com/piinalpin/flask-crud/master/Image-2.PNG)

12. Then modify function `index()` to accept method `POST` request
```python
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        print(request.form)
    return render_template("home.html")
```
![Sample 3](https://raw.githubusercontent.com/piinalpin/flask-crud/master/Image-3.PNG)
![Sample 4](https://raw.githubusercontent.com/piinalpin/flask-crud/master/Image-4.PNG)

13. Configure the database with SQLAlchemy, you should modify `__init__.py` and it will be created `flaskcrud.db` inside `app` directory
```python
import os
from flask import Flask

project_dir = os.path.dirname(os.path.abspath(__file__))
database_file = "sqlite:///{}".format(os.path.join(project_dir, "flaskcrud.db"))

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = database_file
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = True

from app.module.controller import *
```
14. Define model to application, you should create `models.py` file inside `module` directory according the above structure.
```python
from flask_sqlalchemy import SQLAlchemy
from app import app

db = SQLAlchemy(app)

class Mahasiswa(db.Model):
    id = db.Column(db.Integer, unique=True, primary_key=True, nullable=False)
    nim = db.Column(db.String, nullable=False)
    name = db.Column(db.String, nullable=False)

    def __repr__(self):
        return "<Name: {}>".format(self.name)
```

15. The structure of database should like as follows

Mahasiswa  |
------------- |
`id (Integer, PK, Autoincrement, NOT NULL)`  |
`name (String, NOT NULL)`  |
`nim (String, NOT NULL)`  |

16. Stop app if that is still running, press `CTRL+C` key to quit and type `python` to go to python terminal

![Sample 5](https://raw.githubusercontent.com/piinalpin/flask-crud/master/Image-5.PNG)

17. Type command bellow to create database file `flaskcrud.db`
```
>>> from app.module.models import db
>>> db.create_all()
>>> exit()
```
18. The structure project will be look as follows
```
* flask-project/
  |--- app/
  |    |--- module/
  |    |    |--- __init__.py
  |    |    |--- controller.py
  |    |    |--- models.py
  |    |--- templates/ (html file)
  |    |--- __init__.py
  |    |--- flaskcrud.db
  |--- venv/
  |--- run.py
```
19. Import database from `models.py` add this line `from .models import db, Mahasiswa` to the `controller.py`, it's mean import from `models.py` for `db` variable and class `Mahasiswa`
20. Modify `controller.py` to create function to storing data of `Mahasiswa` then save to the database that is already made and retrieving data with `Mahasiswa.query.all()` it will be retrieving all data from database then made with `try` and `except` to handling an error
```python
@app.route('/', methods=['GET','POST'])
def index():
    if request.method == 'POST':
        name = request.form['name']
        nim = request.form['nim']
        try:
            mhs = Mahasiswa(nim=nim, name=name)
            db.session.add(mhs)
            db.session.commit()
        except Exception as e:
            print("Failed to add data.")
            print(e)
    listMhs = Mahasiswa.query.all()
    print(listMhs)
    return render_template("home.html", data=enumerate(listMhs,1))
```
21. The statement of `data=enumerate(listMhs,1)` mean data will show from 1 and so on, not from the id, see __https://github.com/piinalpin/flask-crud/blob/master/README.md#step-to-create-flask-crud__

23. Then create function to __UPDATE__ data from the collections in `controller.py`, on __UPDATE__ you should create two function to load or render form input and update to database from method __POST__ on form input using `Mahasiswa.query.filter_by(id=id).first()` to find data filter by id and `db.session.commit()` to save the data
```python
@app.route('/form-update/<int:id>')
def updateForm(id):
    mhs = Mahasiswa.query.filter_by(id=id).first()
    return render_template("form-update.html", data=mhs)

@app.route('/form-update', methods=['POST'])
def update():
    if request.method == 'POST':
        id = request.form['id']
        name = request.form['name']
        nim = request.form['nim']
        try:
            mhs = Mahasiswa.query.filter_by(id=id).first()
            mhs.name = name
            mhs.nim = nim
            db.session.commit()
        except Exception as e:
            print("Failed to update data")
            print(e)
        return redirect("/")
```
24. And modify import flask on top line change to `from flask import render_template, request, redirect`

25. Then create the __DELETE__ function to delete data from the collections in `controller.py` using filter by id and `db.session.delete(mhs)` function
```python
@app.route('/delete/<int:id>')
def delete(id):
    try:
        mhs = Mahasiswa.query.filter_by(id=id).first()
        db.session.delete(mhs)
        db.session.commit()
    except Exception as e:
        print("Failed delete mahasiswa")
        print(e)
    return redirect("/")
```

### After change structure of flask project
```
* flask-project/
  |--- app/
  |    |--- module/
  |    |    |--- __init__.py
  |    |    |--- controller.py
  |    |    |--- models.py
  |    |--- templates/
  |    |    |--- form-update.html
  |    |    |--- home.html
  |    |--- __init__.py
  |    |--- flaskcrud.db
  |--- venv/
  |--- run.py
```

### Built With

* [Python 3](https://www.python.org/download/releases/3.0/) - The language programming used
* [Flask](http://flask.pocoo.org/) - The web framework used
* [Virtualenv](https://virtualenv.pypa.io/en/latest/) - The virtual environment used
* [SQL Alchemy](https://www.sqlalchemy.org/) - The database library
* [Flask-SQLAlchemy](http://flask-sqlalchemy.pocoo.org/2.3/) - Flask and SQL Alchemy connector

### Want to demo online?
__[Flask Crud With SQL Alchemy Built in Python 3](https://flask-crud-sample.herokuapp.com)__

### Clone or Download

You can clone or download this project
```
> Clone : git clone https://github.com/piinalpin/flask-crud.git
```


<!--more-->
