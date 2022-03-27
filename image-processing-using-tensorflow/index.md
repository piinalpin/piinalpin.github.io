# Image Processing Using Tensorflow - Convolutional Neural Network (CNN)


<!--more-->

### Overview

Digital image processing is the use of a digital computer to process digital images through an algorithm. As a subcategory or field of digital signal processing, digital image processing has many advantages over analog image processing.

![Image Processing Flow](/images/malaria-1.png)

Machine learning is a complex discipline. But implementing machine learning models is far less daunting and difficult than it used to be, thanks to machine learning frameworks—such as Google’s TensorFlow—that ease the process of acquiring data, training models, serving predictions, and refining future results.

Created by the Google Brain team, TensorFlow is an open source library for numerical computation and large-scale machine learning. TensorFlow bundles together a slew of machine learning and deep learning (aka neural networking) models and algorithms and makes them useful by way of a common metaphor. It uses Python to provide a convenient front-end API for building applications with the framework, while executing those applications in high-performance C++.

### Study Case

In this case, we will detect the image whether the image is an indication of malaria infection or not. We will use dataset which can be download [here](https://github.com/piinalpin/research-collection/tree/master/tensorflow/malaria-detection/dataset).

**Directory Structure**

```
.
├── ...
├── dataset
│   └── parasitized/
│   ├── uninfected/
├── test-data/
│   └── ...
└── research.ipynb
└── ...
```

**Import Dependency and Count Dataset**

We will use `tensorflow.keras` library like following code.

```python
from tensorflow import keras
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Conv2D, Activation, MaxPooling2D, Dropout, Flatten, Dense
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import load_model
from PIL import Image
from skimage import transform

import os
import numpy as np
import glob
```

Count our dataset in this case.

```python
parasitized = glob.glob('dataset/parasitized/*.png')
uninfected = glob.glob('dataset/uninfected/*.png')

print("Parasitized data: {}\nUninfected data: {}".format(len(parasitized), len(uninfected)))
```

**Preprocessing**

Data augmentation, based on wikipedia data augmentation is techniques are used to increase the amount of data by adding slightly modified copies of already existing data or newly created synthetic data from existing data.

```python
dimension = 128
batch = 32
data_dir = "dataset"

datagen = ImageDataGenerator(rescale=1/255.0, 
                             validation_split=0.2,
                             zoom_range=0.05,
                             width_shift_range=0.05,
                             height_shift_range=0.05,
                             shear_range=0.05,
                             horizontal_flip=True)

train_data = datagen.flow_from_directory(data_dir, 
                                         target_size=(dimension, dimension), 
                                         batch_size=batch, 
                                         class_mode='categorical', 
                                         subset='training')

validation_data = datagen.flow_from_directory(data_dir,
                                              target_size=(dimension, dimension),
                                              batch_size=batch,
                                              class_mode='categorical',
                                              subset='validation',
                                              shuffle=False)

test_data = datagen.flow_from_directory(data_dir,
                                        target_size=(dimension, dimension),
                                        batch_size=1,
                                        shuffle=False)
```

**Training Data and Modelling**

The process of training an ML model involves providing an ML algorithm (that is, the learning algorithm) with training data to learn from. The term ML model refers to the model artifact that is created by the training process.

```python
model = Sequential()
model.add(Conv2D(filters=16, kernel_size=3, padding="same", activation="relu", input_shape=(dimension, dimension, 3)))
model.add(MaxPooling2D(pool_size=2))

model.add(Conv2D(filters=32, kernel_size=3, padding="same", activation="relu"))
model.add(MaxPooling2D(pool_size=2))

model.add(Conv2D(filters=64, kernel_size=3, padding="same", activation="relu"))
model.add(MaxPooling2D(pool_size=2))

model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(64, activation="relu"))
model.add(Dropout(0.2))
model.add(Dense(2, activation="softmax"))

# Compile the model
model.compile(optimizer="adam", 
              loss="binary_crossentropy", 
              metrics=["accuracy"])

# Save the best trained model by monitoring validation loss
model_name = "train_data_model.b"
model_checkpoint = ModelCheckpoint(model_name, 
                                   save_weights_only=False, 
                                   monitor='val_loss', 
                                   verbose=1, 
                                   mode='auto', 
                                   save_best_only=True)

# Training dataset
history = model.fit(train_data, 
                    batch_size=batch, 
                    epochs=30, 
                    validation_data=validation_data,
                    callbacks = [model_checkpoint],
                    verbose=1)
```

**Model Evaluation**

Evaluation is a process during development of the model to check whether the model is best fit for the given problem and corresponding data. Keras model provides a function, evaluate which does the evaluation of the model. It has three main arguments :
- Test data
- Test data label
- verbose - true or false

Let us evaluate the model, which we created in the previous chapter using test data.

```python
# Load compiled model
model = load_model("train_data_model.b")
model.evaluate(test_data, verbose=0)
```

**Prediction**

Prediction is fitting a shape that gets as close to the data as possible. The object we’re fitting is more of a skeleton that goes through one body of data instead of a fence that goes between separate bodies of data.

```python
# Load image from filename
def load(filename):
   np_image = Image.open(filename)
   np_image = np.array(np_image).astype('int32')/255
   np_image = transform.resize(np_image, (128, 128, 3))
   np_image = np.expand_dims(np_image, axis=0)
   return np_image

def prediction(image):
  np_image = load(image)
  prediction = model.predict(np_image) # Predict input image
  result = [1 * (x[0]>=0.5) for x in prediction] # Normalize prediction
  if result[0] == 0:
    return False
  return True

## Test with random data
test1 = prediction("test-data/parasitized1.png")
test2 = prediction("test-data/parasitized2.png")
test3 = prediction("test-data/parasitized3.png")
test4 = prediction("test-data/parasitized4.png")
test5 = prediction("test-data/uninfected1.png")
test6 = prediction("test-data/uninfected2.png")
test7 = prediction("test-data/uninfected3.png")
test8 = prediction("test-data/uninfected4.png")

print("Result for infected or uninfected of malaria")
print("Test 1: ", test1)
print("Test 2: ", test2)
print("Test 3: ", test3)
print("Test 4: ", test4)
print("Test 5: ", test5)
print("Test 6: ", test6)
print("Test 7: ", test7)
print("Test 8: ", test8)
```

## Source

You can clone or download the source in

```bash
https://github.com/piinalpin/research-collection/tree/master/tensorflow/malaria-detection
```

### Reference

- [Digital Image Processing - Wikipedia](https://en.wikipedia.org/wiki/Digital_image_processing)
- [Tensorflow Sequential](https://www.tensorflow.org/api_docs/python/tf/keras/Sequential)
- [Classification, regression, and prediction — what’s the difference?](https://towardsdatascience.com/classification-regression-and-prediction-whats-the-difference-5423d9efe4ec)
- [Model Evaluation and Model Prediction](https://www.tutorialspoint.com/keras/keras_model_evaluation_and_prediction.htm)
- [Training ML Models](https://docs.aws.amazon.com/machine-learning/latest/dg/training-ml-models.html)
- [What is Data Augmentation? Techniques, Benefit & Examples](https://research.aimultiple.com/data-augmentation/)
