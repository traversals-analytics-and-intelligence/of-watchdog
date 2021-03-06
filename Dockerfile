FROM golang:1.13

ARG CGO_ENABLED=0
ARG GO111MODULE="off"
ARG GOPROXY=""

WORKDIR /go/src/github.com/openfaas-incubator/of-watchdog

# This runs are only a workaround, it's not possible to have all copy after each other
# https://github.com/moby/moby/issues/37965
COPY vendor              vendor
RUN ls
COPY config              config
RUN ls
COPY executor            executor
RUN ls
COPY metrics             metrics
RUN ls
COPY metrics             metrics
RUN ls
COPY main.go             .

# Run a gofmt and exclude all vendored code.
RUN test -z "$(gofmt -l $(find . -type f -name '*.go' -not -path "./vendor/*"))"

RUN go test -v ./...

# Stripping via -ldflags "-s -w" 
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags "-s -w" -installsuffix cgo -o of-watchdog . \
    && CGO_ENABLED=0 GOOS=darwin go build -a -ldflags "-s -w" -installsuffix cgo -o of-watchdog-darwin . \
    && GOARM=6 GOARCH=arm CGO_ENABLED=0 GOOS=linux go build -a -ldflags "-s -w" -installsuffix cgo -o of-watchdog-armhf . \
    && GOARCH=arm64 CGO_ENABLED=0 GOOS=linux go build -a -ldflags "-s -w" -installsuffix cgo -o of-watchdog-arm64 . \
    && GOOS=windows CGO_ENABLED=0 go build -a -ldflags "-s -w" -installsuffix cgo -o of-watchdog.exe .
