//
//  SubscriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 16/09/2024.
//

import SwiftUI
import StoreKit
import addy_shared



struct ManageSubscriptionView: View {
    @StateObject private var storeManager = StoreManager()
    @State private var showPaymentStatusAlert = false
    @State private var paymentStatusMessage = ""
    @State private var paymentStatusTitle = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Binding var horizontalSize: UserInterfaceSizeClass

    let productIds = [
        "host.stjin.addy.subscription.pro.annually",
        "host.stjin.addy.subscription.pro.monthly",
        "host.stjin.addy.subscription.lite.annually",
        "host.stjin.addy.subscription.lite.monthly"
    ]
    
    @State private var selectedTab = "annually"
    @Environment(\.dismiss) var dismiss


        var body: some View {
            
            ZStack {
                if mainViewState.userResource!.subscription_type == "apple" || mainViewState.userResource!.subscription_type == nil {
                    // Only show the subscription options if the user does not have a subscription yet or if the current subscription is managed by apple
                    VStack {
                        // Tab Selection
                        Picker(String(localized: "subscription"), selection: $selectedTab) {
                            Text(String(localized: "annually")).tag("annually")
                            Text(String(localized: "monthly")).tag("monthly")
                        }.onChange(of: selectedTab) {
                            Task {
                                let productIds = productIds.filter { $0.hasSuffix(selectedTab) }
                                await storeManager.fetchProducts(productIdentifiers: productIds)
                            }
                        }

                        .pickerStyle(SegmentedPickerStyle())
                        .padding()

                        // Product Display with Gradient Button
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(storeManager.products, id: \.self) { product in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(product.displayName)
                                            .font(.title2)
                                            .bold()
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(product.displayPrice)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Button(action: {
                                            purchase(product)
                                        }) {
                                            Text(String(localized: "subscribe_now"))
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(LinearGradient(gradient: Gradient(colors: [Color("AddySecondaryColor"), Color("AccentColor")]), startPoint: .leading, endPoint: .trailing))
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(15)
                                }
                            }
                            .padding()
                        }

                        // Feature Overview
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "why_subscribe"))
                                .font(.headline)
                            ForEach([String(localized: "why_subscribe_reason_1"), String(localized: "why_subscribe_reason_2"), String(localized: "why_subscribe_reason_3"), String(localized: "why_subscribe_reason_4")], id: \.self) { feature in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accent)
                                    Text(feature)
                                }
                            }
                        }
                        .padding()

                        // Restore Purchases Button
                        Button(action: {
                            restorePurchases()
                        }) {
                            Text(String(localized:"restore_purchases"))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.bottom)
                    }
                    } else {
                        // If the user is subscribed but NOT through the App Store
                        ContentUnavailableView {
                            Label(String(localized: "subscription_other_platform_title"), systemImage: "creditcard.fill")
                        } description: {
                            Text(String(localized: "subscription_other_platform_title_desc"))
                        }

                    }


            }
            .navigationTitle(String(localized: "manage_subscription"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem() {
                        Button {
                            dismiss()
                        } label: {
                            Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                        }
                        
                    }
                })
            .task{
                let productIds = productIds.filter { $0.hasSuffix(selectedTab) }
                await storeManager.fetchProducts(productIdentifiers: productIds) // Assuming identifiers for demonstration
                await listenForTransactions()
            }
            .alert(isPresented: $showPaymentStatusAlert) {
                Alert(
                    title: Text(paymentStatusTitle),
                    message: Text(paymentStatusMessage)
                )
            }
        }
    
    func purchase(_ product: Product) {
        Task {
            do {
                let result = try await storeManager.purchase(product)
                switch result {
                case .success(let verificationResult):
                    await handleTransaction(verificationResult)
                case .userCancelled:
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: "User cancelled the purchase",
                        method: "purchase",
                        extra: nil)
                case .pending:
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: "The purchase is pending",
                        method: "purchase",
                        extra: nil)
                @unknown default:
                    LoggingHelper().addLog(
                        importance: LogImportance.critical,
                        error: "Unknown result from purchasing",
                        method: "purchase",
                        extra: nil)
                }
            } catch {
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: "Failed to purchase",
                    method: "purchase",
                    extra: error.localizedDescription)
            }
        }
    }
    
    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                checkSubscriptionStatus()
            } catch {
                LoggingHelper().addLog(
                    importance: LogImportance.critical,
                    error: "Failed to restore transactions",
                    method: "restorePurchases",
                    extra: error.localizedDescription)
                
                paymentStatusTitle = String(localized: "failed_to_restore_transactions")
                paymentStatusMessage = error.localizedDescription
                showPaymentStatusAlert = true
            }
        }
    }
    
    func checkSubscriptionStatus() {
        Task {
            // Get all transactions for the user
            for await transaction in Transaction.currentEntitlements {
                // Check if the transaction is for a subscription
                if case .verified(let transaction) = transaction {
                    if transaction.productType == .autoRenewable {
                        await notifyInstanceAboutSubscription(transaction: transaction)
                    }
                }
            }
            
        }
    }
    
    func handleTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        
        do {
            let transaction = try checkVerified(result)
            await notifyInstanceAboutSubscription(transaction: transaction)
        } catch {
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Transaction verification or handling failed",
                method: "handleTransaction",
                extra: error.localizedDescription)
        }
    }
    
    func notifyInstanceAboutSubscription(transaction: StoreKit.Transaction) async {
        do {
            await transaction.finish()
            
            let userResource = try await NetworkHelper().notifyServerForSubscriptionChange(transactionId: String(transaction.id), productId: transaction.productID)
            if let userResource = userResource {
                mainViewState.userResource = userResource
                mainViewState.isPresentingSubscriptionSheet = false
            } else {
                paymentStatusTitle = String(localized: "subscription_processing_failed")
                paymentStatusMessage = String(format: String(localized: "subscription_processing_failed_desc"), mainViewState.userResource!.id, String(transaction.id), transaction.productID)
                showPaymentStatusAlert = true
            }
        } catch {
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Transaction verification or handling failed",
                method: "handleTransaction",
                extra: error.localizedDescription)
            
            paymentStatusTitle = String(localized: "subscription_processing_failed")
            paymentStatusMessage = String(format: String(localized: "subscription_processing_failed_desc"), mainViewState.userResource!.id, String(transaction.id), transaction.productID)
            showPaymentStatusAlert = true
        }
    }
    
    func checkForSubscriptionFromOtherPlatform(){
        
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(let unverified, let verificationError):
            throw verificationError
        }
    }
    
    func listenForTransactions() async {
        for await update in Transaction.updates {
            await handleTransaction(update)
        }
    }
}

class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    
    func fetchProducts(productIdentifiers: [String]) async {
        do {
            let fetchedProducts = try await Product.products(for: productIdentifiers)
            DispatchQueue.main.async {
                self.products = fetchedProducts.sorted { $0.price > $1.price }
            }
        } catch {
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Error fetching products",
                method: "fetchProducts",
                extra: error.localizedDescription)
        }
    }
    
    func purchase(_ product: Product) async throws -> Product.PurchaseResult {
        return try await product.purchase()
    }
}
