package pt.ulusofona.orderservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;

/**
 * Configures the AWS SDK v2 SqsClient.
 *
 * <p>Uses DefaultCredentialsProvider — resolves credentials in this order:
 * <ol>
 *   <li>Environment variables (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)</li>
 *   <li>EC2 Instance Profile (usado em produção — IAM role no EC2)</li>
 *   <li>~/.aws/credentials (desenvolvimento local)</li>
 * </ol>
 *
 * <p>Nunca colocamos credenciais hardcoded aqui.
 */
@Configuration
public class SqsConfig {

    @Value("${aws.region:eu-central-1}")
    private String awsRegion;

    @Bean
    public SqsClient sqsClient() {
        return SqsClient.builder()
                .region(Region.of(awsRegion))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
