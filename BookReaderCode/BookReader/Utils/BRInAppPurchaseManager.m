//
//  InAppPurchaseManager.m
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 9/9/13.
//
//

#import "BRInAppPurchaseManager.h"
#import <StoreKit/StoreKit.h>
#import "DPConstants.h"

// 2
@interface BRInAppPurchaseManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation BRInAppPurchaseManager {
    // 3
    SKProductsRequest * _productsRequest;
    // 4
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}

- (id) initWithProductIdentifiers:(NSSet *)productIdentifiers {
    if ((self = [super init])) {
        _productIdentifiers = productIdentifiers;
         [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void) requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    // 1
    _completionHandler = [completionHandler copy];

    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

#pragma mark - SKProductsRequestDelegate

- (void) productsRequest:(SKProductsRequest *) request didReceiveResponse:(SKProductsResponse *) response {
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;

    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }

    _completionHandler(YES, skProducts);
    _completionHandler = nil;
}

- (void) request:(SKRequest *) request didFailWithError:(NSError *)error {
    NSLog(@"Failed to load list of products.");
    _productsRequest = nil;

    _completionHandler(NO, nil);
    _completionHandler = nil;
}

- (BOOL) isProductPurchased:(NSString *) productIdentifier {
    NSLog(@"productPurchased");
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}


- (void) buyProduct:(SKProduct *) product {
    if (product == nil) {
        return;
    }
    NSLog(@"Buying %@...", product.productIdentifier);

    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) paymentQueue:(SKPaymentQueue *) queue updatedTransactions:(NSArray *) transactions {
    NSLog(@"paymentQueue updatedTransactions");
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");

    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");

    [_purchasedProductIdentifiers addObject:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void) failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) provideContentForProductIdentifier:(NSString *)productIdentifier {
    NSLog(@"provideContentForProductIdentifier...");
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSNotificationCenter defaultCenter] postNotificationName:INAPP_PRODUCT_PURCHASED_NOTIFICATION object:productIdentifier userInfo:nil];
}

- (void) restoreCompletedTransactions {
    NSLog(@"restoreCompletedTransactions...");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

// When restore of all purchased products is completed, then this delegate Funtion Will be fired
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
     NSMutableArray *purchasedItemIDs = [[NSMutableArray alloc] init];

    NSLog(@"received restored transactions: %i", (uint) queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions) {
        NSString *productID = transaction.payment.productIdentifier;
        [purchasedItemIDs addObject:productID];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PURCHASED_PRODUCTS_RESTORED_NOTIFICATION object:purchasedItemIDs userInfo:nil];
    
}

@end