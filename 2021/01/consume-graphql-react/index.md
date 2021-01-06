# GraphQL Client using React


<!--more-->
### Prerequisites
* [GraphQL](https://www.npmjs.com/package/graphql)
* [Apollo Client](https://www.npmjs.com/package/apollo-client-preset-fork)
* [React Apollo](https://www.npmjs.com/package/react-apollo)
* [GraphQL Tag](https://www.npmjs.com/package/graphql-tag)
* [Semantic UI React](npmjs.com/package/semantic-ui-react)
* [Sematic UI CSS](https://www.npmjs.com/package/semantic-ui-css)

### Step to build GraphQL client using React

**Note:** This documentation will use GraphQL server from [GraphQL Server with Spring Boot](https://github.com/piinalpin/graphql-spring-boot)

**Installing React**

```bash
npx create-react-app react-graphql-example
```

or if using yarn

```bash
create-react-app react-graphql-example
```

**Installing Package**

Install some package that we need, especially those related to GraphQL and we will use Apollo, a GraphQL wrapper that makes it easy to interact with GraphQL. And for user interface we will use Semantic UI.

```bash
npm install --save graphql apollo-client-preset react-apollo graphql-tag semantic-ui-react semantic-ui-css
```

or

```bash
yarn add graphql apollo-client-preset react-apollo graphql-tag semantic-ui-react semantic-ui-css
```

**Connect with GraphQL**

Lets connect GraphQL server using ApolloClient that we add into `src/index.js`

```js
import React from 'react';
import ReactDOM from 'react-dom';
import { ApolloClient } from 'apollo-client';
import { HttpLink } from 'apollo-link-http';
import { InMemoryCache } from 'apollo-cache-inmemory';
import { ApolloProvider } from 'react-apollo';

import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';

const client = new ApolloClient({
	link: new HttpLink({
		uri: 'http://localhost:8080/graphql'
	}),
	cache: new InMemoryCache()
});

ReactDOM.render(
  <ApolloProvider client={client}>
    <App />
  </ApolloProvider>,
  document.getElementById("root")
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
```

**Query to GraphQL Server**

Do query to GraphQL server from React component and makesure we have response from backend. So we first use `console.log` in `src/App.js`.

```js
import React, { Component } from 'react';
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';
import { Container, Feed, Card } from 'semantic-ui-react';
import 'semantic-ui-css/semantic.min.css'
import './App.css';

class App extends Component {
  render() {
    console.log(this.props.data);
    return (
        <Container text textAlign="center">
          <Card centered fluid>
            <Card.Content>
              <Card.Header>Person Data</Card.Header>
            </Card.Content>
            <Card.Content>
              {this.props.data.getAllPerson && (
                <Feed>
                  {this.props.data.getAllPerson.map(person => (
                      <Feed.Event key={person.id}>
                        <Feed.Content>
                          <Feed.Label content={person.firstName} />
                          <Feed.Date content={person.createdAt} />
                          <Feed.Summary>{person.address}</Feed.Summary>
                        </Feed.Content>
                      </Feed.Event>
                    ))}
                  </Feed>
                )
              }
            </Card.Content>
          </Card>
          <Card centered fluid>
            <Card.Content>
              <Card.Header>Book Data</Card.Header>
            </Card.Content>
            <Card.Content>
              {/* Iterate data here later */}
            </Card.Content>
          </Card>
        </Container>
    );
  }
}

const queries = gql`
  query {
    getAllPerson {
      id
      firstName
      lastName
      address
      createdAt
    }
    getAllBook {
        id
        title
        releaseDate
        description
        author {
            id
            firstName
            address
            createdAt
        }
        createdAt
    }
  }
`;

export default graphql(queries, {
  options: {
    variables: {

    }
  }
})(App);
```

**Read Data from GraphQL Server**

After we got data from backend, then we will render it into React component `src/App.js`.

```js
import React, { Component } from 'react';
import { graphql } from 'react-apollo';
import gql from 'graphql-tag';
import { Container, Feed, Card } from 'semantic-ui-react';
import 'semantic-ui-css/semantic.min.css'
import './App.css';

class App extends Component {
  render() {
    console.log(this.props.data);
    return (
        <Container text textAlign="center">
          <Card centered fluid>
            <Card.Content>
              <Card.Header>Person Data</Card.Header>
            </Card.Content>
            <Card.Content>
              {this.props.data.getAllPerson && (
                <Feed>
                  {this.props.data.getAllPerson.map(person => (
                      <Feed.Event key={person.id}>
                        <Feed.Content>
                          <Feed.Label content={person.firstName} />
                          <Feed.Date content={person.createdAt} />
                          <Feed.Summary>{person.address}</Feed.Summary>
                        </Feed.Content>
                      </Feed.Event>
                    ))}
                  </Feed>
                )
              }
            </Card.Content>
          </Card>
          <Card centered fluid>
            <Card.Content>
              <Card.Header>Book Data</Card.Header>
            </Card.Content>
            <Card.Content>
              {this.props.data.getAllPerson && (
                <Feed>
                  {this.props.data.getAllBook.map(book => (
                      <Feed.Event key={book.id}>
                        <Feed.Content>
                          <Feed.Label>{book.title} - {book.author.firstName}</Feed.Label>
                          <Feed.Date content={book.releaseDate} />
                          <Feed.Summary>{book.description}</Feed.Summary>
                        </Feed.Content>
                      </Feed.Event>
                    ))}
                  </Feed>
                )
              }
            </Card.Content>
          </Card>
        </Container>
    );
  }
}

const queries = gql`
  query {
    getAllPerson {
      id
      firstName
      lastName
      address
      createdAt
    }
    getAllBook {
        id
        title
        releaseDate
        description
        author {
            id
            firstName
            address
            createdAt
        }
        createdAt
    }
  }
`;

export default graphql(queries, {
  options: {
    variables: {

    }
  }
})(App);
```

![GraphQL Modelling](/images/react-graphql-example-1.png)

### Thankyou

[Medium](https://medium.com/@rizafahmi22/graphql-client-dengan-react-8849c6f4857e) - GraphQL Client Dengan React