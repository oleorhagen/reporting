FROM golang:1.18.1-alpine3.15 as builder
WORKDIR /go/src/github.com/mendersoftware/reporting
RUN mkdir -p /etc_extra
RUN echo "nobody:x:65534:" > /etc_extra/group
RUN echo "nobody:!::0:::::" > /etc_extra/shadow
RUN echo "nobody:x:65534:65534:Nobody:/:" > /etc_extra/passwd
RUN chown -R nobody:nobody /etc_extra
RUN apk add --no-cache \
    xz-dev \
    musl-dev \
    gcc \
    git \
    ca-certificates
COPY ./ .
RUN env CGO_ENABLED=1 go build

FROM alpine:3.16.0
RUN apk add --no-cache xz
EXPOSE 8080
COPY --from=builder /etc_extra/ /etc/
USER 65534
WORKDIR /etc/reporting
COPY --from=builder --chown=nobody /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --chown=nobody ./config.yaml .
COPY --from=builder --chown=nobody /go/src/github.com/mendersoftware/reporting/reporting /usr/bin/

ENTRYPOINT ["/usr/bin/reporting", "--config", "/etc/reporting/config.yaml"]
