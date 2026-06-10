package pt.ulusofona.orderservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Entry point for the Order Service.
 *
 * <p>Inter-service communication:
 * <ul>
 *   <li><b>Synchronous (OpenFeign):</b> UserService, ProductService</li>
 *   <li><b>Asynchronous (SQS):</b> publishes OrderCreatedEvent and
 *       OrderStatusChangedEvent to the shop-dev-orders queue</li>
 * </ul>
 */
@SpringBootApplication
@EnableFeignClients
public class OrderServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
}
