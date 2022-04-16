# Contextual Chat Bot using NLP


<!--more-->

### Overview

Contextual chat bots are bots that can chat with humans using everyday language that is appropriate to the topic humans are talking about. We will build a model for a puzzle conversation.

### Prerequisites

* [Python 3.x](https://www.python.org/)
* [Flask](https://flask.palletsprojects.com/en/2.0.x/)
* [NLTK](https://www.nltk.org)
* [TF Learn](http://tflearn.org)
* [Sastrawi](https://pypi.org/project/Sastrawi/)
* [Keras](https://keras.io/)

### Implementation

**Transform Conversational Intent Definitions to a Tensorflow Model**

A chatbot framework needs a structure in which conversational intents are defined. One clean way to do this is with a JSON file, like following bellow.

```json
{
  "intents": [
    {
      "tag": "greeting",
      "patterns": [
        "Hi",
        "Halo",
        "Hai",
        "Hello"
      ],
      "responses": [
        "Hai, ada yang bisa dibantu?",
        "Halo, ada yang bisa saya bantu?",
        "Hai, saya adalah WebSocket Bot."
      ],
      "context_set": ""
    },
    {
      "tag": "thanks",
      "patterns": [
        "Terimakasih",
        "Okay",
        "Ok",
        "Makasih",
        "Makasih ya",
        "Thanks"
      ],
      "responses": [
        "Senang membantu anda.",
        "Okay, sama sama.",
        "Hubungi saya kalau anda ingin mencari referensi lagi",
        "Okay, sama sama. Jangan lupa matikan notifikasi botnya biar gak mengganggu karena masih dalam tahap pengembangan"
      ]
    },
    {
      "tag": "kabar",
      "patterns": [
        "Apa kabar?",
        "Bagaimana kabarnya?",
        "Gimana kabarnya?",
        "Gmn kabarnya?"
      ],
      "responses": [
        "Aaa, Kabar saya baik.",
        "Luar biasa.",
        "Baik sekali hari ini",
        "Alhamdulillah, baik."
      ]
    },
    {
      "tag": "riddles",
      "patterns": [
        "tebak tebakan",
        "tebak-tebakan",
        "tebakan",
        "tebak",
        "humor",
        "lelucon",
        "lucu"
      ],
      "responses": [
        {
          "question": "Telor apa yang sangar?",
          "answer": "Telor asin, soalnya ada tatonya."
        },
        {
          "question": "Masak apa yang ragu-ragu?",
          "answer": "Masak iya sih?"
        },
        {
          "question": "Hewan apa yang paling kurang ajar?",
          "answer": "Kutu rambut, soalnya kepala orang diijak-injak."
        },
        {
          "question": "Benda mana yang lebih berat: kapas 10 kilo atau besi 10 kilo?",
          "answer": "Sama beratnya karena keduanya sama-sama 10 kilo."
        },
        {
          "question": "Apa yang mempunyai 12 kaki dan bisa terbang?",
          "answer": "6 ekor burung."
        },
        {
          "question": "Apa yang ada di ujung langit?",
          "answer": "Huruf T"
        },
        {
          "question": "Tamunya sudah masuk, tapi yang punya malah keluar. Apakah itu?",
          "answer": "Tukang becak lagi narik penumpang."
        },
        {
          "question": "Ikan apa yang bisa terbang hayo?",
          "answer": "Lele-lawar."
        },
        {
          "question": "Hewan apa ya yang banyak keahlian?",
          "answer": "Kukang. Ada kukang tambal ban, kukang servis motor, kukang ngomporin temen juga ada. Ups."
        },
        {
          "question": "Sayur apa yang paling dingin?",
          "answer": "Kembang cold."
        },
        {
          "question": "Sayur, sayur apa yang kasihan?",
          "answer": "Di-rebung semut."
        },
        {
          "question": "Kenapa sapi bisa jalan sendiri?",
          "answer": "Karena ada huruf i. Coba kalau diganti huruf u, bakal seram deh kalau gerak sendiri."
        },
        {
          "question": "Kebo apa yang bikin kita lelah?",
          "answer": "Kebogor jalan kaki."
        },
        {
          "question": "Sepatu, sepatu apa yang bisa di pakai masak?",
          "answer": "Sepatula (Spatula)."
        },
        {
          "question": "Telor, telor apa yang diinjak nggak pecah?",
          "answer": "Telortoar."
        },
        {
          "question": "Sayur apa yang pintar nyanyi?",
          "answer": "Kolplay."
        },
        {
          "question": "Bisnis apa yang sangat terkenal?",
          "answer": "Bisnispears (Britney Spears)."
        },
        {
          "question": "Sayur, sayur apa yang bersinar?",
          "answer": "Habis gelap, terbitlah terong."
        },
        {
          "question": "Mobil tabrakan di jalan tol, yang turun apanya dulu?",
          "answer": "Speedometer."
        }
      ],
      "context_set": ""
    }
  ]
}
```

**Tensorflow Engine**

First we take care our imports and global variables.

```python
import json
import nltk
import pickle
import random
import tflearn

import numpy as np
import tensorflow as tf
from Sastrawi.Stemmer.StemmerFactory import StemmerFactory

stemmer = StemmerFactory().create_stemmer()
nltk.download('punkt')
tf.disable_v2_behavior()
tf.disable_eager_execution()
```

Create file `tensor_flow.py` for our tensorflow engine. And first fill like below to create constructor.

```python
class TensorFlow(object):

    def __init__(self, intents):
        self.classes = list()
        self.documents = list()
        self.ERROR_THRESHOLD = 0.25
        self.ignore_words = ["?"]
        self.intents = json.load(open(intents))
        self.output = list
        self.training = list()
        self.train_x = None
        self.train_y = None
        self.words = list()
        for intent in self.intents["intents"]:
            for pattern in intent["patterns"]:
                w = nltk.word_tokenize(pattern)
                self.words.extend(w)
                self.documents.append((w, intent['tag']))
                if intent['tag'] not in self.classes:
                    self.classes.append(intent['tag'])
        self.words = [stemmer.stem(w.lower()) for w in self.words if w not in self.ignore_words]
        self.words = sorted(list(set(self.words)))
        self.classes = sorted(list(set(self.classes)))
        self.train_doc()
        self.model = self.set_model()
```

Add method inside our class to create document training like following below.

```python
def train_doc(self):
    training = list()
    output_empty = [0] * len(self.classes)
    for doc in self.documents:
        bag = list()
        pattern_words = doc[0]
        pattern_words = [stemmer.stem(word.lower()) for word in pattern_words]
        for w in self.words:
            bag.append(1) if w in pattern_words else bag.append(0)
        output_row = list(output_empty)
        output_row[self.classes.index(doc[1])] = 1
        training.append([bag, output_row])
    self.training = training
    random.shuffle(self.training)
    self.training = np.array(self.training)
    self.train_x = list(self.training[:, 0])
    self.train_y = list(self.training[:, 1])
```

Create method inside class to use for set our tflearn models.

```python
def set_model(self):
    tf.reset_default_graph()
    net = tflearn.input_data(shape=[None, len(self.train_x[0])])
    net = tflearn.fully_connected(net, 8)
    net = tflearn.fully_connected(net, 8)
    net = tflearn.fully_connected(net, len(self.train_y[0]), activation="softmax")
    net = tflearn.regression(net)

    model = tflearn.DNN(net, tensorboard_dir="tflearn_logs")
    model.fit(self.train_x, self.train_y, n_epoch=1000, batch_size=8, show_metric=True)
    model.save('./model.tflearn')
    pickle.dump({'words': self.words, 'classes': self.classes, 'train_x': self.train_x, 'train_y': self.train_y},
                open("training_data", "wb"))
    return model
```

Before we can begin processing intents, we need a way to produce a bag-of-words from user input. This is the same technique as we used earlier to create our training documents. Add static method in our class.

```python
 @staticmethod
def clean_up_sentence(sentence):
    sentence_words = nltk.word_tokenize(sentence)
    sentence_words = [stemmer.stem(word.lower()) for word in sentence_words]
    return sentence_words

@staticmethod
def bow(sentence, words, show_details=False):
    sentence_words = TensorFlow.clean_up_sentence(sentence)
    bag = [0] * len(words)
    for s in sentence_words:
        for i, w in enumerate(words):
            if w == s:
                bag[i] = 1
                if show_details:
                    print("found in bag: %s" % w)
    return np.array(bag)
```

Each sentence passed to response() is classified. Our classifier uses model.predict() and is lighting fast. The probabilities returned by the model are lined-up with our intents definitions to produce a list of potential responses. Create method `classify` and `response` to get predicted response.

```python
def classify(self, sentence):
    data = pickle.load(open("training_data", "rb"))
    classes = data['classes']
    words = data['words']
    results = self.model.predict([TensorFlow.bow(sentence, words)])[0]
    results = [[i, r] for i, r in enumerate(results) if r > self.ERROR_THRESHOLD]
    results.sort(key=lambda x: x[1], reverse=True)
    return_list = list()
    for r in results:
        return_list.append((classes[r[0]], r[1]))
    return return_list

def response(self, sentence):
    results = self.classify(sentence)
    if results:
        while results:
            for i in self.intents['intents']:
                if i['tag'] == results[0][0]:
                    return results[0][0], random.choice(i['responses'])
            results.pop(0)
```

If one or more classifications are above a threshold, we see if a tag matches an intent and then process that. We’ll treat our classification list as a stack and pop off the stack looking for a suitable match until we find one, or it’s empty. Finally, our tensorflow engine should be like following below.

```python
import json
import nltk
import pickle
import random
import tflearn

import numpy as np
import tensorflow as tf
from Sastrawi.Stemmer.StemmerFactory import StemmerFactory

stemmer = StemmerFactory().create_stemmer()
nltk.download('punkt')
tf.disable_v2_behavior()
tf.disable_eager_execution()


class TensorFlow(object):

    def __init__(self, intents):
        self.classes = list()
        self.documents = list()
        self.ERROR_THRESHOLD = 0.25
        self.ignore_words = ["?"]
        self.intents = json.load(open(intents))
        self.output = list
        self.training = list()
        self.train_x = None
        self.train_y = None
        self.words = list()
        for intent in self.intents["intents"]:
            for pattern in intent["patterns"]:
                w = nltk.word_tokenize(pattern)
                self.words.extend(w)
                self.documents.append((w, intent['tag']))
                if intent['tag'] not in self.classes:
                    self.classes.append(intent['tag'])
        self.words = [stemmer.stem(w.lower()) for w in self.words if w not in self.ignore_words]
        self.words = sorted(list(set(self.words)))
        self.classes = sorted(list(set(self.classes)))
        self.train_doc()
        self.model = self.set_model()

    def train_doc(self):
        training = list()
        output_empty = [0] * len(self.classes)
        for doc in self.documents:
            bag = list()
            pattern_words = doc[0]
            pattern_words = [stemmer.stem(word.lower()) for word in pattern_words]
            for w in self.words:
                bag.append(1) if w in pattern_words else bag.append(0)
            output_row = list(output_empty)
            output_row[self.classes.index(doc[1])] = 1
            training.append([bag, output_row])
        self.training = training
        random.shuffle(self.training)
        self.training = np.array(self.training)
        self.train_x = list(self.training[:, 0])
        self.train_y = list(self.training[:, 1])

    def set_model(self):
        tf.reset_default_graph()
        net = tflearn.input_data(shape=[None, len(self.train_x[0])])
        net = tflearn.fully_connected(net, 8)
        net = tflearn.fully_connected(net, 8)
        net = tflearn.fully_connected(net, len(self.train_y[0]), activation="softmax")
        net = tflearn.regression(net)

        model = tflearn.DNN(net, tensorboard_dir="tflearn_logs")
        model.fit(self.train_x, self.train_y, n_epoch=1000, batch_size=8, show_metric=True)
        model.save('./model.tflearn')
        pickle.dump({'words': self.words, 'classes': self.classes, 'train_x': self.train_x, 'train_y': self.train_y},
                    open("training_data", "wb"))
        return model

    @staticmethod
    def clean_up_sentence(sentence):
        sentence_words = nltk.word_tokenize(sentence)
        sentence_words = [stemmer.stem(word.lower()) for word in sentence_words]
        return sentence_words

    @staticmethod
    def bow(sentence, words, show_details=False):
        sentence_words = TensorFlow.clean_up_sentence(sentence)
        bag = [0] * len(words)
        for s in sentence_words:
            for i, w in enumerate(words):
                if w == s:
                    bag[i] = 1
                    if show_details:
                        print("found in bag: %s" % w)
        return np.array(bag)

    def classify(self, sentence):
        data = pickle.load(open("training_data", "rb"))
        classes = data['classes']
        words = data['words']
        results = self.model.predict([TensorFlow.bow(sentence, words)])[0]
        results = [[i, r] for i, r in enumerate(results) if r > self.ERROR_THRESHOLD]
        results.sort(key=lambda x: x[1], reverse=True)
        return_list = list()
        for r in results:
            return_list.append((classes[r[0]], r[1]))
        return return_list

    def response(self, sentence):
        results = self.classify(sentence)
        if results:
            while results:
                for i in self.intents['intents']:
                    if i['tag'] == results[0][0]:
                        return results[0][0], random.choice(i['responses'])
                results.pop(0)

```

**Test Our Engine**

Now we can test our engine by typing in command line.

```bash
python

>>> from tensor_flow import TensorFlow
>>> resp = TensorFlow(intents="intents.json")
>>> tag, data = resp.response("halo")
>>> print(data)
```

Or create new file example, `test.py` and fill like below.

```python
from tensor_flow import TensorFlow

resp = TensorFlow(intents="intents.json")
tag, data = resp.response("halo")
print(data)
```

And run our python file in our terminal `python test.py`.

**Build REST Application using Flask**

Now we will create flask application that can be used for another application using chat bot. Create file `main.py` and our project directory should be like following below.

```
* chatbot-python/
  |--- intents.json
  |--- main.py
  |--- tensor_flow.py
```

Fill `main.py` like following code.

```python
from tensor_flow import TensorFlow
from flask import Flask, request, jsonify

resp = TensorFlow(intents="intents.json")
app = Flask(__name__)


@app.route('/', methods=['POST'])
def chat():
    tag, data = resp.response(request.json['message'])
    response_dto = dict()
    response_dto["type"] = tag
    if tag == "riddles":
        response_data = dict()
        response_data["question"] = data["question"]
        response_data["answer"] = data["answer"]
        response_dto["data"] = response_data
    else:
        response_data = dict()
        response_data["message"] = data
        response_dto["data"] = response_data

    response = jsonify(response_dto)
    response.status_code = 200
    return response


if __name__ == '__main__':
    app.run(host='localhost', port=8000, debug=True)
```

Lets try our chat bot using rest api, we will use cURL like this.

```bash
curl --location --request POST 'http://localhost:8000/' \
--header 'Content-Type: application/json' \
--data-raw '{
    "message": "terimakasih"
}'
```

And we will gen an output like this.

```json
{
    "data": {
        "message": "Hubungi saya kalau anda ingin mencari referensi lagi"
    },
    "type": "thanks"
}
```

### References

[Contextual Chatbots with Tensorflow](https://chatbotsmagazine.com/contextual-chat-bots-with-tensorflow-4391749d0077)

[What Are Contextual Chatbots? How They Can Make A World Of Difference In User Experience?](https://medium.com/makerobos/what-are-contextual-chatbots-how-they-can-make-a-world-of-difference-in-user-experience-e7446c96664e)
