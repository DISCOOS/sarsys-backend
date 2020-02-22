FROM google/dart

WORKDIR /app
ADD pubspec.* /app/

# Use a number instead of 'aqueduct' to prevent kubernetes error 'CreateContainerConfigError: Error: container
# has runAsNonRoot and image has non-numeric user (aqueduct), cannot verify user is non-root'.
RUN groupadd -r -g 1000 aqueduct
RUN useradd -m -r -u 1000 -g 1000 aqueduct
RUN chown -R aqueduct:aqueduct /app

USER 1000
RUN pub get --no-precompile

USER root
ADD .. /app
RUN chown -R 1000:1000 /app

USER 1000
RUN pub get --offline --no-precompile

# Make dart snapshot - reduces image size and memory consumption
RUN dart --snapshot=bin/main.snapshot --snapshot-kind=app-jit bin/main.dart --port 8082 --instances 1 --training=true --config=config.src.yaml

# We are running with an non-privileged used for secure setup. This forces ut to use a non-privileged port also.
# Ports below 1024 are called Privileged Ports and in Linux (and most UNIX flavors and UNIX-like systems),
# they are not allowed to be opened by any non-root user. This is a security feature originally implemented as a
# way to prevent a malicious user from setting up a malicious service on a well-known service port.
# If we use port 80  'SocketException: Failed to create server socket (OS Error: Permission denied, errno = 13)'
# is raised.
EXPOSE 8082

ENTRYPOINT ["dart", "bin/main.snapshot", "--port", "8082", "--instances", "1", "--config", "config.yaml"]