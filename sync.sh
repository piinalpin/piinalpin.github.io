#/bin/bash
echo "APP_ID: $ALGOLIA_APPLICATION_ID"
curl -X POST -H "X-Algolia-API-Key: $ALGOLIA_API_KEY" -H "X-Algolia-Application-Id: $ALGOLIA_APPLICATION_ID" "https://$ALGOLIA_APPLICATION_ID.algolia.net/1/indexes/test-index/clear"