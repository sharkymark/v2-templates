# Start from base image (built on Docker host)
FROM coder-base:v0.1

# Install everything as root
USER root

# Install go
RUN curl -L "https://dl.google.com/go/go1.18.1.linux-amd64.tar.gz" | tar -C /usr/local -xzvf -

# Setup go env vars
ENV GOROOT /usr/local/go
ENV PATH $PATH:$GOROOT/bin

ENV GOPATH /home/coder/go
ENV GOBIN $GOPATH/bin
ENV PATH $PATH:$GOBIN

# Set back to coder user
USER coder