# sarsys_app_server
SarSys Application Server

## Running the Application Locally

Run `aqueduct serve` from this directory to run the application. For running within an IDE, run `bin/main.dart`. By default, a configuration file named `config.yaml` will be used.

To generate a SwaggerUI client, run `aqueduct document client`.

## Running Application Tests

To run all tests for this application, run the following in this directory:

```
pub run test
```

The default configuration file used when testing is `config.src.yaml`. This file should be checked into version control. It also the template for configuration files used in deployment.

## Building Docker Image

```
docker build -t discoos/sarsys_app_server:latest .
```

## Push Docker Image

```
docker push discoos/sarsys_app_server:latest
```

## Deploying an Application

See the documentation for [Deployment](https://aqueduct.io/docs/deploy/).