# ── Stage 1: build ──────────────────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Cache dependencies before copying source
COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn package -DskipTests -q

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /app/target/notification-service-*.jar app.jar

EXPOSE 8084

ENTRYPOINT ["java", "-jar", "app.jar"]
