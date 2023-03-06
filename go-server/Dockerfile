FROM golang:latest as builder
LABEL maintainer="ductnn"

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .


FROM alpine:latest
LABEL maintainer="ductnn"

WORKDIR /root/
COPY --from=builder /app/server .
COPY --from=builder /app/.env .

EXPOSE 8080

CMD ["./server"]
