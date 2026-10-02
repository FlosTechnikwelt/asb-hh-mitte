FROM node:24-alpine

LABEL org.opencontainers.image.authors="Florian Linde <florian.linde@grassau.com>"
LABEL org.opencontainers.image.description="ASB HH Mitte - Backend Service"
LABEL org.opencontainers.image.vendor="Grassau GmbH"
LABEL org.opencontainers.image.version="1.0.0"

WORKDIR /app

ENV NODE_ENV=production \
    PORT=80

COPY --chown=node:node package.json index.js index.html ./

USER node
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:' + process.env.PORT + '/healthz').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "index.js"]
