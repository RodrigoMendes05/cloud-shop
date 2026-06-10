package pt.ulusofona.notificationservice.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SqsConsumerTest {

    @Mock
    private SqsClient sqsClient;

    @Test
    void poll_doesNothing_whenDisabled() {
        SqsConsumer consumer = new SqsConsumer(sqsClient, "disabled");
        consumer.poll();
        verifyNoInteractions(sqsClient);
    }

    @Test
    void poll_deletesMessage_afterSuccessfulProcessing() {
        String queueUrl = "https://sqs.eu-central-1.amazonaws.com/123456789/shop-dev-orders";
        SqsConsumer consumer = new SqsConsumer(sqsClient, queueUrl);

        String body = """
                {
                  "orderId": 1,
                  "userId": 42,
                  "items": [{"productId": 1, "productName": "Widget", "quantity": 2, "price": 9.99}],
                  "totalAmount": 19.98,
                  "createdAt": "2024-01-15T10:00:00"
                }
                """;

        Message message = Message.builder()
                .messageId("msg-001")
                .receiptHandle("receipt-001")
                .body(body)
                .build();

        ReceiveMessageResponse receiveResponse = ReceiveMessageResponse.builder()
                .messages(List.of(message))
                .build();

        when(sqsClient.receiveMessage(any(ReceiveMessageRequest.class)))
                .thenReturn(receiveResponse);

        consumer.poll();

        ArgumentCaptor<DeleteMessageRequest> captor =
                ArgumentCaptor.forClass(DeleteMessageRequest.class);
        verify(sqsClient).deleteMessage(captor.capture());
        assertEquals("receipt-001", captor.getValue().receiptHandle());
    }

    @Test
    void poll_doesNotDelete_onProcessingFailure() {
        String queueUrl = "https://sqs.eu-central-1.amazonaws.com/123456789/shop-dev-orders";
        SqsConsumer consumer = new SqsConsumer(sqsClient, queueUrl);

        // Invalid JSON → Jackson will throw → message should NOT be deleted
        Message message = Message.builder()
                .messageId("msg-bad")
                .receiptHandle("receipt-bad")
                .body("not-valid-json")
                .build();

        ReceiveMessageResponse receiveResponse = ReceiveMessageResponse.builder()
                .messages(List.of(message))
                .build();

        when(sqsClient.receiveMessage(any(ReceiveMessageRequest.class)))
                .thenReturn(receiveResponse);

        consumer.poll();

        verify(sqsClient, never()).deleteMessage(any(DeleteMessageRequest.class));
    }

    @Test
    void poll_processesStatusChangedEvent() {
        String queueUrl = "https://sqs.eu-central-1.amazonaws.com/123456789/shop-dev-orders";
        SqsConsumer consumer = new SqsConsumer(sqsClient, queueUrl);

        String body = """
                {
                  "orderId": 5,
                  "userId": 7,
                  "previousStatus": "PENDING",
                  "newStatus": "CONFIRMED",
                  "changedAt": "2024-01-15T11:00:00"
                }
                """;

        Message message = Message.builder()
                .messageId("msg-002")
                .receiptHandle("receipt-002")
                .body(body)
                .build();

        when(sqsClient.receiveMessage(any(ReceiveMessageRequest.class)))
                .thenReturn(ReceiveMessageResponse.builder().messages(List.of(message)).build());

        consumer.poll();

        verify(sqsClient).deleteMessage(any(DeleteMessageRequest.class));
    }
}
