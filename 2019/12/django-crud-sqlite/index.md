# Simple Django CRUD App With SQLite


#### Codename : Rattlesnake

## Prerequisites

Make sure you have installed Python 3 and virtual environment on your device

### Project structure
File structure in django by default has a structure like below
```
* django-crud-sqlite/
  |--- rattlesnake/
  |    |--- app/
  |    |    |--- migrations/
  |    |    |--- templates/
  |    |    |--- __init__.py
  |    |    |--- admin.py
  |    |    |--- apps.py
  |    |    |--- models.py
  |    |    |--- tests.py
  |    |    |--- views.py
  |    |--- rattlesnake/
  |    |    |--- __init__.py
  |    |    |--- settings.py
  |    |    |--- urls.py
  |    |    |--- wsgi.py
  |    |--- manage.py
  |--- venv/
```

### Step to create django crud

A step by step series of examples that tell you how to get a development env running

1. Create virtual environment and activate inside your `django-crud-sqlite/` directory according the above structure
```
virtualenv venv
> On windows -> venv\Scripts\activate
> On linux -> . env/bin/activate
```
2. Install django and start new project inside your `django-crud-sqlite/` directory according the above structure
```
pip install django
django-admin startproject rattlesnake
cd rattlesnake
```
3. Create new app, from `rattlesnake/` directory will create create new `app/` to store the collection
```
> On Windows -> manage.py startapp app
> On Linux, etc -> ./manage.py startapp app
```
4. Register your app into `rattlesnake` project, the `app` to `INSTALLED_APP` in `rattlesnake/settings.py`
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    :
    'app',
    :
]
```
5. Create the model to define the table structure of database and save the collection into database `app/models.py`
```python
from django.db import models
from django.urls import reverse

# Create your models here.
class Student(models.Model):
    name = models.CharField(max_length=200, null=False)
    identityNumber = models.CharField(max_length=200, null=False)
    address = models.CharField(max_length=200, null=True)
    department = models.CharField(max_length=200, null=True)

    def __str__(self):
        return self.name
    
    # The absolute path to get the url then reverse into 'student_edit' with keyword arguments (kwargs) primary key
    def get_absolute_url(self):
        return reverse('student_edit', kwargs={'pk': self.pk})
```
6. Every after change `models.py` you need to make migrations into `db.sqlite3` (database) to create the table for the new model
```
manage.py makemigrations
manage.py migrate
```
7. Create the views to create app pages on browser, the file is `app/views.py` according the above structure
```python
from django.http import HttpResponse
from django.shortcuts import render
from django.views.generic import ListView, DetailView
from django.views.generic.edit import CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy

from .models import Student

# Create your views here.

class StudentList(ListView):
    model = Student

class StudentDetail(DetailView):
    model = Student

class StudentCreate(CreateView):
    model = Student
    # Field must be same as the model attribute
    fields = ['name', 'identityNumber', 'address', 'department']
    success_url = reverse_lazy('student_list')

class StudentUpdate(UpdateView):
    model = Student
    # Field must be same as the model attribute
    fields = ['name', 'identityNumber', 'address', 'department']
    success_url = reverse_lazy('student_list')

class StudentDelete(DeleteView):
    model = Student
    success_url = reverse_lazy('student_list')
```
8. Then, create file `app/urls.py` to define app url path (in CI as same as route function)
```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.StudentList.as_view(), name='student_list'),
    path('view/<int:pk>', views.StudentDetail.as_view(), name='student_detail'),
    path('new', views.StudentCreate.as_view(), name='student_new'),
    path('edit/<int:pk>', views.StudentUpdate.as_view(), name='student_edit'),
    path('delete/<int:pk>', views.StudentDelete.as_view(), name='student_delete'),
]
```
9. The `app/urls.py` would not work unless you include that into the main url `rattlesnake/urls.py`
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    :
    path('student/', include('app.urls')),
    :
]
```
10. Create the html file to display user interface, you need create directory `app/templates/app/` like below
```
* django-crud-sqlite/
  |--- rattlesnake/
  |    |--- app/
  |    |    |--- migrations/
  |    |    |--- templates/
  |    |    |    |--- app/
  |    |    |--- __init__.py
  |    |    |--- admin.py
  |    |    |--- apps.py
  |    |    |--- models.py
  |    |    |--- tests.py
  |    |    |--- views.py
  |    |--- rattlesnake/
  |    |    |--- __init__.py
  |    |    |--- settings.py
  |    |    |--- urls.py
  |    |    |--- wsgi.py
  |    |--- manage.py
  |--- venv/
```
11. Create file `app/templates/app/student_list.html` to display or parsing student list data with `ListView` library
12. Create file `app/templates/app/student_detail.html` to display or parsing data of each student and will used by `DetailView` library
```html
<h1>Student Detail</h1>
<h3>Name : {{ object.name }}</h3>
<h3>Identity Number : {{ object.identityNumber }}</h3>
<h3>Address : {{ object.address }}</h3>
<h3>Department : {{ object.department }}</h3>
```
13. Create file `app/templates/app/student_form.html` to display form input and edit views
14. Create file `app/templates/app/student_confirm_delete.html` to display promt or alert confirmation to delete the object view
15. Test the project
```
manage.py runserver
```

### After change structure of flask project
```
* django-crud-sqlite/
  |--- rattlesnake/
  |    |--- app/
  |    |    |--- migrations/
  |    |    |--- templates/
  |    |    |    |--- app/
  |    |    |    |    |--- student_confirm_delete.html
  |    |    |    |    |--- student_detail.html
  |    |    |    |    |--- student_form.html
  |    |    |    |    |--- student_list.html
  |    |    |--- __init__.py
  |    |    |--- admin.py
  |    |    |--- apps.py
  |    |    |--- models.py
  |    |    |--- tests.py
  |    |    |--- urls.py
  |    |    |--- views.py
  |    |--- rattlesnake/
  |    |    |--- __init__.py
  |    |    |--- settings.py
  |    |    |--- urls.py
  |    |    |--- wsgi.py
  |    |--- db.sqlite3
  |    |--- manage.py
  |--- venv/
```

## Built With

* [Python 3](https://www.python.org/download/releases/3.0/) - The language programming used
* [Django 2](https://www.djangoproject.com/) - The web framework used
* [Virtualenv](https://virtualenv.pypa.io/en/latest/) - The virtual environment used
* [SQLite 3](https://www.sqlite.org/index.html) - The database library

## Clone or Download

You can clone or download this project
```
> Clone : git clone https://github.com/piinalpin/django-crud-sqlite.git
```

<!--more-->
