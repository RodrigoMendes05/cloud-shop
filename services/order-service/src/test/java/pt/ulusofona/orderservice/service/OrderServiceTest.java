package pt.ulusofona.orderservice.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import pt.ulusofona.orderservice.client.ProductResponse;
import pt.ulusofona.orderservice.client.ProductServiceClient;
import pt.ulusofona.orderservice.client.UserResponse;
import pt.ulusofona.orderservice.client.UserServiceClient;
import pt.ulusofona.orderservice.dto.OrderItemRequest;
import pt.ulusofona.orderservice.dto.OrderRequest;
import pt.ulusofona.orderservice.dto.OrderResponse;
import pt.ulusofona.orderservice.messaging.SqsPublisher;
import pt.ulusofona.orderservice.model.Order;
import pt.ulusofona.orderservice.model.OrderItem;
import pt.ulusofona.orderservice.model.OrderStatus;
import pt.ulusofona.orderservice.repository.OrderRepository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private UserServiceClient userServiceClient;

    @Mock
    private ProductServiceClient productServiceClient;

    @Mock
    private SqsPublisher sqsPublisher;   // substituiu KafkaTemplate

    @InjectMocks
    private OrderService orderService;

    private UserResponse mockUser;
    private ProductResponse mockProduct;
    private Order mockOrder;

    @BeforeEach
    void setUp() {
        mockUser = new UserResponse();
        mockUser.setId(1L);
        mockUser.setName("Test User");
        mockUser.setEmail("test@example.com");

        mockProduct = new ProductResponse();
        mockProduct.setId(1L);
        mockProduct.setName("Test Product");
        mockProduct.setPrice(new BigDecimal("29.99"));
        mockProduct.setStockQuantity(10);

        mockOrder = new Order();
        mockOrder.setId(1L);
        mockOrder.setUserId(1L);
        mockOrder.setStatus(OrderStatus.PENDING);
        mockOrder.setCreatedAt(LocalDateTime.now());
        mockOrder.setUpdatedAt(LocalDateTime.now());

        OrderItem mockItem = new OrderItem();
        mockItem.setId(1L);
        mockItem.setProductId(1L);
        mockItem.setProductName("Test Product");
        mockItem.setQuantity(2);
        mockItem.setPrice(new BigDecimal("29.99"));
        mockOrder.addOrderItem(mockItem);
        mockOrder.calculateTotal();
    }

    @Test
    void createOrder_success() {
        when(userServiceClient.getUserById(1L)).thenReturn(mockUser);
        when(productServiceClient.getProductById(1L)).thenReturn(mockProduct);
        when(orderRepository.save(any(Order.class))).thenReturn(mockOrder);

        OrderItemRequest itemRequest = new OrderItemRequest();
        itemRequest.setProductId(1L);
        itemRequest.setQuantity(2);

        OrderRequest request = new OrderRequest();
        request.setUserId(1L);
        request.setItems(Arrays.asList(itemRequest));

        OrderResponse response = orderService.createOrder(request);

        assertNotNull(response);
        assertEquals(1L, response.getId());
        // Verifica que o publisher foi chamado (substitui verificação do kafkaTemplate.send)
        verify(sqsPublisher).publish(any(), eq("OrderCreatedEvent"));
    }

    @Test
    void createOrder_userNotFound_throwsException() {
        when(userServiceClient.getUserById(1L)).thenThrow(new RuntimeException("User not found"));

        OrderItemRequest itemRequest = new OrderItemRequest();
        itemRequest.setProductId(1L);
        itemRequest.setQuantity(1);

        OrderRequest request = new OrderRequest();
        request.setUserId(1L);
        request.setItems(Arrays.asList(itemRequest));

        assertThrows(RuntimeException.class, () -> orderService.createOrder(request));
        verify(sqsPublisher, never()).publish(any(), any());
    }

    @Test
    void createOrder_productNotFound_throwsException() {
        when(userServiceClient.getUserById(1L)).thenReturn(mockUser);
        when(productServiceClient.getProductById(1L)).thenThrow(new RuntimeException("Product not found"));

        OrderItemRequest itemRequest = new OrderItemRequest();
        itemRequest.setProductId(1L);
        itemRequest.setQuantity(1);

        OrderRequest request = new OrderRequest();
        request.setUserId(1L);
        request.setItems(Arrays.asList(itemRequest));

        assertThrows(RuntimeException.class, () -> orderService.createOrder(request));
        verify(sqsPublisher, never()).publish(any(), any());
    }

    @Test
    void createOrder_insufficientStock_throwsException() {
        mockProduct.setStockQuantity(1);
        when(userServiceClient.getUserById(1L)).thenReturn(mockUser);
        when(productServiceClient.getProductById(1L)).thenReturn(mockProduct);

        OrderItemRequest itemRequest = new OrderItemRequest();
        itemRequest.setProductId(1L);
        itemRequest.setQuantity(5);

        OrderRequest request = new OrderRequest();
        request.setUserId(1L);
        request.setItems(Arrays.asList(itemRequest));

        assertThrows(RuntimeException.class, () -> orderService.createOrder(request));
        verify(sqsPublisher, never()).publish(any(), any());
    }

    @Test
    void getAllOrders_returnsList() {
        when(orderRepository.findAll()).thenReturn(Arrays.asList(mockOrder));

        List<OrderResponse> orders = orderService.getAllOrders();

        assertEquals(1, orders.size());
        verify(orderRepository).findAll();
    }

    @Test
    void getOrderById_success() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(mockOrder));

        OrderResponse response = orderService.getOrderById(1L);

        assertNotNull(response);
        assertEquals(1L, response.getId());
    }

    @Test
    void getOrderById_notFound_throwsException() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> orderService.getOrderById(99L));
    }

    @Test
    void updateOrderStatus_success() {
        when(orderRepository.findById(1L)).thenReturn(Optional.of(mockOrder));
        when(orderRepository.save(any(Order.class))).thenReturn(mockOrder);

        OrderResponse response = orderService.updateOrderStatus(1L, OrderStatus.CONFIRMED);

        assertNotNull(response);
        verify(sqsPublisher).publish(any(), eq("OrderStatusChangedEvent"));
    }
}
