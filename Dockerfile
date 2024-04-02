# Use the Go 1.19 Alpine image as the base for building
FROM golang:1.19-alpine as gobuild

# Set the working directory inside the container
WORKDIR /build

# Copy only the Go module files to cache dependencies
COPY go.mod go.sum /build/

# Download dependencies separately to leverage Docker layer caching
RUN go mod download -x

# Copy the entire source code to the working directory
COPY cmd /build/cmd
COPY pkg /build/pkg

# Build the Go binary with static linking
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

# Start a new stage for the final minimal Alpine image
FROM alpine:3.17

# Add metadata to the image
LABEL maintainers="Shreyas And Anshul"
LABEL description="csi-s3 slim image"

# Use a different mirror for Alpine packages
#ENV ALPINE_MIRROR "http://dl-cdn.alpinelinux.org/alpine"

# Install necessary packages using Alpine package manager
RUN apk add fuse mailcap rclone
RUN apk add -X s3fs-fuse

# Download geesefs binary and set permissions
ADD https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-amd64 /usr/bin/geesefs
RUN chmod 755 /usr/bin/geesefs

# Copy the built binary from the previous stage
COPY --from=gobuild /build/s3driver /s3driver

# Set the entry point for the container
ENTRYPOINT ["/s3driver"]

#FROM golang:1.19-alpine as gobuild
#
#WORKDIR /build
#ADD go.mod go.sum /build/
#RUN go mod download -x
#ADD cmd /build/cmd
#ADD pkg /build/pkg
#RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver
#
#FROM alpine:3.17
#LABEL maintainers="Shreyas And Anshul"
#LABEL description="csi-s3 slim image"
#
#RUN apk add --no-cache fuse mailcap rclone
#RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community s3fs-fuse
#
#ADD https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-amd64 /usr/bin/geesefs
#RUN chmod 755 /usr/bin/geesefs
#
#COPY --from=gobuild /build/s3driver /s3driver
#ENTRYPOINT ["/s3driver"]
