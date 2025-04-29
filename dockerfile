# Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN echo "Dummy backend build" > /dummy.log
CMD ["sh", "-c", "while true; do sleep 3600; done"]
