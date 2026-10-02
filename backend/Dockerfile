FROM golang:1.26-alpine AS build

LABEL org.opencontainers.image.authors="Florian Linde <florian.linde@grassau.com>"
LABEL org.opencontainers.image.description="ASB HH Mitte - Backend Service"
LABEL org.opencontainers.image.vendor="Grassau GmbH"
LABEL org.opencontainers.image.version="1.0.0"

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/backend .

FROM scratch

WORKDIR /app

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/backend /app/backend

USER 65532:65532
EXPOSE 8080

ENTRYPOINT ["/app/backend"]
