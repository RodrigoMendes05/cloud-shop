package pt.ulusofona.notificationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Notification Service — SQS consumer.
 *
 * <p>Polls the shop-dev-orders SQS queue, processes order events,
 * and logs simulated notifications (email/SMS in a real system).
 *
 * <p>Runs on port 8084. Exposes /health for ALB health checks.
 */
@SpringBootApplication
@EnableScheduling
public class NotificationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(NotificationServiceApplication.class, args);
    }
}
