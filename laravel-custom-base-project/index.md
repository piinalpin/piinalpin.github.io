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
2. Change`.env.docker` file to change database configuration to your database configuration and add basic auth configuration. Then copy `.env.docker` to `.env`
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

### Run Using Docker
1. Install Docker desktop from [Docker Hub](https://hub.docker.com/search?q=&type=edition&offering=community&sort=updated_at&order=desc)
2. Install MySQL Docker if you want to use MySQL as container
```bash
docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:latest
```
3. Create database and add user for laravel docker, default IP Address for docker is *172.17.0.1*
```bash
shell> docker exec -it mysql mysql -u root -p

mysql> CREATE DATABASE database_name;
mysql> CREATE USER 'newuser'@'172.17.0.1' IDENTIFIED BY 'user_password';
mysql> GRANT ALL PRIVILEGES ON database_name.* TO 'newuser'@'172.17.0.1';
mysql> FLUSH PRIVILEGES;
```

4. Change `.env.docker` to change database connection for mysql docker
```
DB_CONNECTION=mysql
DB_HOST=172.17.0.1
DB_PORT=3306
DB_DATABASE=database_name
DB_USERNAME=new_user
DB_PASSWORD=user_password
```

5. Run migration and seed data `php artisan migrate && php artisan db:seed`
6. Build web server on docker, you can see Dockerfile for web server at [web.dockerfile](https://github.com/piinalpin/laravel-base/blob/master/web.dockerfile)
```bash
docker build -t laravel_web:latest -f web.dockerfile .
```

7. Build laravel application on docker, you can see Dockerfile for laravel application at [app.dockerfile](https://github.com/piinalpin/laravel-base/blob/master/app.dockerfile)
```bash
docker build -t laravel_app:latest -f app.dockerfile .
```
8. Create network on docker and create connection for mysql docker on your network.
```bash
docker network create my-network
docker network connect my-network mysql
```

9. Adjust `docker-compose.yml` to run web server, application and connect to external mysql container.
```yml
version: '3'

services:
  web:
    image: laravel_web:latest
    volumes:
      - ./:/var/www
    restart: always
    ports:
      - "8080:80"
      - "443:443"
    links:
      - app
    networks:
      - my-network

  app:
    image: laravel_app:latest
    env_file: '.env.docker'
    environment:
      - "DB_HOST=172.17.0.1"
      - "APP_URL=http://localhost:8080/api/v1"
    volumes:
      - ./:/var/www
    restart: always
    networks:
      - my-network

networks:
  my-network:
    external: true
```

10. Run `docker-compose up -d` to deploy docker image to container and `docker-compose down` to stop it.
11. Application should be can access at `localhost:8080`

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

