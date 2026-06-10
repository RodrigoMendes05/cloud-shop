package pt.ulusofona.notificationservice.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class OrderItemEvent {
    private Long productId;
    private String productName;
    private Integer quantity;
    private BigDecimal price;
}
