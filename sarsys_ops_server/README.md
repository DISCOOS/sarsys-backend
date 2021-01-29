# sarsys_ops_server module

SARSys Ops server module monitors all SARSys modules and acts as a control pane for SARSys module operations.

## Running the server locally

Run `aqueduct serve` from this directory to run the application.
For running within an IDE, run `bin/main.dart`.
By default, a configuration file named `config.yaml` will be used.

To generate a SwaggerUI client, run `make document`.

## Running server tests

To run all tests for this application, run the following in this directory:

```
make test
```

The default configuration file used when testing is `config.src.yaml`.
This file should be checked into version control.
It also the template for configuration files used in deployment.

## Deploying to Kubernetes

This server is intended to be deployed to Kubernetes. Deploy is performed using

```
make publish
```
