# sarsys_app_server module


## Running locally

Run `pub run aqueduct:aqueduct serve --port 80 --isolates 1` from this directory to run the application. 
For running within an IDE, run `bin/main.dart`. By default, a configuration file named `config.yaml` 
will be used. This file is read using the [safe_config](https://pub.dev/packages/safe_config) package 
during bootstrap. The following environment variables are required to exist before bootstrap begins. 

```
TENANT=discoos
EVENTSTORE_SCHEME=http
EVENTSTORE_HOST=127.0.0.1
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

To generate a SwaggerUI client, run `make document`.

## Running tests

To run all tests for this application, run the following in this directory:

```
make test
```

The default configuration file used when testing is `config.src.yaml`. It also the template for configuration files 
used in deployment.

## Building Docker Image

```
make build
```

## Push Docker Image

```
make push
```

## Deploying to Kubernetes

This server is intended to be deployed to Kubernetes. Deploy is performed using

```
make publish
```
