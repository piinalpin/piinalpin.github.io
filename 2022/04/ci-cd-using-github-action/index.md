# CI/CD Using Github Action


![Devops](/images/devops.png)

Continuous integration is a coding philosophy and set of practices that drive development teams to frequently implement small code changes and check them in to a version control repository. Most modern applications require developing code using a variety of platforms and tools, so teams need a consistent mechanism to integrate and validate changes. Continuous integration establishes an automated way to build, package, and test their applications. Having a consistent integration process encourages developers to commit code changes more frequently, which leads to better collaboration and code quality.

Continuous delivery picks up where continuous integration ends, and automates application delivery to selected environments, including production, development, and testing environments. Continuous delivery is an automated way to push code changes to these environments.

### CI/CD Benefits

There are 4 benefits of CI/CD:
- Increase speed of innovation and ability to complete in the marketplace.
- Code in production is making money instead of sitting in a queue waiting to be deployed.
- Greate ability to attract and retain talent.
- Higher quality code and operation due to specialization.

Automated deployment is a practice that allows you to ship code fully or semy-automatically accross several stages of the development process from initial development right through to production. The automated deployment can:
- Reduce possibility of errors especially human error
- Saving time
- Consistency and repeatable

### CI/CD Tools

There are several CI/CD tools that are commonly used, namely:
|  | [Jenkins](https://jenkins.io/) | [CircleCI](https://circleci.com/) | [Bamboo](https://www.atlassian.com/software/bamboo) | [Gitlab CI](https://about.gitlab.com/) | [Github Actions](https://github.com/actions) |
|---|---|---|---|---|---|
| Open source | Yes | No | No | No | Yes |
| Ease of use & setup | Medium | Medium | Medium | Medium | Easy |
| Built-in features | 3/5 | 4/5 | 4/5 | 4/5 | 3/5 |
| Integration | <i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i> | <i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i> | <i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i> | <i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i> | <i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i><i class="fa fa-star" style='font-size:12px'></i> |
| Hosting | On premise & Cloud | On premise & Cloud | On premise & Bitbucket as Cloud | On premise & Cloud | Cloud |
| Free Version | Yes | Yes | Yes | Yes | Yes |
| Supported OS | Windows, Linux, MacOS, Unix-like OS | Linux or MacOS | Windows, Linux, MacOS, Solaris | Linux distributions: Ubuntu, Debian, CentOS, Oracle Linux | Linux, Windows, MacOS |

### Github Actions

![Github Actions](/images/github-action.png)

At the most basic level, GitHub Actions brings automation directly into the software development lifecycle on GitHub via event-driven triggers. These triggers are specified events that can range from creating a pull request to building a new brand in a repository.

GitHub Actions is a CI/CD tool for the GitHub flow. You can use it to integrate and deploy code changes to a third-party cloud application platform as well as test, track, and manage code changes. GitHub Actions also supports third-party CI/CD tools, the container platform Docker, and other automation platforms.

#### Project Preparation

Before we used a Github Actions, prepare a spring boot project. You can start from [Spring Initializer](https://start.spring.io/) to create a spring boot project. And create `Dockerfile` into a project.

```Dockerfile
# Import base JDK from Linux
FROM adoptopenjdk/openjdk11:alpine

# Set work directory
WORKDIR /app

# Copy application files
COPY target/*.jar app.jar

# Expose PORT
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Pipeline

In github action, we will create a pipeline like following image below.

![Pipeline](/images/pipeline.png)

#### Github Actions Script

Put `.yaml` file into `.github/workflows`, we will use a push trigger to run github actions jobs. First we create for unit testing step.

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  run_test:
    name: Unit Test
    runs-on: ubuntu-18.04
    steps:
      - run: echo "Starting execute unit test"
      - uses: actions/checkout@v3
      - name: Setup JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: 11
          distribution: 'adopt'
      - name: Maven Verify
        run: mvn clean verify
      - name: Maven Sonar Code Coverage
        run: mvn sonar:sonar -Dsonar.projectKey=springboot-cicd -Dsonar.login=${{ secrets.SONAR_TOKEN }}
```
Description :
- Using `ubuntu-18.04` runner
- Checkout latest code from `main` branch
- Using `java 11`
- Execute command `mvn clean verify`
- Execute command `mvn sonar:sonar -Dsonar.projectKey=springboot-cicd -Dsonar.login=${{ secrets.SONAR_TOKEN }}`

We can change the trigger using create a `tags` like following below.

```yaml
on:
  create:
    tags:
      - '*SNAPSHOT'
```

Then, create another job for build package and build images.

```yaml
build:
    name: Build
    runs-on: ubuntu-18.04
    needs: run_test
    steps:
      - run: echo "Starting build package"
      - uses: actions/checkout@v3
      - name: Setup JDK 11
        uses: actions/setup-java@v3
        with:
          java-version: 11
          distribution: 'adopt'
      - name: Maven Build
        run: mvn clean package -Dmaven.test.skip=true
      - name: Login to docker hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - name: Build docker image
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: user/images:tag
```

Description :
- Using `ubuntu-18.04` runner and need job `run_test` successfully
- Checkout latest code from `main` branch
- Setup java 11
- Execute command `mvn clean package -Dmaven.test.skip=true`
- Login to docker hub with credential on github secrets
- Execute build image from `Dockerfile` and push into images registry

Finally, create job for deploying into server using SSH.

```yaml
deployment:
    name: Deploy container using SSH
    runs-on: ubuntu-18.04
    needs: build
    steps:
      - run: echo "Starting deploy container"
      - uses: actions/checkout@v3
      - name: Copy environment file via ssh
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          port: 22
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: .env
          target: /home/${{ secrets.SSH_USERNAME }}
      - name: Deploy using ssh
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          port: 22
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            docker stop the_container
            docker rmi user/images:tag
            docker pull user/images:tag
            docker run -d --rm --name the_container -p 80:8080 --env-file=.env --network another_network user/images:tag
```

![Github Action Pipeline](/images/github-action-pipeline.png)

### Summary

Developing a CI/CD pipeline is a standard practice for businesses that frequently improve applications and require a reliable delivery process. Once in place, the CI/CD pipeline lets the team focus more on enhancing applications and less on the details of delivering it to various environments.

CI/CD pipelines are typically complex and have a lot of tools that range from testing applications to integration tests to container platforms and application platforms, among other things. GitHub Actions simplifies the process with Node and Docker integrations and allows you to specify which version you want to use and then connect your code to a target environment and application platform.

### Reference

- [What is CI/CD? Continuous integration and continuous delivery explained](https://www.infoworld.com/article/3271126/what-is-cicd-continuous-integration-and-continuous-delivery-explained.html)
- [4 Benefits of CI/CD](https://about.gitlab.com/blog/2019/06/27/positive-outcomes-ci-cd/)
- [Best 14 CI/CD Tools You Must Know | Updated for 2022](https://katalon.com/resources-center/blog/ci-cd-tools)
- [What is GitHub Actions?](https://resources.github.com/downloads/What-is-GitHub.Actions_.Benefits-and-examples.pdf)
- [Github Actions setup-java](https://github.com/actions/setup-java)
- [Docker Login Action](https://github.com/docker/login-action)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Appleboy SCP Action](https://github.com/appleboy/scp-action)
- [Appleboy SSH Action](https://github.com/appleboy/ssh-action)
