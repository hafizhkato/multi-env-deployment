# Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN echo "Dummy backend build" > /dummy.log
CMD ["node", "-e", "console.log('Hello from dummy container!')"]
