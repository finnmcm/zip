#!/usr/bin/env -S deno run --allow-net --allow-env

/**
 * Webhook Testing Script for Stripe Webhook Functions
 * 
 * This script provides comprehensive testing of the webhook functions
 * by simulating various Stripe events and verifying the responses.
 * 
 * Usage:
 *   deno run --allow-net --allow-env test-webhook.ts
 *   deno run --allow-net --allow-env test-webhook.ts --event=payment_intent.succeeded
 *   deno run --allow-net --allow-env test-webhook.ts --local
 */

interface TestEvent {
  type: string;
  description: string;
  data: any;
  expectedStatus: number;
  expectedResponse: any;
}

interface TestResult {
  event: string;
  success: boolean;
  status: number;
  response: any;
  error?: string;
  duration: number;
}

class WebhookTester {
  private baseUrl: string;
  private authToken: string;
  private testResults: TestResult[] = [];

  constructor() {
    // Get configuration from environment or use defaults
    this.baseUrl = Deno.env.get("WEBHOOK_URL") || "http://127.0.0.1:54321/functions/v1/stripe-webhook";
    this.authToken = Deno.env.get("SUPABASE_ANON_KEY") || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0";
  }

  /**
   * Generate test events for various Stripe webhook scenarios
   */
  private generateTestEvents(): TestEvent[] {
    const testOrderId = "550e8400-e29b-41d4-a716-446655440000";
    const testPaymentIntentId = "pi_test_1234567890";
    const testChargeId = "ch_test_1234567890";
    const testInvoiceId = "in_test_1234567890";

    return [
      // Payment Intent Events
      {
        type: "payment_intent.succeeded",
        description: "Payment completed successfully",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "payment_intent.payment_failed",
        description: "Payment failed",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "payment_failed",
            last_payment_error: {
              message: "Your card was declined."
            },
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "payment_intent.canceled",
        description: "Payment canceled",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "canceled",
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "payment_intent.processing",
        description: "Payment processing",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "processing",
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "payment_intent.requires_action",
        description: "Payment requires action",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "requires_action",
            next_action: {
              type: "use_stripe_sdk"
            },
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },

      // Charge Events
      {
        type: "charge.succeeded",
        description: "Charge completed successfully",
        data: {
          object: {
            id: testChargeId,
            object: "charge",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            payment_intent: testPaymentIntentId,
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "charge.failed",
        description: "Charge failed",
        data: {
          object: {
            id: testChargeId,
            object: "charge",
            amount: 2000,
            currency: "usd",
            status: "failed",
            failure_message: "Your card was declined.",
            payment_intent: testPaymentIntentId,
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "charge.refunded",
        description: "Charge refunded",
        data: {
          object: {
            id: testChargeId,
            object: "charge",
            amount: 2000,
            amount_refunded: 2000,
            currency: "usd",
            status: "succeeded",
            payment_intent: testPaymentIntentId,
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "charge.dispute.created",
        description: "Dispute created",
        data: {
          object: {
            id: testChargeId,
            object: "charge",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            payment_intent: testPaymentIntentId,
            dispute: {
              status: "needs_response"
            },
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "charge.dispute.closed",
        description: "Dispute resolved",
        data: {
          object: {
            id: testChargeId,
            object: "charge",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            payment_intent: testPaymentIntentId,
            dispute: {
              status: "won"
            },
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },

      // Invoice Events
      {
        type: "invoice.payment_succeeded",
        description: "Invoice payment succeeded",
        data: {
          object: {
            id: testInvoiceId,
            object: "invoice",
            amount_paid: 2000,
            currency: "usd",
            status: "paid",
            payment_intent: testPaymentIntentId,
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "invoice.payment_failed",
        description: "Invoice payment failed",
        data: {
          object: {
            id: testInvoiceId,
            object: "invoice",
            amount_due: 2000,
            currency: "usd",
            status: "open",
            payment_intent: testPaymentIntentId,
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },

      // Refund Events
      {
        type: "charge.refund.updated",
        description: "Refund updated",
        data: {
          object: {
            id: "re_test_1234567890",
            object: "refund",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            reason: "requested_by_customer",
            metadata: {
              order_id: testOrderId,
              user_id: "user_test_123"
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },

      // Subscription Events
      {
        type: "customer.subscription.deleted",
        description: "Subscription deleted",
        data: {
          object: {
            id: "sub_test_1234567890",
            object: "subscription",
            status: "canceled",
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },

      // Edge Cases
      {
        type: "payment_intent.succeeded",
        description: "Missing order_id metadata",
        data: {
          object: {
            id: testPaymentIntentId,
            object: "payment_intent",
            amount: 2000,
            currency: "usd",
            status: "succeeded",
            metadata: {
              user_id: "user_test_123"
              // Missing order_id
            },
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      },
      {
        type: "unknown.event.type",
        description: "Unknown event type",
        data: {
          object: {
            id: "evt_test_1234567890",
            object: "event",
            created: Math.floor(Date.now() / 1000)
          }
        },
        expectedStatus: 200,
        expectedResponse: { received: true, processed: true }
      }
    ];
  }

  /**
   * Test a single webhook event
   */
  private async testEvent(event: TestEvent): Promise<TestResult> {
    const startTime = Date.now();
    
    try {
      console.log(`🔄 Testing: ${event.type} - ${event.description}`);
      
      const response = await fetch(this.baseUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${this.authToken}`,
          "stripe-signature": this.generateMockSignature(event)
        },
        body: JSON.stringify(event)
      });

      const responseText = await response.text();
      let responseData;
      
      try {
        responseData = JSON.parse(responseText);
      } catch {
        responseData = { raw: responseText };
      }

      const duration = Date.now() - startTime;
      
      const result: TestResult = {
        event: event.type,
        success: response.status === event.expectedStatus,
        status: response.status,
        response: responseData,
        duration
      };

      if (response.status !== event.expectedStatus) {
        result.error = `Expected status ${event.expectedStatus}, got ${response.status}`;
      }

      return result;

    } catch (error) {
      const duration = Date.now() - startTime;
      return {
        event: event.type,
        success: false,
        status: 0,
        response: {},
        error: error.message,
        duration
      };
    }
  }

  /**
   * Generate a mock Stripe signature for testing
   * Note: This won't pass real signature verification, but allows testing the event processing logic
   */
  private generateMockSignature(event: TestEvent): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const payload = `${timestamp}.${JSON.stringify(event)}`;
    const signature = `t=${timestamp},v1=mock_signature_${btoa(payload).substring(0, 20)}`;
    return signature;
  }

  /**
   * Run all tests
   */
  async runAllTests(): Promise<void> {
    console.log("🚀 Starting Webhook Function Tests");
    console.log(`📍 Testing endpoint: ${this.baseUrl}`);
    console.log("=" * 60);

    const events = this.generateTestEvents();
    
    for (const event of events) {
      const result = await this.testEvent(event);
      this.testResults.push(result);
      
      // Add delay between tests to avoid overwhelming the endpoint
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    this.printResults();
  }

  /**
   * Test a specific event type
   */
  async testSpecificEvent(eventType: string): Promise<void> {
    console.log(`🎯 Testing specific event: ${eventType}`);
    
    const events = this.generateTestEvents();
    const event = events.find(e => e.type === eventType);
    
    if (!event) {
      console.error(`❌ Event type '${eventType}' not found in test events`);
      return;
    }

    const result = await this.testEvent(event);
    this.testResults = [result];
    this.printResults();
  }

  /**
   * Print test results summary
   */
  private printResults(): void {
    console.log("\n" + "=" * 60);
    console.log("📊 Test Results Summary");
    console.log("=" * 60);

    const total = this.testResults.length;
    const passed = this.testResults.filter(r => r.success).length;
    const failed = total - passed;
    const avgDuration = this.testResults.reduce((sum, r) => sum + r.duration, 0) / total;

    console.log(`✅ Passed: ${passed}`);
    console.log(`❌ Failed: ${failed}`);
    console.log(`📈 Success Rate: ${((passed / total) * 100).toFixed(1)}%`);
    console.log(`⏱️  Average Duration: ${avgDuration.toFixed(0)}ms`);

    if (failed > 0) {
      console.log("\n❌ Failed Tests:");
      this.testResults
        .filter(r => !r.success)
        .forEach(r => {
          console.log(`   - ${r.event}: ${r.error || `Status ${r.status}`}`);
        });
    }

    console.log("\n📋 Detailed Results:");
    this.testResults.forEach(result => {
      const status = result.success ? "✅" : "❌";
      const duration = `${result.duration}ms`;
      console.log(`   ${status} ${result.event} (${duration})`);
      
      if (!result.success && result.error) {
        console.log(`      Error: ${result.error}`);
      }
    });

    console.log("\n" + "=" * 60);
  }

  /**
   * Test webhook health/connectivity
   */
  async testHealth(): Promise<void> {
    console.log("🏥 Testing webhook health...");
    
    try {
      const response = await fetch(this.baseUrl, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${this.authToken}`
        }
      });

      if (response.status === 405) {
        console.log("✅ Health check: Method not allowed (expected for GET requests)");
      } else {
        console.log(`⚠️  Health check: Unexpected status ${response.status}`);
      }
    } catch (error) {
      console.error("❌ Health check failed:", error.message);
    }
  }
}

// Main execution
async function main() {
  const args = Deno.args;
  const tester = new WebhookTester();

  // Parse command line arguments
  const eventType = args.find(arg => arg.startsWith("--event="))?.split("=")[1];
  const isLocal = args.includes("--local");
  const healthCheck = args.includes("--health");

  if (healthCheck) {
    await tester.testHealth();
    return;
  }

  if (eventType) {
    await tester.testSpecificEvent(eventType);
  } else {
    await tester.runAllTests();
  }

  if (isLocal) {
    console.log("\n💡 Local testing mode - webhook signature verification will fail");
    console.log("   This is expected behavior for local testing without proper Stripe setup");
  }
}

// Run the main function
if (import.meta.main) {
  main().catch(console.error);
}
