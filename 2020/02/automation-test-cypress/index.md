# Automation Test Using Cypress Example


### Prerequisites

Install Cypress using NPM :
```bash
cd /your/project/path
npm install cypress --save-dev
```
or using Yarn :
```bash
cd /your/project/path
yarn add cypress --dev
```

### Step to create test case

1. Open cypress to get examples of test case from cypress module

using npx :
```bash
npx cypress open
```
using yarn
```bash
yarn run cypress open
```
Cypress should be like image below
![Default Cypress](https://raw.githubusercontent.com/piinalpin/cypress-example/master/screenshot/default-cypress.png)

2. Create test case data, in this case I will use my simple CRUP web app which is deployed on heroku `https://github.com/piinalpin/FE-flask-rest-api.git`. Create new file `student-data.json` at `/my-project/cypress/integration/my-app`. This file will be use for add new record and update record in the application.
```json
{
	"student": {
		"name": "Kirito",
		"identityNumber": "2483483"
	},
	"editStudent": {
		"name": "Kirigaya Kazuto",
		"identityNumber": "8374323"
	}
}
```

3. Create test case `student.spec.js` inside `/my-project/cypress/integration/myapp` extension should be `.spec.js` because legible automatically on cypress as test case. Lets start with get list student.
```javascript
describe('Student CRUD Test', function() {

	// Define variable of new record and update record
	let student = {}
	let editStudent = {}

	// Before each will be run automatically when run a test case
	beforeEach(function() {
		// Visit website with follow url
		cy.visit('https://fe-flask-rest-api-maverick.herokuapp.com/')

		// Read sudent-data.json which is use for add record
		cy.readFile('cypress/integration/fe-flask-rest-api/student-data.json').its('student').then(value => {
            student = {
            	name: value.name,
            	identityNumber: value.identityNumber
            }
        })

		// Read sudent-data.json which is use for update record
		cy.readFile('cypress/integration/fe-flask-rest-api/student-data.json').its('editStudent').then(value => {
            editStudent = {
            	name: value.name,
            	identityNumber: value.identityNumber
            }
        })
	})

	// Create function get list student case
	it('Get List Student', function() {
		// Find class nav-link on htmnl where text contains List Student then click it
		cy.get('.nav-link').contains('List Student').click()

		// Assertion url should be equals
		cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')

		// Assertion table of list student has table>thead>tr
		cy.get('table>thead').should('have', 'tr')
	})

})
```

4. You can see on Cypress application then click `Run all spec`.
5. Create case for Add Student below get list student function. Then see this run spec. You can remove all data from my web app before run spec at [FE Flask Rest API](https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa)
```javascript
it('Add New Student', function() {
	cy.get('.nav-link').contains('Add Student').click()
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa/add')
	cy.get('input[id="name"]').type(student.name).should('have.value', student.name)
	cy.get('input[id="nim"]').type(student.identityNumber).should('have.value', student.identityNumber)
	cy.get('button').contains('Submit').click()
	cy.get('button').contains('Yes, save it!').click()
	cy.get('button').contains('OK').click()
	cy.wait(2000)
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')
	cy.get('table>tbody>tr').eq(0).should('contain', student.name)
})
```

6. Create update test case, before you run this spec please remove all data from web application. Because cypress run all spec of `student.spec.js` automatically.
```javascript
it('Edit Student', function() {
	cy.get('.nav-link').contains('List Student').click()
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')
	cy.get('button.btn.btn-warning.btn-secondary').children('i').should('have.class', 'fa-pencil').click()
	cy.get('input[id="name"]').clear().type(editStudent.name).clear().type(editStudent.name).should('have.value', editStudent.name)
	cy.get('input[id="nim"]').clear().type(editStudent.identityNumber).clear().type(editStudent.identityNumber).should('have.value', editStudent.identityNumber)
	cy.get('button').contains('Submit').click()
	cy.get('button').contains('Yes, save it!').click()
	cy.get('button').contains('OK').click()
	cy.wait(2000)
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')
	cy.get('table>tbody>tr').eq(0).should('contain', editStudent.name)
})
```

7. Create delete test case, like step 6th please remove all data manually.
```javascript
it('Delete Student', function() {
	cy.get('.nav-link').contains('List Student').click()
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')
	cy.get('button.btn.btn-danger.btn-secondary').children('i').should('have.class', 'fa-trash').click()
	cy.get('button').contains('Yes, save it!').click()
	cy.get('button').contains('OK').click()
	cy.wait(2000)
	cy.url().should('eq', 'https://fe-flask-rest-api-maverick.herokuapp.com/#/mahasiswa')
	cy.get('table>thead').should('have', 'tr')
})
```

8. Result all spec should be like image below.
![Student Test Result](https://raw.githubusercontent.com/piinalpin/cypress-example/master/screenshot/student-test.png)

9. Finally you can see `student.spec.js` run from get list, add data, update data and then delete data. So there is no duplicate data. Thankyou for reading my documentation.

### Thankyou
[Cypress](https://docs.cypress.io/guides/getting-started/installing-cypress.html#Advanced) - The official site of Cypress and Documentation

### Clone or Download
You can clone or download then run all test case
```bash
git clone https://github.com/piinalpin/cypress-example.git
cd cypress-example
npm i
npx cypress open
```