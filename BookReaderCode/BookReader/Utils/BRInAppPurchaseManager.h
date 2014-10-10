//
//  InAppPurchaseManager.h
//  ABCD Buddy
//
//  Created by Gauri Tikekar on 9/9/13.
//
//

#import <Foundation/Foundation.h>

#import <StoreKit/StoreKit.h>
typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface BRInAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

- (id) initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void) requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
// Add two new method declarations
- (void) buyProduct:(SKProduct *)product;
- (BOOL) isProductPurchased:(NSString *)productIdentifier;
- (void) restoreCompletedTransactions;
@end

