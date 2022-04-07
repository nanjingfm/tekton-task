FROM registry.alauda.cn:60080/devops/builder-go:1.17.6-ubuntu-12 as builder
RUN mkdir -p /build-tools/bin
WORKDIR /build-tools
RUN set -eux; \
    curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b ./bin 2>&1; \
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ./bin 2>&1; \
    set +e; \
    curl -sfL https://raw.githubusercontent.com/get-woke/woke/main/install.sh | sh -s -- -b ./bin 2>&1 > /dev/null; \
    downloadWokeCode="$?"; \
    set -e; \
    if [ $downloadWokeCode -gt 0 ]; then \
      arch="$(dpkg --print-architecture)"; \
      if [ "$arch" = "arm64" ]; then \
        wget https://github.com/get-woke/woke/releases/download/v0.18.1/woke-0.18.1-linux-arm64.tar.gz; \
        tar zxvf woke-0.18.1-linux-arm64.tar.gz; \
        mv woke-0.18.1-linux-arm64/woke ./bin; \
      else \
        echo "Installing woke failed ..."; \
        exit 1; \
      fi; \
    fi; \
    export GOSUMDB="off"; \
    export GOPROXY=https://proxy.golang.com.cn,https://proxy.golang.org,direct; \
    go get github.com/client9/misspell/cmd/misspell; \
    go get github.com/mattmoor/boilerplate-check/cmd/boilerplate-check; \
    cp "$(go env GOPATH)/bin/misspell" ./bin; \
    cp "$(go env GOPATH)/bin/boilerplate-check" ./bin; \
    echo "Installing success..."

FROM registry.alauda.cn:60080/devops/builder-go:1.17.6-ubuntu-12
COPY --from=builder /build-tools/bin /build-tools/bin/
ENV PATH /build-tools/bin:$PATH
