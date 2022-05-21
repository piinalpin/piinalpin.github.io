# Salary Prediction with ML - Linear Regression


![Machine Learning](/images/machine-learning.jpg)

Machine learning is a branch of artificial intelligence (AI) and computer science which focuses on the use of data and algorithms to imitate the way that humans learn, gradually improving its accuracy.

### How Does Machine Learning Works?

Similar to how the human brain gains knowledge and understanding, machine learning relies on input, such as training data or knowledge graphs, to understand entities, domains and the connections between them. With entities defined, deep learning can begin.

**Data is The Key** : The algorithms that drive machine learning are critical to success. ML algorithms build a mathematical model based on sample data, known as “training data,” to make predictions or decisions without being explicitly programmed to do so. This can reveal trends within data that information businesses can use to improve decision making, optimize efficiency and capture actionable data at scale.

**AI is the Goal**: Machine Learning provides the foundation for AI systems that automate processes and solve data-based business problems autonomously. It enables companies to replace or augment certain human capabilities. Common machine learning applications you may find in the real world include chatbots, self-driving cars and speech recognition.

### Machine Learning Method

Machine learning classifiers fall into three primary categories, such as:

* **Supervised learning**, also known as supervised machine learning, is defined by its use of labeled datasets to train algorithms that to classify data or predict outcomes accurately. As input data is fed into the model, it adjusts its weights until the model has been fitted appropriately. This occurs as part of the cross validation process to ensure that the model avoids overfitting or underfitting. Supervised learning helps organizations solve for a variety of real-world problems at scale, such as classifying spam in a separate folder from your inbox. Some methods used in supervised learning include ***neural networks***, ***naïve bayes***, ***linear regression***, ***logistic regression***, ***random forest***, ***support vector machine (SVM)***, and more.

* **Unsupervised learning**, also known as unsupervised machine learning, uses machine learning algorithms to analyze and cluster unlabeled datasets. These algorithms discover hidden patterns or data groupings without the need for human intervention. Its ability to discover similarities and differences in information make it the ideal solution for exploratory data analysis, cross-selling strategies, customer segmentation, image and pattern recognition. It’s also used to reduce the number of features in a model through the process of dimensionality reduction; principal component analysis (PCA) and singular value decomposition (SVD) are two common approaches for this. Other algorithms used in unsupervised learning include neural networks, k-means clustering, probabilistic clustering methods, and more.

* **Semi-supervised learning** offers a happy medium between supervised and unsupervised learning. During training, it uses a smaller labeled data set to guide classification and feature extraction from a larger, unlabeled data set. Semi-supervised learning can solve the problem of having not enough labeled data (or not being able to afford to label enough data) to train a supervised learning algorithm. 

### Linear Regression

Linear regression is a basic and commonly used type of predictive analysis.  The overall idea of regression is to examine two things: (1) does a set of predictor variables do a good job in predicting an outcome (dependent) variable?  (2) Which variables in particular are significant predictors of the outcome variable, and in what way do they–indicated by the magnitude and sign of the beta estimates–impact the outcome variable?  These regression estimates are used to explain the relationship between one dependent variable and one or more independent variables.

The simplest form of the regression equation with one dependent and one independent variable is defined by the formula :

![y = bx + c](/images/linear-regression-equation.png)

Where:
* *y* : estimated dependent variable score
* *c* : constant
* *b* : regression coefficient
* *x* : score on the independent variable

There are many names for a regression’s dependent variable.  It may be called an outcome variable, criterion variable, endogenous variable, or regressand.  The independent variables can be called exogenous variables, predictor variables, or regressors.

Three major uses for regression analysis are (1) determining the strength of predictors, (2) forecasting an effect, and (3) trend forecasting.

### Salary Prediction Model

First of all, we should provides the dataset. Dataset can be a excel file, csv file or etc. You can use my example dataset [here](https://docs.google.com/spreadsheets/d/1FIGP3-OGfv8KR9nKObKbzPUk2N6Q7ruZxz4zSsWpd5o/edit?usp=sharing).

Import `pandas` library for building the data frames.

```python
import pandas as pd
```
 
 Then load the dataset, like below

 ```python
dataset = pd.read_excel('salary_dataset.xlsx')
dataset
 ```

|  | knowledge | technical | logical | year_experience | salary |
|---:|---:|---:|---:|---:|---:|
| 0 | 50 | 60 | 50 | 0 | Rp 2,500,000.00 |
| 1 | 60 | 50 | 50 | 0 | Rp 2,500,000.00 |
| 2 | 50 | 70 | 70 | 0 | Rp 3,000,000.00 |
| 3 | 40 | 50 | 60 | 0 | Rp 2,800,000.00 |
| 4 | 70 | 70 | 70 | 1.1 | Rp 4,000,000.00 |
| 5 | 75 | 70 | 65 | 1.2 | Rp 4,000,000.00 |
| 6 | 65 | 65 | 60 | 1.1 | Rp 3,800,000.00 |
| 7 | 70 | 70 | 70 | 1.5 | Rp 4,500,000.00 |
| 8 | 65 | NaN | 70 | 1 | Rp 3,400,000.00 |
| 9 | 70 | 80 | 80 | 2 | Rp 6,000,000.00 |
| 10 | 75 | 75 | 85 | 1.8 | Rp 6,000,000.00 |
| 11 | 80 | 80 | 80 | 2 | Rp 7,000,000.00 |
| 12 | 80 | 80 | 80 | 2.2 | Rp 7,500,000.00 |
| 13 | 75 | 70 | 80 | 2.9 | Rp 7,800,000.00 |
| 14 | 80 | 85 | 80 | 3 | Rp 8,400,000.00 |
| 15 | 75 | 80 | 75 | 2.4 | Rp 7,500,000.00 |
| 16 | 85 | 80 | 90 | 3.2 | Rp 8,200,000.00 |
| 17 | 85 | 80 | 85 | 3.2 | Rp 8,000,000.00 |
| 18 | 85 | 90 | 90 | 2.7 | Rp 8,000,000.00 |
| 19 | 90 | 90 | 90 | 3.7 | Rp 10,000,000.00 |
| 20 | NaN | NaN | NaN | 3 | Rp 8,000,000.00 |

#### Cleaning Dataset

Clean null or `NaN` values from data frame using `dropna()`.

```python
dataset = dataset.dropna()
dataset.head()
```

|  | knowledge | technical | logical | year_experience | salary |
|---:|---:|---:|---:|---:|---:|
| 0 | 50 | 60 | 50 | 0.0 | Rp 2,500,000.00 |
| 1 | 60 | 50 | 50 | 0.0 | Rp 2,500,000.00 |
| 2 | 50 | 70 | 70 | 0.0 | Rp 3,000,000.00 |
| 3 | 40 | 50 | 60 | 0.0 | Rp 2,800,000.00 |
| 4 | 70 | 70 | 70 | 1.1 | Rp 4,000,000.00 |

#### Building Model

Import `train_test_split` from scikit learn to split arrays or matrices into random train and test subsets. Quick utility that wraps input validation and `next(ShuffleSplit().split(X, y))` and application to input data into a single call for splitting (and optionally subsampling) data in a oneliner.

```python
from sklearn.model_selection import train_test_split

x = dataset.drop('salary', axis=1)
y = dataset['salary']

x.head()
```

|  | knowledge | technical | logical | year_experience |
|---:|---:|---:|---:|---:|
| 0 | 50 | 60 | 50 | 0.0 |
| 1 | 60 | 50 | 50 | 0.0 |
| 2 | 50 | 70 | 70 | 0.0 |
| 3 | 40 | 50 | 60 | 0.0 |
| 4 | 70 | 70 | 70 | 1.1 |

```python
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=42)
```

#### Prediction

Import `LinearRegression` from scikit learn and use the linear regression function. And create object from `LinearRegression`.

```python
from sklearn.linear_model import LinearRegression

linear = LinearRegression()
linear.fit(x_train, y_train)
```

Predict test data `x_test` with call function `predict()` and store to variable `y_pred`. The result is prediction salary with test data using `LinearRegression`.

```python
y_pred = linear.predict(x_test)
y_pred
```
`array([2122535.96880463, 3980638.07697809, 6537626.01871658, 1078550.87649938])`

#### Accuracy

`Machine learning` model accuracy is the measurement used to determine which `model` is best at identifying relationships and patterns between variables in a dataset based on the input, or `training` data. The better a model can generalize to ‘unseen’ data, the better `predictions` and `insights` it can produce, which in turn deliver more business value.

```python
linear.score(x_test, y_test)
```

`0.8148593096952005`

Our linear regression model accuracy score is **81.4%**

#### Implementation

Implementation a `Linear Regression` with some input from user that have value of `knowledge`, `techincal`, `logical` and `year of experience`. Assumes, you are fresh graduate with have a knowledge score is 50, technical score is 50 and logical score is 60. In this case we will use a `dictionary` data and convert it into `DataFrame` like below. 

```python
data_dict = {
    'knowledge': 50,
    'technical': 50,
    'logical': 60,
    'year_experience': 0
}

input_data = pd.DataFrame([data_dict])
input_data
```

|  | knowledge | technical | logical | year_experience |
|---:|---:|---:|---:|---:|
| 0 | 50 | 50 | 60 | 0.0 |

And predict using `LinearRegression` function like below.

```python
predicted_salary = linear.predict(input_data)[0]
# Convert decimal to integer
predicted_salary = int(predicted_salary)
print("IDR {:,.2f}".format(predicted_salary))
```
`IDR 1,864,514.00`

The result of the prediction of the case is **IDR 1,864,514.00**.

### Conclusion

Simple `Linear Regression` help us to predict a dependent variable for salary prediction model. It can estimated of a response variable for people with values of the carier variable within the knowledges. You can download my jupyter notebook [Predict Salary - Linear Regression.ipynb](https://colab.research.google.com/drive/1JQs-x4YcAvF3hkzv6pKbMdLZXc4ItJrG?usp=sharing).

### Reference

* [Machine Learning](https://www.ibm.com/cloud/learn/machine-learning)
* [What Is Machine Learning? A Definition.](https://www.expert.ai/blog/machine-learning-definition/)
* [What is Linear Regression?](https://www.statisticssolutions.com/free-resources/directory-of-statistical-analyses/what-is-linear-regression/)
