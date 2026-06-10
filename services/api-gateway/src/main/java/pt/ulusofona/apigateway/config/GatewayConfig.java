package pt.ulusofona.apigateway.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;

/**
 * Configuration class for Spring Cloud Gateway routes.
 * 
 * <p>This class configures the routing rules for the API Gateway, defining
 * how incoming requests are forwarded to backend microservices. The gateway
 * acts as a reverse proxy, routing requests based on URL patterns.
 * 
 * <p>Current routing configuration:
 * <ul>
 *   <li>/api/users/** -> User Service (http://localhost:8081)</li>
 *   <li>/api/products/** -> Product Service (http://localhost:8082)</li>
 * </ul>
 * 
 * <p>Note: When Docker Compose is implemented (Week 2), these URLs should be
 * updated to use service names instead of localhost (e.g., http://user-service:8081).
 * 
 * <p>The routes are configured programmatically using RouteLocatorBuilder, which
 * provides a fluent API for defining routes. Alternatively, routes can be
 * configured in application.yml.
 * 
 * @author Cloud Computing Course
 * @version 1.0.0
 * @since 1.0.0
 * @see org.springframework.cloud.gateway.route.RouteLocator
 * @see org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder
 */
@Configuration
public class GatewayConfig {

    @Value("${services.user.url:http://user-service:8081}")
    private String userServiceUrl;

    @Value("${services.product.url:http://product-service:8082}")
    private String productServiceUrl;

    @Value("${services.order.url:http://order-service:8083}")
    private String orderServiceUrl;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("user-service", r -> r
                        .path("/api/users/**")
                        .filters(f -> f.stripPrefix(1))
                        .uri(userServiceUrl))
                .route("product-service", r -> r
                        .path("/api/products/**")
                        .filters(f -> f.stripPrefix(1))
                        .uri(productServiceUrl))
                .route("order-service", r -> r
                        .path("/api/orders/**")
                        .filters(f -> f.stripPrefix(1))
                        .uri(orderServiceUrl))
                .build();
    }
}
