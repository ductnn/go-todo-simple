FROM golang:latest as builder
LABEL maintainer="ductnn"

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .
RUN chmod +x /app/server


FROM alpine:latest
LABEL maintainer="ductnn"

WORKDIR /root/

RUN addgroup --system --gid 1000 server
RUN adduser --system --uid 1000 server

COPY --from=builder --chown=server:server /app/server .
COPY --from=builder --chown=server:server /app/.env .

USER server

EXPOSE 8080

# RUN chmod +x server

CMD ["./server"]
