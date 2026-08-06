# syntax=docker/dockerfile:1.4

############################
# 1️⃣  Build the Go binary
############################
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build

WORKDIR /src
COPY . .

# Cache Go dependencies – speeds subsequent builds
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    # Static binary (no cgo → no dynamic libs)
    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    go build -trimpath -buildmode=exe -o /purpleair2mqtt

############################
# 2️⃣  Minimal runtime image
############################
# `scratch` contains nothing – only the static binary.  If you prefer a tiny Alpine base, replace `scratch` with `alpine:3.18`.
FROM scratch
COPY --from=build /purpleair2mqtt /purpleair2mqtt

# The binary expects to be pointed at a config file at run‑time,
# e.g. `docker run -v /path/config.toml:/config.toml <image> -config /config.toml`.
ENTRYPOINT ["/purpleair2mqtt", "-config", "/config.toml"]
