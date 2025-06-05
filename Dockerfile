# syntax=docker/dockerfile:1.7-labs
FROM rust:alpine AS builder

ARG TARGETPLATFORM
ARG BINARY_NAME=hello_world

WORKDIR /usr/src/app
COPY --parents ./Cargo.toml ./Cargo.lock ./src ./

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/src/app/target \
    apk add --no-cache musl-dev && \
    case "${TARGETPLATFORM}" in \
        linux/amd64) TARGET="x86_64-unknown-linux-musl";; \
        linux/arm64) TARGET="aarch64-unknown-linux-musl";; \
        *) echo "Unsupported platform: ${TARGETPLATFORM}"; exit 1;; \
    esac && \
    rustup target add $TARGET && \
    cargo build --release --target $TARGET --bin $BINARY_NAME && \
    cp target/$TARGET/release/$BINARY_NAME /usr/local/bin/app

FROM alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

WORKDIR /home/appuser/app

COPY --from=builder /usr/local/bin/app /usr/local/bin/app

CMD ["app"]
