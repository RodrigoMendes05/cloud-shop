package pt.ulusofona.orderservice.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

/**
 * Publishes order events to the AWS SQS queue.
 *
 * <p>Uses the AWS SDK v2 SqsClient configured in {@link SqsConfig}.
 * If SQS is disabled (local/test profile), the publish is silently skipped.
 */
@Slf4j
@Component
public class SqsPublisher {

    private final SqsClient sqsClient;
    private final String queueUrl;
    private final ObjectMapper objectMapper;
    private final boolean enabled;

    public SqsPublisher(
            SqsClient sqsClient,
            @Value("${aws.sqs.queue-url:disabled}") String queueUrl) {
        this.sqsClient = sqsClient;
        this.queueUrl = queueUrl;
        this.enabled = !"disabled".equals(queueUrl);
        this.objectMapper = new ObjectMapper()
                .registerModule(new JavaTimeModule());
    }

    /**
     * Sends an event object as a JSON message to SQS.
     *
     * @param event  any serialisable event object
     * @param eventType  label used in logs (e.g. "OrderCreatedEvent")
     */
    public void publish(Object event, String eventType) {
        if (!enabled) {
            log.debug("SQS disabled — skipping publish of {}", eventType);
            return;
        }
        try {
            String body = objectMapper.writeValueAsString(event);
            SendMessageRequest request = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(body)
                    .messageGroupId(eventType) // necessário se a queue for FIFO; ignorado em Standard
                    .build();
            var result = sqsClient.sendMessage(request);
            log.info("Published {} to SQS — messageId={}", eventType, result.messageId());
        } catch (JsonProcessingException e) {
            log.error("Failed to serialise {} for SQS", eventType, e);
        } catch (Exception e) {
            log.error("Failed to send {} to SQS", eventType, e);
            // Não propaga — a order já foi guardada na DB; o evento é best-effort
        }
    }
}
