# sarsys_app_server
SarSys Application Server

## Running locally

Run `pub run aqueduct:aqueduct serve --port 80 --isolates 2` from this directory to run the application. 
For running within an IDE, run `bin/main.dart`. By default, a configuration file named `config.yaml` 
will be used. This file is read using the [safe_config](https://pub.dev/packages/safe_config) package 
during bootstrap. The following environment variables are required to exist before bootstrap begins. 

```
TENANT=discoos
EVENTSTORE_HOST=http://127.0.0.1
EVENTSTORE_PORT=2113
EVENTSTORE_LOGIN=admin
EVENTSTORE_PASSWORD=changeit
```

Most IDEs support run configurations that allow environment variables to be set before the server is run. 
Not setting these will output the following error to the server log.

```
Invalid configuration data for 'EvenStoreConfig'. Missing required values: 'tenant', ...
``` 

## Generate Swagger client

To generate a SwaggerUI client, run `aqueduct document client`.

## Running tests

To run all tests for this application, run the following in this directory:

```
pub run test
```

The default configuration file used when testing is `config.src.yaml`. It also the template for configuration files 
used in deployment.

## Building Docker Image

```
docker build -t discoos/sarsys_app_server:latest .
```

## Push Docker Image

```
docker push discoos/sarsys_app_server:latest
```

## Deploying to Kubernetes

```
kubectl apply -f k8s/sarsys.yaml
```

See the documentation for [deployment of Aqueduct](https://aqueduct.io/docs/deploy/).