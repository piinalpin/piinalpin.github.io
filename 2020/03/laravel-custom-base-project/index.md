# Laravel Custom Base Project


### Features

- Basic Authentication
- Json Web Token
- Custom Error Handling
- CORS Filter
- Authority Access
- Custom Middleware
- Soft Deletes Service
- Custom Form Validation
- Auto Refresh Token Every 1 Hour (Ajax)
- User Management

### Documentation
1. Clone this project `https://github.com/piinalpin/laravel-base.git`.
2. Change `.env` file to change database configuration to your database configuration and add basic auth configuration.
```
AUTH_USERNAME=<BASIC_AUTH_USERNAME>
AUTH_PASSWORD=<BASIC_AUTH_PASSWORD>

DB_CONNECTION=mysql
DB_HOST=<DATABASE_HOST>
DB_PORT=<DATABASE_PORT>
DB_DATABASE=<DATABASE_NAME>
DB_USERNAME=<DATABASE_USERNAME>
DB_PASSWORD=<DATABASE_PASSWORD>
```
3. Run `php artisan migrate` to migrate table on database.
4. Change `database/AppUserSeeder.php` according what do you want (optional), for this case I have two default user.
```php
DB::table('APP_USER')->insert([ 
	'created_at' => DB::raw('CURRENT_TIMESTAMP'),
	'created_by' => 0,
	'username' => 'admin',
    'full_name' => 'Administrator',
    'email' => 'admin@test.com',
    'password' => Hash::make('password'),
    'enabled' => true,
    'role' => 'ADMINISTRATOR'
]);
```
5. Run `php artisan db:seed` to seed data in database.
6. Run `php artisan serve` to run this project.

### API Documentation
- Login `/api/v1/oauth/token POST`
	- Header `Authorization: Basic` username and password as same as value of basic auth on `.env`
	- Form Data `username: admin` and `password: password`
- User Currently Logged In `/api/vi/user/me GET`
	- Header `Authorization: Bearer Token`
- Get All User `/api/vi/user GET`
	- Header `Authorization: Bearer Token`
- Create New User `/api/vi/user/me POST`
	- Header `Authorization: Bearer Token`
	- Request: `application/json`
	```json
	{
		"username": "someuser",
		"email": "someemail@test.com",
		"fullName": "Some Name",
		"password": "somepassword",
		"confirmPassword": "somepassword",
		"enabled": true,
		"role": "SOME_ROLE"
	}
	```
- Get Single User `/api/vi/user/{id} GET`
	- Header `Authorization: Bearer Token`
- Update User `/api/vi/user/{id} POST`
	- Header `Authorization: Bearer Token`
	- Request: `application/json`
	```json
	{
		"username": "someuser",
		"email": "someemail@test.com",
		"fullName": "Some Name",
		"password": "somepassword",
		"confirmPassword": "somepassword",
		"enabled": true,
		"role": "SOME_ROLE"
	}
	```
- Delete User `/api/vi/user/{id} DELETE`
	- Header `Authorization: Bearer Token`

### License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
