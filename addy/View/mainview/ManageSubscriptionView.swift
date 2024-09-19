//
//  SubscriptionBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 16/09/2024.
//

import SwiftUI
import StoreKit
import addy_shared


struct InfiniteMarquee: View {
    let items: [String]
    @State private var scrollOffset: CGFloat = 0
    private let scrollSpeed: CGFloat = 0.5 // Pixels per frame, adjust this for speed
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accent)
                            Text(item)
                                .font(.headline)
                        }
                    }
                }
                .offset(x: scrollOffset)
            }
            .onAppear {
                startScrolling(in: geometry.size.width)
            }
        }
    }

    func startScrolling(in width: CGFloat) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            withAnimation(.linear(duration: 1.0 / 60.0)) {
                let contentWidth = width * CGFloat(items.count)
                if -scrollOffset > contentWidth {
                    // Reset to start when we've scrolled past the duplicated content
                    scrollOffset = 0
                } else {
                    scrollOffset -= scrollSpeed
                }
            }
        }
        // Keep the timer alive for the lifecycle of the view
        RunLoop.current.add(timer, forMode: .common)
    }
}


class ReceiptManager: NSObject, SKRequestDelegate {
    var completion: ((Result<Void, Error>) -> Void)?

    func refreshReceipt(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }

    func requestDidFinish(_ request: SKRequest) {
        if request is SKReceiptRefreshRequest {
            // Handle successful receipt refresh
            
            LoggingHelper().addLog(
                importance: .info,
                error: "Recent receipt successfully refreshed",
                method: "request",
                extra: nil)
            
            completion?(.success(()))
            request.cancel()
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKReceiptRefreshRequest {
            // Handle failed receipt refresh
            
            LoggingHelper().addLog(
                importance: .critical,
                error: "Receipt refresh failed",
                method: "request",
                extra: error.localizedDescription)
            
            completion?(.failure(error))
            request.cancel()
        }
    }
}


struct ManageSubscriptionView: View {
    @StateObject private var storeManager = StoreManager()
    @State private var showPaymentStatusAlert = false
    @State private var paymentStatusMessage = ""
    @State private var paymentStatusTitle = ""
    @EnvironmentObject var mainViewState: MainViewState
    @Binding var horizontalSize: UserInterfaceSizeClass
    @Binding var shouldHideNavigationBarBackButtonSubscriptionView: Bool
    @State private var isPresentedManageSubscription = false
    @State private var isNotifyingServer = false
    @State private var purchasedItem: StoreKit.Transaction? = nil

    let productIds = [
        "pro_yearly",
        "pro_monthly",
        "lite_yearly",
    ]
    
    @State private var selectedTab = "yearly"
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL


        var body: some View {
            
            ZStack {
                if isNotifyingServer {
                    ContentUnavailableView {
                                // Label - typically an image or icon
                        Label(String(localized: "activating_subscription"), systemImage: "hourglass")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.accentColor)
                                
                                // Primary action or additional description
                                Text(String(localized: "activating_subscription_desc"))
                                    .font(.subheadline)
                                
                                // Here's where you add the ProgressView
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.top, 10)
                                
                            } description: {
                                // Optional: Additional description if needed
                                Text(String(localized: "this_might_take_a_few_moments"))
                            }
                            .padding()
                } else {
                    if mainViewState.userResource!.subscription_type == "apple" || mainViewState.userResource!.subscription_type == nil {
                        // Only show the subscription options if the user does not have a subscription yet or if the current subscription is managed by apple
                        VStack {
                            // Tab Selection
                            Picker(String(localized: "subscription"), selection: $selectedTab) {
                                Text(String(localized: "annually")).tag("yearly")
                                Text(String(localized: "monthly")).tag("monthly")
                            }.onChange(of: selectedTab) {
                                Task {
                                    let productIds = productIds.filter { $0.hasSuffix(selectedTab) }
                                    await storeManager.fetchProducts(productIdentifiers: productIds)
                                }
                            }
                            
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            
                            if storeManager.products.isEmpty {
                                VStack {
                                    ProgressView()
                                }.frame(maxHeight: .infinity)
                            } else {
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
                                                    Text((purchasedItem?.productID ?? "" == product.id) ? String(localized: "active") : String(localized: "subscribe_now"))
                                                        .frame(maxWidth: .infinity)
                                                        .padding()
                                                        .background((purchasedItem?.productID ?? "" == product.id) ? LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [Color("AddySecondaryColor"), Color("AccentColor")]), startPoint: .leading, endPoint: .trailing))
                                                        .foregroundColor(.white)
                                                        .cornerRadius(10)
                                                }.disabled((purchasedItem?.productID ?? "") == product.id)
                                            }
                                            .padding()
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .cornerRadius(15)
                                        }
                                    }
                                    .padding()
                                }
                            }

                            
                            VStack {
                                // Feature Overview
                                InfiniteMarquee(items: [
                                    String(localized: "why_subscribe_reason_1"),
                                    String(localized: "why_subscribe_reason_2"),
                                    String(localized: "why_subscribe_reason_3"),
                                    String(localized: "why_subscribe_reason_4"),
                                    String(localized: "why_subscribe_reason_5"),
                                    String(localized: "why_subscribe_reason_6"),
                                    String(localized: "why_subscribe_reason_7"),
                                    String(localized: "why_subscribe_reason_8"),
                                ])
                                .frame(height: 30)
                                .padding(.top)
                                
                                VStack(alignment: .center, spacing: 10) {
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
                                    
                                    Button(action: {
                                        isPresentedManageSubscription = true
                                    }) {
                                        Text(String(localized:"manage_subscription"))
                                    }
                                    .padding(.bottom)
                                    
                                    HStack {
                                        Spacer()

                                        Button(action: {
                                            openURL(URL(string: "https://addy.io/privacy")!)
                                        }) {
                                            Text(String(localized:"privacy_policy"))
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            openURL(URL(string: "https://addy.io/terms")!)
                                        }) {
                                            Text(String(localized:"terms_of_service"))
                                        }
                                        Spacer()

                                    }
                                    .padding(.bottom)

                                }
                            }.background(.gray.opacity(0.1))
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

            }
            .manageSubscriptionsSheet(isPresented: $isPresentedManageSubscription)
            .apply{
                if isNotifyingServer {
                    $0
                } else {
                    $0.navigationTitle(String(localized: "manage_subscription"))
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
                }
            }
            .task{
                let productIds = productIds.filter { $0.hasSuffix(selectedTab) }
                await storeManager.fetchProducts(productIdentifiers: productIds)
                await getPurchasedItem()
            }
            .alert(isPresented: $showPaymentStatusAlert) {
                Alert(
                    title: Text(paymentStatusTitle),
                    message: Text(paymentStatusMessage)
                )
            }
        }
    
    
    private func purchase(_ product: Product) {
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
    
    private func restorePurchases() {
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
    
    private func checkSubscriptionStatus() {
        Task {
            // Get all transactions for the user
            for await transaction in Transaction.currentEntitlements {
                // Check if the transaction is for a subscription
                if case .verified(let transaction) = transaction {
                    if transaction.productType == .autoRenewable {
                        await notifyInstanceAboutSubscription(transaction: transaction, completion: {_ in 
                            // No action is required since no new transaction has been made
                        })
                    }
                }
            }
            
        }
    }
    
    private func getPurchasedItem() async {
        
        // Fetch all transactions
        var allTransactions = [StoreKit.Transaction]()
        for await transaction in Transaction.currentEntitlements {
            if case .verified(let verifiedTransaction) = transaction,
               verifiedTransaction.productType == .autoRenewable {
                
                if let expirationDate = verifiedTransaction.expirationDate,
                   expirationDate > Date.now {
                    allTransactions.append(verifiedTransaction)
                }
                
            }
        }

        // Sort transactions by purchase date or expiration date if available
        // Assuming there's a date property like 'purchaseDate' or 'expirationDate'
        let sortedTransactions = allTransactions.sorted { $0.purchaseDate > $1.purchaseDate }

        // Get the last transaction
        if let lastTransaction = sortedTransactions.first {
            purchasedItem = lastTransaction
        } else {
            LoggingHelper().addLog(
                importance: LogImportance.warning,
                error: "No valid subscription transactions found.",
                method: "getPurchasedItem",
                extra: nil)
        }
    }
    
    private func handleTransaction(_ result: VerificationResult<StoreKit.Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await notifyInstanceAboutSubscription(transaction: transaction) { succeeded in
                Task {
                    if succeeded {
                        await transaction.finish()
                    } else {
                        // There is not much we can do, we have to finish the transaction regardless
                        await transaction.finish()
                    }
                }
            }
        } catch {
            LoggingHelper().addLog(
                importance: LogImportance.critical,
                error: "Transaction verification or handling failed",
                method: "handleTransaction",
                extra: error.localizedDescription)
        }
    }
       
    
    
    // Refresh the receipt before fetching it, once refreshed, fetch and return
    private func fetchReceipt() async -> String? {
        let receiptManager = ReceiptManager()

        return await withCheckedContinuation { continuation in
            receiptManager.refreshReceipt { result in
                switch result {
                case .success:
                    // Get the receipt if it's available.
                    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                       FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

                        do {
                            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                            let receiptString = receiptData.base64EncodedString(options: [])
                            continuation.resume(returning: receiptString)
                        } catch {
                            LoggingHelper().addLog(
                                importance: .critical,
                                error: "Couldn't read receipt data with error:",
                                method: "fetchReceipt",
                                extra: error.localizedDescription)
                            continuation.resume(returning: nil)
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(let error):
                    LoggingHelper().addLog(
                        importance: .critical,
                        error: "Failure while refreshing receipts",
                        method: "fetchReceipt",
                        extra: error.localizedDescription)
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func notifyInstanceAboutSubscription(transaction: StoreKit.Transaction, completion: @escaping (Bool) -> Void) async {
        shouldHideNavigationBarBackButtonSubscriptionView = true
        isNotifyingServer = true

        do {
            if let receiptData = await fetchReceipt() {
                let userResource = try await NetworkHelper().notifyServerForSubscriptionChange(receipt: receiptData)
                if let userResource = userResource {
                    mainViewState.userResource = userResource
                    mainViewState.isPresentingProfileBottomSheet = false
                    shouldHideNavigationBarBackButtonSubscriptionView = false
                    isNotifyingServer = false
                    completion(true)
                } else {
                    paymentStatusTitle = String(localized: "subscription_processing_failed")
                    paymentStatusMessage = String(format: String(localized: "subscription_processing_failed_desc"), mainViewState.userResource!.id, String(transaction.id), transaction.productID)
                    showPaymentStatusAlert = true
                    shouldHideNavigationBarBackButtonSubscriptionView = false
                    isNotifyingServer = false
                    completion(false)
                }
            } else {
                paymentStatusTitle = String(localized: "could_not_obtain_receipt")
                paymentStatusMessage = String(format: String(localized: "could_not_obtain_receipt_desc"), mainViewState.userResource!.id, String(transaction.id), transaction.productID)
                showPaymentStatusAlert = true
                shouldHideNavigationBarBackButtonSubscriptionView = false
                isNotifyingServer = false
                completion(false)

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
            shouldHideNavigationBarBackButtonSubscriptionView = false
            isNotifyingServer = false
            completion(false)
        }
    }

    
    
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(let unverified, let verificationError):
            throw verificationError
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
