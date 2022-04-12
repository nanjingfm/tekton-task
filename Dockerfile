FROM registry.alauda.cn:60080/devops/builder-go:1.17.6-ubuntu-12 as builder
RUN mkdir -p /build-tools/bin /build-tools/lib
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
RUN set -eux; \
    apt-get update; \
    apt-get -y install rsync; \
    cp "$(which rsync)" ./bin; \
    lib_path=$(ls /usr/lib/ | grep linux-gnu | awk '{print "/usr/lib/"$1}'); \
    ls "${lib_path}" | grep libpopt | xargs -I EE cp "${lib_path}/EE" ./lib;

FROM registry.alauda.cn:60080/devops/builder-go:1.17.6-ubuntu-12
COPY --from=builder /build-tools/bin /build-tools/bin/
COPY --from=builder /build-tools/lib /build-tools/lib/
RUN set -eux; \
    lib_path=$(ls /usr/lib/ | grep linux-gnu | awk '{print "/usr/lib/"$1}'); \
    mv /build-tools/lib/* "${lib_path}"
ENV PATH /build-tools/bin:$PATH
