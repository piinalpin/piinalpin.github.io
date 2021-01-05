# Simple Spring Batch with Quartz Scheduling


<!--more-->

### Prerequisites
* [MySQL Database](https://www.mysql.com/)
* [Spring Initializr](https://start.spring.io/)
* [Spring Boot Starter Batch](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-batch/2.4.0)
* [Spring Boot Starter Quartz](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-quartz/2.4.0)
* [MySQL-Connector](https://mvnrepository.com/artifact/mysql/mysql-connector-java/8.0.22)
* [Lombok Annotation](https://mvnrepository.com/artifact/org.projectlombok/lombok/1.18.16)

### What is Spring Batch?

![Spring batch reference model](/images/spring-batch-reference-model.png)

Spring Batch is a lightweight, comprehensive batch framework designed to enable the development of robust batch applications vital for the daily operations of enterprise systems. Spring Batch builds upon the characteristics of the Spring Framework that people have come to expect (productivity, POJO-based development approach, and general ease of use), while making it easy for developers to access and leverage more advance enterprise services when necessary. Spring Batch is not a scheduling framework. There are many good enterprise schedulers (such as Quartz, Tivoli, Control-M, etc.) available in both the commercial and open source spaces. It is intended to work in conjunction with a scheduler, not replace a scheduler.

### Step to create spring batch
1. Create business data

Typically, your customer or a business analyst supplies a spreadsheet. For this simple example, you can find some made-up data in `src/main/resources/sample-data.csv`:

```html
Maverick,24,M
Al Sah-Him,21,M
Felicia,24,F
Jessica,22,F
Calvin Joe,25,M
```
Next, write an SQL script to create a table and store data.

```sql
CREATE TABLE M_HUMAN
(
    id         bigint auto_increment primary key,
    created_at timestamp default CURRENT_TIMESTAMP not null,
    updated_at timestamp                           null on update CURRENT_TIMESTAMP,
    deleted_at timestamp                           null,
    name       varchar(255)                        not null,
    age        varchar(3)                          not null,
    gender     varchar(1)                          not null
);
```

2. Starting with spring initializr

For all Spring applications, you should start with the [Spring Initializr](https://start.spring.io/). The Initializr offers a fast way to pull in all the dependencies you need for an application and does a lot of the set up for you. This example needs the Spring Batch. And we will started with maven project.
	
The following listing shows the `pom.xml` file created when you choose Maven:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.4.0</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.maverick</groupId>
	<artifactId>spring-batch-example</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>spring-batch-example</name>
	<description>Demo project for Spring Boot</description>

	<properties>
		<java.version>11</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-batch</artifactId>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.batch</groupId>
			<artifactId>spring-batch-test</artifactId>
			<scope>test</scope>
		</dependency>
		<!-- https://mvnrepository.com/artifact/mysql/mysql-connector-java -->
		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<version>8.0.22</version>
		</dependency>

		<!-- https://mvnrepository.com/artifact/org.projectlombok/lombok -->
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<version>1.18.16</version>
			<scope>provided</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-quartz</artifactId>
		</dependency>

	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

</project>

```

3. Create a model class as the following example `src/main/java/com/maverick/springbatchexample/model/Person.java`

```java
package com.maverick.springbatchexample.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Person {

    private String name;

    private String age;

    private String gender;

}
```

4. Create an intermediate processor as the following example `src/main/java/com/maverick/springbatchexample/processor/PersonItemProcessor.java`

```java
package com.maverick.springbatchexample.processor;

import com.maverick.springbatchexample.model.Person;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.item.ItemProcessor;

public class PersonItemProcessor implements ItemProcessor<Person, Person> {

    private static final Logger LOG = LoggerFactory.getLogger(PersonItemProcessor.class);

    @Override
    public Person process(Person person) throws Exception {
        LOG.info("### Process: " + person.getName());
        return person;
    }

}
```

5. Create datasource configuration as the following example `src/main/java/com/maverick/springbatchexample/configuration/DataSourceConfiguration.java`

```java
package com.maverick.springbatchexample.configuration;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfiguration {

    @Value("${spring.datasource.url}")
    private String datasourceUrl;

    @Value("${spring.datasource.username}")
    private String datasourceUsername;

    @Value("${spring.datasource.password}")
    private String datasourcePassword;

    @Value("${spring.datasource.driverClassName}")
    private String datasourceDriverClassName;

    @Bean(name = "MVRCKDatasource")
    @Primary
    public DataSource dataSource() {
        return DataSourceBuilder.create()
                .url(datasourceUrl)
                .username(datasourceUsername)
                .password(datasourcePassword)
                .driverClassName(datasourceDriverClassName)
                .build();
    }

    @Bean(name = "MVRCKJdbcTemplate")
    public JdbcTemplate jdbcTemplate(@Qualifier("MVRCKDatasource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

}
```

6. Create quartz job launcher as the following example `src/main/java/com/maverick/springbatchexample/quartz/QuartzJobLauncher.java`

```java
package com.maverick.springbatchexample.quartz;

import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.*;
import org.springframework.batch.core.configuration.JobLocator;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.batch.core.launch.NoSuchJobException;
import org.springframework.batch.core.repository.JobExecutionAlreadyRunningException;
import org.springframework.batch.core.repository.JobInstanceAlreadyCompleteException;
import org.springframework.batch.core.repository.JobRestartException;
import org.springframework.scheduling.quartz.QuartzJobBean;

public class QuartzJobLauncher extends QuartzJobBean {

    private static final Logger LOG = LoggerFactory.getLogger(QuartzJobLauncher.class);

    private String jobName;
    private JobLauncher jobLauncher;
    private JobLocator jobLocator;

    public String getJobName() {
        return jobName;
    }

    public void setJobName(String jobName) {
        this.jobName = jobName;
    }

    public JobLauncher getJobLauncher() {
        return jobLauncher;
    }

    public void setJobLauncher(JobLauncher jobLauncher) {
        this.jobLauncher = jobLauncher;
    }

    public JobLocator getJobLocator() {
        return jobLocator;
    }

    public void setJobLocator(JobLocator jobLocator) {
        this.jobLocator = jobLocator;
    }

    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        try {
            Job job = jobLocator.getJob(jobName);
            JobParameters jobParameters = new JobParametersBuilder()
                    .addLong("time",System.currentTimeMillis())
                    .toJobParameters();
            JobExecution jobExecution = jobLauncher.run(job, jobParameters);
            LOG.info("Job was completed successfully.", job.getName(), jobExecution.getId());
        } catch (JobParametersInvalidException | NoSuchJobException | JobExecutionAlreadyRunningException | JobInstanceAlreadyCompleteException | JobRestartException ex) {
            LOG.error("Failed execute job !!!");
            LOG.error(ex.getMessage());
        }
    }

}
```

7. Create quartz configuration as the following example `src/main/java/com/maverick/springbatchexample/quartz/QuartzConfiguration.java`

Quartz Scheduler Cron Format

Format [ * * * * * ? * ]

------>[ 1 2 3 4 5 6 7 ]

[1] : Seconds

[2] : Minutes

[3] : Hours

[4] : Day of month

[5] : Month

[6] : Day of week

[7] : Year

```java
package com.maverick.springbatchexample.quartz;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.configuration.JobLocator;
import org.springframework.batch.core.configuration.JobRegistry;
import org.springframework.batch.core.configuration.support.JobRegistryBeanPostProcessor;
import org.springframework.batch.core.explore.JobExplorer;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.batch.core.launch.JobOperator;
import org.springframework.batch.core.launch.support.SimpleJobLauncher;
import org.springframework.batch.core.launch.support.SimpleJobOperator;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.repository.support.JobRepositoryFactoryBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.quartz.CronTriggerFactoryBean;
import org.springframework.scheduling.quartz.JobDetailFactoryBean;
import org.springframework.scheduling.quartz.SchedulerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class QuartzConfiguration {

    private static final Logger LOG = LoggerFactory.getLogger(QuartzConfiguration.class);

    private final DataSource dataSource;
    private final JobExplorer jobExplorer;
    private final JobLocator jobLocator;
    private final JobRegistry jobRegistry;
    private final PlatformTransactionManager platformTransactionManager;

    @Value("${scheduler.maverick.cron}")
    private String schedulerMaverickCron;

    @Autowired
    public QuartzConfiguration(DataSource dataSource, JobExplorer jobExplorer, JobLocator jobLocator,
                               JobRegistry jobRegistry, PlatformTransactionManager platformTransactionManager) {
        this.dataSource = dataSource;
        this.jobExplorer = jobExplorer;
        this.jobLocator = jobLocator;
        this.jobRegistry = jobRegistry;
        this.platformTransactionManager = platformTransactionManager;
    }

    @Bean
    public JobRegistryBeanPostProcessor jobRegistryBeanPostProcessor(JobRegistry jobRegistry) {
        JobRegistryBeanPostProcessor jobRegistryBeanPostProcessor = new JobRegistryBeanPostProcessor();
        jobRegistryBeanPostProcessor.setJobRegistry(jobRegistry);
        return jobRegistryBeanPostProcessor;
    }

    @Bean(name = "jobRepository")
    public JobRepository jobRepository() {
        JobRepositoryFactoryBean factoryBean = new JobRepositoryFactoryBean();
        factoryBean.setDataSource(dataSource);
        factoryBean.setTransactionManager(platformTransactionManager);
        factoryBean.setIsolationLevelForCreate("ISOLATION_READ_COMMITTED");
        factoryBean.setTablePrefix("BATCH_");
        try {
            factoryBean.afterPropertiesSet();
            return factoryBean.getObject();
        } catch (Exception ex) {
            LOG.error("JobRepository bean could not be initialized", ex);
        }
        return null;
    }

    @Bean
    public JobLauncher jobLauncher(){
        SimpleJobLauncher jobLauncher = new SimpleJobLauncher();
        jobLauncher.setJobRepository(jobRepository());
        return jobLauncher;
    }

    @Bean
    public JobOperator jobOperator() {
        SimpleJobOperator jobOperator = new SimpleJobOperator();
        jobOperator.setJobExplorer(jobExplorer);
        jobOperator.setJobLauncher(jobLauncher());
        jobOperator.setJobRegistry(jobRegistry);
        jobOperator.setJobRepository(jobRepository());
        return jobOperator;
    }

    @Bean
    public JobDetailFactoryBean jobDetailFactoryBean() {
        JobDetailFactoryBean factory = new JobDetailFactoryBean();
        factory.setJobClass(QuartzJobLauncher.class);
        Map<String, Object> map = new HashMap<>();
        map.put("jobName", "importPersonJob");
        map.put("jobLauncher", jobLauncher());
        map.put("jobLocator", jobLocator);
        factory.setJobDataAsMap(map);
        return factory;
    }

    @Bean
    public CronTriggerFactoryBean cronTriggerFactoryBean() {
        CronTriggerFactoryBean stFactory = new CronTriggerFactoryBean();
        stFactory.setJobDetail(jobDetailFactoryBean().getObject());
        stFactory.setCronExpression(schedulerMaverickCron);
        stFactory.setName("cronTriggerFactoryBean");
        return stFactory;
    }

    @Bean
    public SchedulerFactoryBean schedulerBean() {
        SchedulerFactoryBean scheduler = new SchedulerFactoryBean();
        scheduler.setTriggers(cronTriggerFactoryBean().getObject());
        return scheduler;
    }

}
```

8. Create job completion notification listener to notify when job is complete as the following example `src/main/java/com/maverick/springbatchexample/service/JobCompletionNotificationListener.java`

```java
package com.maverick.springbatchexample.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.BatchStatus;
import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.listener.JobExecutionListenerSupport;
import org.springframework.stereotype.Service;

@Service
public class JobCompletionNotificationListener extends JobExecutionListenerSupport {

    private static final Logger LOG = LoggerFactory.getLogger(JobCompletionNotificationListener.class);

    @Override
    public void afterJob(JobExecution jobExecution) {
        if (jobExecution.getStatus() == BatchStatus.COMPLETED) {
            LOG.info("### JOB FINISHED!");
        }
    }
}
```

9. Put together a batch job configuration as the following example `src/main/java/com/maverick/springbatchexample/configuration/BatchConfiguration.java`

```java
package com.maverick.springbatchexample.configuration;

import com.maverick.springbatchexample.model.Person;
import com.maverick.springbatchexample.processor.PersonItemProcessor;
import com.maverick.springbatchexample.service.JobCompletionNotificationListener;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
import org.springframework.batch.core.configuration.annotation.JobBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepScope;
import org.springframework.batch.core.launch.support.RunIdIncrementer;
import org.springframework.batch.item.database.BeanPropertyItemSqlParameterSourceProvider;
import org.springframework.batch.item.database.JdbcBatchItemWriter;
import org.springframework.batch.item.database.builder.JdbcBatchItemWriterBuilder;
import org.springframework.batch.item.file.FlatFileItemReader;
import org.springframework.batch.item.file.builder.FlatFileItemReaderBuilder;
import org.springframework.batch.item.file.mapping.BeanWrapperFieldSetMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import javax.sql.DataSource;

@Configuration
@EnableBatchProcessing
public class BatchConfiguration {

    private final JobBuilderFactory jobBuilderFactory;
    private final StepBuilderFactory stepBuilderFactory;

    @Value("${files.source-file:sample-data.csv}")
    private String sourceFile;

    @Autowired
    public BatchConfiguration(JobBuilderFactory jobBuilderFactory, StepBuilderFactory stepBuilderFactory) {
        this.jobBuilderFactory = jobBuilderFactory;
        this.stepBuilderFactory = stepBuilderFactory;
    }

    @Bean
    public FlatFileItemReader<Person> reader() {
        return new FlatFileItemReaderBuilder<Person>()
                .name("personItemReader")
                .resource(new ClassPathResource(sourceFile))
                .delimited()
                .names(new String[]{"name", "age", "gender"})
                .fieldSetMapper(new BeanWrapperFieldSetMapper<>(){{
                    setTargetType(Person.class);
                }})
                .build();
    }

    @Bean
    @StepScope
    public PersonItemProcessor processor() {
        return new PersonItemProcessor();
    }

    @Bean
    public JdbcBatchItemWriter<Person> writer(DataSource dataSource) {
        return new JdbcBatchItemWriterBuilder<Person>()
                .itemSqlParameterSourceProvider(new BeanPropertyItemSqlParameterSourceProvider<>())
                .sql("INSERT INTO M_HUMAN (name, age, gender) VALUES (:name, :age, :gender)")
                .dataSource(dataSource)
                .build();
    }

    @Bean
    public Job importPersonJob(JobCompletionNotificationListener listener,
                               @Qualifier("personImportStep") Step personImportStep) {
        return jobBuilderFactory.get("importPersonJob")
                .incrementer(new RunIdIncrementer())
                .listener(listener)
                .start(personImportStep)
                .build();
    }

    @Bean
    public Step personImportStep(FlatFileItemReader<Person> reader,
                                 PersonItemProcessor processor,
                                 JdbcBatchItemWriter<Person> writer) {
        return stepBuilderFactory.get("personImportStep")
                .<Person, Person> chunk(10)
                .reader(reader)
                .processor(processor)
                .writer(writer)
                .build();
    }

}
```

10. Make application executable and load `application.properties` from classpath

```java
@SpringBootApplication
@PropertySources({
		@PropertySource(value = "classpath:application.properties", ignoreResourceNotFound = true)
})
public class SpringBatchExampleApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringBatchExampleApplication.class, args);
	}

}
```

11. Edit `src/main/resources/application.properties` to allow initialize schema and etc.

```
spring.batch.initialize-schema=ALWAYS
spring.main.allow-bean-definition-overriding=true
spring.batch.job.enabled=false
```

12. Create an external application configuration call `application.yml`

```yml
app:
  name: "Spring Batch Example"
spring:
  profiles:
    active: "dev"
  datasource:
    url: "jdbc:mysql://localhost:3306/DB_NAME?allowPublicKeyRetrieval=true&useSSL=false"
    username: DB_USERNAME
    password: DB_PASSWORD
    driverClassName: com.mysql.cj.jdbc.Driver
scheduler:
  maverick:
    cron: "0 0 14 ? * TUE *"
files:
  source-file: "sample-data.csv"
```

13. Build an executable jar with `mvn clean package` and run application parallel to `application.yml` with command 
```bash
java -jar spring-batch-example-0.0.1-SNAPSHOT.jar -Dspring.config.location=application.yml
```

The job prints out a line for each person that gets transformed. After the job runs, you can also see the output from querying the database. It should resemble the following output:

```log
2020-12-08 14:00:00.218  INFO 78242 --- [erBean_Worker-1] o.s.b.c.l.support.SimpleJobLauncher      : Job: [SimpleJob: [name=importPersonJob]] launched with the following parameters: [{time=1607410800020}]
2020-12-08 14:00:00.338  INFO 78242 --- [erBean_Worker-1] o.s.batch.core.job.SimpleStepHandler     : Executing step: [personImportStep]
2020-12-08 14:00:00.437  INFO 78242 --- [erBean_Worker-1] c.m.s.processor.PersonItemProcessor      : ### Process: Maverick
2020-12-08 14:00:00.438  INFO 78242 --- [erBean_Worker-1] c.m.s.processor.PersonItemProcessor      : ### Process: Al Sah-Him
2020-12-08 14:00:00.438  INFO 78242 --- [erBean_Worker-1] c.m.s.processor.PersonItemProcessor      : ### Process: Felicia
2020-12-08 14:00:00.438  INFO 78242 --- [erBean_Worker-1] c.m.s.processor.PersonItemProcessor      : ### Process: Jessica
2020-12-08 14:00:00.438  INFO 78242 --- [erBean_Worker-1] c.m.s.processor.PersonItemProcessor      : ### Process: Calvin Joe
2020-12-08 14:00:00.503  INFO 78242 --- [erBean_Worker-1] o.s.batch.core.step.AbstractStep         : Step: [personImportStep] executed in 164ms
2020-12-08 14:00:00.533  INFO 78242 --- [erBean_Worker-1] .m.s.s.JobCompletionNotificationListener : ### JOB FINISHED!
2020-12-08 14:00:00.559  INFO 78242 --- [erBean_Worker-1] o.s.b.c.l.support.SimpleJobLauncher      : Job: [SimpleJob: [name=importPersonJob]] completed with the following parameters: [{time=1607410800020}] and the following status: [COMPLETED] in 267ms
```

### Clone or Download

You can clone or download this project
```bash
git@github.com:piinalpin/spring-batch-quartz-example.git
```

### Thankyou

[Spring.io](https://spring.io/guides/gs/batch-processing/) - Create a Batch Service