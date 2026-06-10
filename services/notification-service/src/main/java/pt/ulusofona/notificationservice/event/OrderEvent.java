package pt.ulusofona.notificationservice.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Represents an order event consumed from the SQS queue.
 *
 * <p>Uses @JsonIgnoreProperties(ignoreUnknown = true) so the consumer
 * is resilient to new fields added by the producer in future.
 */
@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class OrderEvent {

    /** Present in OrderCreatedEvent and OrderStatusChangedEvent */
    private Long orderId;
    private Long userId;

    /** Present only in OrderCreatedEvent */
    private List<OrderItemEvent> items;
    private BigDecimal totalAmount;
    private LocalDateTime createdAt;

    /** Present only in OrderStatusChangedEvent */
    private String previousStatus;
    private String newStatus;
    private LocalDateTime changedAt;
}
