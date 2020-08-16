FROM alpine:3.8 AS builder

RUN apk -v --no-cache add \
      build-base \
      ca-certificates \
      curl \
      git \
      go

RUN mkdir -p /go/src/github.com/gliderlabs/registrator \
      && git clone https://github.com/gliderlabs/registrator.git \
           /go/src/github.com/gliderlabs/registrator

ENV GOPATH "/go"
ENV PATH "$PATH:/go/bin"

RUN mkdir -p /go/bin \
      && curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

RUN cd /go/src/github.com/gliderlabs/registrator \
      && git config --global http.https://gopkg.in.followRedirects true \
      && dep ensure \
      && go build -ldflags "-X main.Version=$(cat VERSION)" -o /opt/registrator/bin/registrator

FROM infrablocks/alpine-aws-s3-config:0.18.0

COPY --from=builder /opt/registrator/bin/registrator /opt/registrator/bin/registrator
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY docker-entrypoint.sh /opt/registrator/bin/docker-entrypoint.sh

ENV STARTUP_SCRIPT_PATH "/opt/registrator/bin/docker-entrypoint.sh"
