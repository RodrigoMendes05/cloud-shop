package pt.ulusofona.notificationservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import pt.ulusofona.notificationservice.event.OrderEvent;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;

import java.util.List;

/**
 * Polls the SQS queue every 5 seconds and processes order events.
 *
 * <p>Processing model:
 * <ol>
 *   <li>Receive up to 10 messages (long-polling, 20 s wait)</li>
 *   <li>For each message: deserialise → handle → delete</li>
 *   <li>If handling throws, the message is NOT deleted → visibility
 *       timeout expires → re-queued → after maxReceiveCount it goes
 *       to the DLQ</li>
 * </ol>
 *
 * <p>This guarantees at-least-once delivery and lets the DLQ story
 * work naturally for the defence.
 */
@Slf4j
@Service
public class SqsConsumer {

    private final SqsClient sqsClient;
    private final String queueUrl;
    private final ObjectMapper objectMapper;
    private final boolean enabled;

    public SqsConsumer(
            SqsClient sqsClient,
            @Value("${aws.sqs.queue-url:disabled}") String queueUrl) {
        this.sqsClient = sqsClient;
        this.queueUrl = queueUrl;
        this.enabled = !"disabled".equals(queueUrl);
        this.objectMapper = new ObjectMapper()
                .registerModule(new JavaTimeModule());

        if (enabled) {
            log.info("SQS consumer enabled — queue: {}", queueUrl);
        } else {
            log.info("SQS consumer disabled (no queue URL configured)");
        }
    }

    /**
     * Polling loop. Runs every 5 s; long-poll inside keeps connections efficient.
     * Fixed-delay so the next poll only starts after the current one finishes.
     */
    @Scheduled(fixedDelay = 5000)
    public void poll() {
        if (!enabled) return;

        ReceiveMessageRequest request = ReceiveMessageRequest.builder()
                .queueUrl(queueUrl)
                .maxNumberOfMessages(10)
                .waitTimeSeconds(20)   // long polling — reduces empty responses
                .build();

        List<Message> messages;
        try {
            messages = sqsClient.receiveMessage(request).messages();
        } catch (Exception e) {
            log.error("Error receiving messages from SQS", e);
            return;
        }

        for (Message message : messages) {
            try {
                processMessage(message);
                deleteMessage(message);
            } catch (Exception e) {
                // Do NOT delete — let the visibility timeout expire so SQS retries
                log.error("Failed to process message {} — will retry (DLQ after {} attempts)",
                        message.messageId(), 3, e);
            }
        }
    }

    private void processMessage(Message message) throws Exception {
        log.debug("Received SQS message: id={} body={}", message.messageId(), message.body());

        OrderEvent event = objectMapper.readValue(message.body(), OrderEvent.class);

        if (event.getNewStatus() != null) {
            // OrderStatusChangedEvent
            log.info("[NOTIFICATION] Order {} status changed: {} → {}  (user: {})",
                    event.getOrderId(),
                    event.getPreviousStatus(),
                    event.getNewStatus(),
                    event.getUserId());
        } else {
            // OrderCreatedEvent
            int itemCount = event.getItems() != null ? event.getItems().size() : 0;
            log.info("[NOTIFICATION] New order {} created for user {} — {} item(s), total: {}",
                    event.getOrderId(),
                    event.getUserId(),
                    itemCount,
                    event.getTotalAmount());

            if (event.getItems() != null) {
                event.getItems().forEach(item ->
                    log.info("  → {} x {} @ {}",
                            item.getQuantity(), item.getProductName(), item.getPrice()));
            }
        }
    }

    private void deleteMessage(Message message) {
        sqsClient.deleteMessage(DeleteMessageRequest.builder()
                .queueUrl(queueUrl)
                .receiptHandle(message.receiptHandle())
                .build());
        log.debug("Deleted message {}", message.messageId());
    }
}
