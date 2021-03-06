FROM google/dart:2.12.2
MAINTAINER DISCO Open Source <admin@discoos.org>

WORKDIR /app
ADD bin/main.snapshot /app/
ADD config.yaml /app/

# Use a number instead of 'sarsys' to prevent kubernetes error 'CreateContainerConfigError: Error: container
# has runAsNonRoot and image has non-numeric user (sarsys), cannot verify user is non-root'.
RUN groupadd -r -g 1000 sarsys
RUN useradd -m -r -u 1000 -g 1000 sarsys
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
EXPOSE 8083

VOLUME /var/lib/sarsys

HEALTHCHECK --timeout=4s CMD curl -sf http://localhost:8082/api/healthz/alive || exit 1

# ENTRYPOINT ["dart", "run", "--observe", "main.snapshot", "--healthPort", "8082", "--grpcPort", "8083", "--config", "config.yaml"]
ENTRYPOINT ["dart", "run", "main.snapshot", "--healthPort", "8082", "--grpcPort", "8083", "--config", "config.yaml"]