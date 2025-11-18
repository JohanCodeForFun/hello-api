# Build stage
FROM maven:3.9-eclipse-temurin-21-alpine AS build

LABEL maintainer="your-email@example.com"
LABEL description="Simple Hello API Service"

WORKDIR /app

# Kopiera pom.xml först (cache optimization)
COPY pom.xml .
RUN mvn dependency:go-offline || true

# Kopiera source code och bygg
COPY src src
RUN mvn clean package -DskipTests

# Production stage
FROM eclipse-temurin:21-jre-alpine

# Säkerhet: kör som non-root user
RUN addgroup -g 1001 spring && \
    adduser -u 1001 -G spring -s /bin/sh -D spring

WORKDIR /app

# Kopiera jar från build stage
COPY --from=build --chown=spring:spring /app/target/hello-api-1.0-SNAPSHOT.jar app.jar

# Byt till non-root user
USER spring:spring

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]