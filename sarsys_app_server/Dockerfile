FROM google/dart:2.8.2
MAINTAINER DISCO Open Source <admin@discoos.org>

WORKDIR /app
ADD bin/main.snapshot /app/
ADD config.yaml /app/
ADD web/ /app/web/

# Use a number instead of 'aqueduct' to prevent kubernetes error 'CreateContainerConfigError: Error: container
# has runAsNonRoot and image has non-numeric user (aqueduct), cannot verify user is non-root'.
RUN groupadd -r -g 1000 aqueduct
RUN useradd -m -r -u 1000 -g 1000 aqueduct
RUN chown -R 1000:1000 /app
RUN mkdir -p /var/lib/sarsys && chown -R 1000:1000 /var/lib/sarsys && chmod -R 700 /var/lib/sarsys

USER 1000

# We are running with an non-privileged used for secure setup. This forces ut to use a non-privileged port also.
# Ports below 1024 are called Privileged Ports and in Linux (and most UNIX flavors and UNIX-like systems),
# they are not allowed to be opened by any non-root user. This is a security feature originally implemented as a
# way to prevent a malicious user from setting up a malicious service on a well-known service port.
# If we use port 80  'SocketException: Failed to create server socket (OS Error: Permission denied, errno = 13)'
# is raised.
EXPOSE 8082

VOLUME /var/lib/sarsys

HEALTHCHECK --timeout=4s CMD curl -sf http://localhost:8082/api/healthz || exit 1

ENTRYPOINT ["dart", "main.snapshot", "--port", "8082", "--instances", "1", "--config", "config.yaml"]