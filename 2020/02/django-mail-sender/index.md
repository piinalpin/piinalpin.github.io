# Django Mail Sender With Rabbit-MQ and Celery Worker


### Prerequisites

* [Erlang (Open Telecom Platform)](https://www.erlang.org/)
* [RabbitMQ (Message Broker)](https://www.rabbitmq.com/)
* [Pyhton 3.6 (Base Compiler)](https://www.python.org/)
* [Sendgrid Account (SMTP Client)](https://sendgrid.com/)
* [Virtualenv](https://virtualenv.pypa.io/en/latest/)

### Step to create Django mail sender

1. Create virtual environtment in root directory on your project and activate it

```bash
virtualenv env
. env/bin/activate
```

2. Install Django 2.1

```bash
pip install Django==2.1.2
```

3. Create project and application in Django

```bash
django-admin startproject your_project_name
django-admin startapp your_apps_name
```

4. Install library celery and celery-message-consumer

```bash
pip install celery
pip install celery-message-consumer
```

5. Edit django base settings `project_name/settings.py`

Change DEBUG to False and ALLOWED_HOST to localhost

```python
# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

ALLOWED_HOSTS = ['localhost']
```

Add email configuration

```python
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.sendgrid.net'
EMAIL_HOST_USER = <Your_Username>
EMAIL_HOST_PASSWORD = <Your_Password>
EMAIL_PORT = 587
EMAIL_USE_TLS = True
DEFAULT_FROM_EMAIL = "Info KS-Linux UAD <info@kslinux.tif.uad.ac.id>"
```

Add RabbitMQ configuration

```python
# RabbitMQ Configuration
RABBIT_HOST = "localhost"
RABBIT_PORT = "5672"
RABBIT_VIRTUAL_HOST = "/"
RABBITMQ_ROUTING_KEY = "mail_consumer"
# RabbitMQ Credentials
RABBIT_USERNAME = "guest"
RABBIT_PASSWORD = "guest"
```

Add application at configuration

```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django',
    'mail_consumer',
]
```

Create logging configuration and create `logs` directory

```python
# Logging Configuratino
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue'
        }
    },
    'formatters': {
        'main_formatter': {
            'format': '%(levelname)s:%(name)s: %(message)s '
                      '(%(asctime)s; %(filename)s:%(lineno)d)',
            'datefmt': "%Y-%m-%d %H:%M:%S",
        },
    },
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler'
        },
        'console': {
            'level': 'DEBUG',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'main_formatter',
        },
        'production_file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/main.log',
            'maxBytes': 1024 * 1024 * 5,  # 5 MB
            'backupCount': 7,
            'formatter': 'main_formatter',
            'filters': ['require_debug_false'],
        },
        'debug_file': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/main_debug.log',
            'maxBytes': 1024 * 1024 * 5,  # 5 MB
            'backupCount': 7,
            'formatter': 'main_formatter',
            'filters': ['require_debug_true'],
        },
        'null': {
            "class": 'logging.NullHandler',
        }
    },
    'loggers': {
        'django.request': {
            'handlers': ['mail_admins', 'console'],
            'level': 'ERROR',
            'propagate': True,
        },
        'django': {
            'handlers': ['null', ],
        },
        'py.warnings': {
            'handlers': ['null', ],
        },
        '': {
            'handlers': ['console', 'production_file', 'debug_file'],
            'level': "DEBUG",
        },
    }
}
```

Create queue name or exchange to RabbitMQ and Celery by-pass log

```python
# ADD CELERY BYPASS LOG
CELERYD_HIJACK_ROOT_LOGGER = False

# CREATE QUEUE TO RABBITMQ
EXCHANGES = {
    # a reference name for this config, used when attaching handlers
    'default': {
        'name': 'data',  # actual name of exchange in RabbitMQ
        'type': 'mail_consumer',  # an AMQP exchange type
    },
}
```

6. Create function send in `app_name/views.py`

```python
from trinity import settings
from django.core.mail import EmailMultiAlternatives

def sender(data):
    try:
        subject = data['subject']
        body = data['text']
        from_email = settings.DEFAULT_FROM_EMAIL
        to = data['to']
        html_body = data['html']
        messages = EmailMultiAlternatives(subject, body, from_email, to)
        messages.attach_alternative(html_body, "text/html")
        messages.attach_file(data['file'], 'image/jpg')
        messages.send()
        print("Email has been sent!")
    except:
        print("Can not sent email, something wrong!")
```

7. Create task listener to RabbitMQ queue `app_name/tasks.py`

```python
import json
from django.conf import settings
from event_consumer import message_handler

@message_handler(settings.RABBITMQ_ROUTING_KEY)
def listen_queue(body):
    print(body)
    # CREATE PAYLOAD FROM BODY
    payload = json.loads(body)
    print("==================================");
    # PRINT PAYLOADS
    print(payload)
    # CALL FUNCTION SENDER FROM VIEWS
    from .views import sender
    sender(payload)
```

8. Create celery worker `project_name/celery.py`

```python
# IMPORT LIBRARY TO CONNECT WITH RABBITMQ
from __future__ import absolute_import
import os
from celery import Celery
from celery.signals import setup_logging
from event_consumer.handlers import AMQPRetryConsumerStep

from trinity.settings import LOGGING
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'trinity.settings')

# CREATE APP CELERY
app = Celery('trinity')
app.steps['consumer'].add(AMQPRetryConsumerStep)

# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')
# Load task modules from all registered Django app configs.
app.autodiscover_tasks()

# CREATE TASKS
@app.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))

@setup_logging.connect()
def configure_logging(sender=None, **kwargs):
    import logging.config
    logging.config.dictConfig(LOGGING)
```

9. Create test send message to broker with pika. Create new file outside the project and then create new virtual environtment. Install `pika` to create connection with broker.

```bash
pip install pika
```

10. Create file wihich is send message to the broker `test_send_email.py`

```python
import pika
import sys

# GET CONNECTION TO RABBITMQ
connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='mail_consumer', durable=True)

message = """
{
    "subject": "Registration of Training Asynchronous Programming",
    "text": "Congratulations you have registered as participants of asynchronous programming. We have attached a ticket registration, please download.",
    "html":"<h2>Congratulations you have registered as participants of asynchronous programming. We have attached a ticket registration, please download.</h2>",
    "to": ["<Your_Destination_Email>"],
    "file": "<Attachment>"
}
"""
# PUSH MESSAGE TO QUEUE MAIL_CONSUMER
channel.basic_publish(exchange='',
                      routing_key='mail_consumer', # This is routing key which must be the same as celery routing key
                      body=message,
                      properties=pika.BasicProperties(
                         delivery_mode = 2, # make message persistent
                      ))
print(" [x] Sent %r" % message)
connection.close()
```

11. Run the test send message
```bash
python test_send_email.py`
```

12. Activate RabbitMQ management then you can check request payload on RabbitMQ -> Queue -> Get Messages `http://localhost:15672`

13. Run celery project

```bash
pip celery worker -A your_project_name.celery.app
```

### Built With

* [Python 3](https://www.python.org/download/releases/3.0/) - The language programming used
* [Django 2](https://www.djangoproject.com/) - The web framework used
* [Virtualenv](https://virtualenv.pypa.io/en/latest/) - The virtual environment used
* [Celery](https://docs.celeryproject.org/en/stable/userguide/workers.html) - Celery worker to create connection with RabbitMQ

### Clone or Download

You can clone or download this project
```bash
git clone https://github.com/piinalpin/trinity.git
```