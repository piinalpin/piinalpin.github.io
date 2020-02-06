# Get Twitter Trending with World of Earth Identity (WOEID) Test


<!--more-->

### Prerequisites

Make sure you have installed [Python 3](https://www.python.org/downloads/) or [Anaconda](https://www.anaconda.com/) on your device.

### Step to create TwitterAPI Consumer

1. Install [Tweepy](https://www.tweepy.org/)
```
pip install tweepy
```
2. Create an App on [Twitter Developer](https://developer.twitter.com/) to get API Key, then find `apiKey`, `apiSecretKey`, `accessToken`, and `accessTokenSecret` on tabs `Keys and tokens`
3. Create custom library `TwitterTrendingsAPI.py`
```python
import json
import tweepy


class TwitterTrendingsAPI:
    
    """
        How to use?
        
        Change apiKey, apiSecretKey, accessToken, accessTokenSecret with your own Twitter Apps from https://developer.twitter.com
        
        Use this class
        
        api = TwitterAPI(woeId=23424846, limit=10)
        api.getTrending()
    """

    def __init__(self, woeId, limit):
        self.apiKey = "<YOUR_API_KEY>"
        self.apiSecretKey = "<YOUR_API_SECRET_KEY>"
        self.accessToken = "<YOUR_ACCESS_TOKEN>"
        self.accessTokenSecret = "<YOUR_ACCESS_TOKEN_SECRET>"
        self.woeId = woeId
        self.limit = limit

    def getApiAuth(self):
        auth = tweepy.OAuthHandler(self.apiKey, self.apiSecretKey)
        auth.set_access_token(self.accessToken, self.accessTokenSecret)
        return tweepy.API(auth)

    def getTrending(self):
        trends = self.getApiAuth().trends_place(self.woeId)
        trending = json.loads(json.dumps(trends, indent=1))
        return trending[0]["trends"][:self.limit]

```
4. Create python file or jupyter notebook file to call these custom library which is already created
```python
# Import custom twitter trendings API
from TwitterTrendingsAPI import TwitterTrendingsAPI

# Define WOEID
"""
More World of Earth Id : https://codebeautify.org/jsonviewer/f83352
Find WOEID by your self

"""

INDONESIA_WOE_ID = 23424846
UNITED_KINGDOM_WOE_ID = 23424975

# Define TwitterTrendingsAPI Object with Limit 10 Trendings
api = TwitterTrendingsAPI(woeId=INDONESIA_WOE_ID, limit=10)

# Get Trendings
trendings = api.getTrending()
print(trendings)

# Filter Trendings By Hashtag
trends = list()
for trend in trendings:
    getTrendName = trend["name"].strip("#")
    trends.append(getTrendName)
print(trends)
```
### Conclusion
This tutorial can be use for data mining or machine learning, what is trending topic now?