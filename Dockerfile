FROM registry.redhat.io/ubi8/ubi as builder
LABEL maintainer="quentin.henneaux@sokube.ch" \
      name="Skopeo" \
      version="v1.2.0" \
      build_date=""

ENV SKOPEO_RELEASE="v1.2.0"
ENV OS="linux"
ENV ARCH="amd64"

WORKDIR /tmp
RUN dnf install -y ca-certificates make gpgme-devel libassuan-devel device-mapper-devel git go-toolset \
    && git clone --depth 1 --branch ${SKOPEO_RELEASE} https://github.com/containers/skopeo.git $GOPATH/src/github.com/containers/skopeo \
    && update-ca-trust
WORKDIR ${GOPATH}/src/github.com/containers/skopeo/
RUN CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} go build -a -installsuffix cgo -ldflags '-w -s' -gcflags "" -tags "exclude_graphdriver_devicemapper exclude_graphdriver_btrfs containers_image_openpgp" -o /go/bin/skopeo ./cmd/skopeo

FROM scratch
COPY --from=builder /go/bin/skopeo /go/bin/skopeo
COPY --from=builder /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
COPY --from=builder --chown=1001:0 /run /run
COPY --from=builder --chown=1001:0 /src/github.com/containers/skopeo/default-policy.json /etc/containers/policy.json
USER 1001
ENTRYPOINT ["/go/bin/skopeo"]
