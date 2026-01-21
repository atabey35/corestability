// IAPManager.swift
// CoreStability
// Manages In-App Purchases using StoreKit

import StoreKit

enum IAPProduct: String, CaseIterable {
    case gems80 = "com.cagdasbertanisik.corestability.gems.80"
    case gems500 = "com.cagdasbertanisik.corestability.gems.500"
    case gems1200 = "com.cagdasbertanisik.corestability.gems.1200"
    case gems3500 = "com.cagdasbertanisik.corestability.gems.3500"
    case gems8000 = "com.cagdasbertanisik.corestability.gems.8000"
    case gems20000 = "com.cagdasbertanisik.corestability.gems.20000"
    // case removeAds removed
    case battlePass = "com.cagdasbertanisik.corestability.battlepass"
    
    // Weapon Rentals/Purchases
    case shotgunRental = "com.cagdasbertanisik.corestability.shotgun.rental.v2"
    case shotgunLifetime = "com.cagdasbertanisik.corestability.shotgun.lifetime"
    case railgunRental = "com.cagdasbertanisik.corestability.railgun.rental"
    case railgunLifetime = "com.cagdasbertanisik.corestability.railgun.lifetime"
    
    // Turret Slots
    case turretSlot1 = "com.cagdasbertanisik.corestability.turret.slot1"
    case turretSlot2 = "com.cagdasbertanisik.corestability.turret.slot2"
    case turretSlot3 = "com.cagdasbertanisik.corestability.turret.slot3"
    case turretSlot4 = "com.cagdasbertanisik.corestability.turret.slot4"
    
    // Special
    case bladeWeapon = "com.cagdasbertanisik.corestability.blade.unlock"
    
    var gemAmount: Int {
        switch self {
        case .gems80: return 80
        case .gems500: return 500
        case .gems1200: return 1200
        case .gems3500: return 3500
        case .gems8000: return 8000
        case .gems20000: return 20000
        default: return 0
        }
    }
    
    /// Fallback price in USD (shown if StoreKit price not loaded)
    var fallbackPrice: String {
        switch self {
        case .gems80: return "$0.99"
        case .gems500: return "$4.99"
        case .gems1200: return "$9.99"
        case .gems3500: return "$24.99"
        case .gems8000: return "$49.99"
        case .gems20000: return "$99.99"
        // case .removeAds removed
        case .battlePass: return "$4.99"
        case .shotgunRental: return "$2.99"
        case .shotgunLifetime: return "$3.99"
        case .railgunRental: return "$3.99"
        case .railgunLifetime: return "$5.99"
        case .turretSlot1: return "$0.99"
        case .turretSlot2: return "$1.99"
        case .turretSlot3: return "$2.99"
        case .turretSlot4: return "$3.99"
        case .bladeWeapon: return "$1.99"
        }
    }
    
    var displayName: String {
        switch self {
        case .gems80: return "80 Gems"
        case .gems500: return "500 Gems (+25%)"
        case .gems1200: return "1,200 Gems (+40%)"
        case .gems3500: return "3,500 Gems (+60%)"
        case .gems8000: return "8,000 Gems (+80%)"
        case .gems20000: return "20,000 Gems (+100%)"
        // case .removeAds removed
        case .battlePass: return "Battle Pass"
        case .shotgunRental: return "Shotgun (15 Days)"
        case .shotgunLifetime: return "Shotgun (Forever)"
        case .railgunRental: return "Railgun (15 Days)"
        case .railgunLifetime: return "Railgun (Forever)"
        case .turretSlot1: return "Turret Slot 1"
        case .turretSlot2: return "Turret Slot 2"
        case .turretSlot3: return "Turret Slot 3"
        case .turretSlot4: return "Turret Slot 4"
        case .bladeWeapon: return "Spinning Blade"
        }
    }
}

final class IAPManager: NSObject {
    static let shared = IAPManager()
    
    private var products: [SKProduct] = []
    private var purchaseCompletion: ((Bool, String?) -> Void)?
    
    private let defaults = UserDefaults.standard
    
    // MARK: - State
    
    // hasRemovedAds removed

    
    var hasBattlePass: Bool {
        get { defaults.bool(forKey: "hasBattlePass") }
        set { defaults.set(newValue, forKey: "hasBattlePass") }
    }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() {
        let productIDs = Set(IAPProduct.allCases.map { $0.rawValue })
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func getProduct(for iap: IAPProduct) -> SKProduct? {
        return products.first { $0.productIdentifier == iap.rawValue }
    }
    
    func getLocalizedPrice(for iap: IAPProduct) -> String {
        guard let product = getProduct(for: iap) else { return iap.fallbackPrice }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? iap.fallbackPrice
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: IAPProduct, completion: @escaping (Bool, String?) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(false, "Purchases are disabled on this device")
            return
        }
        
        guard let skProduct = getProduct(for: product) else {
            completion(false, "Product not found. Try again later.")
            return
        }
        
        purchaseCompletion = completion
        let payment = SKPayment(product: skProduct)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Restore
    
    func restorePurchases(completion: @escaping (Bool, String?) -> Void) {
        purchaseCompletion = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Process Purchase
    
    private func handlePurchase(productID: String) {
        guard let product = IAPProduct(rawValue: productID) else { return }
        
        switch product {
        case .gems80, .gems500, .gems1200, .gems3500, .gems8000, .gems20000:
            GemManager.shared.addGems(product.gemAmount, source: .purchase)
            
        // case .removeAds removed
            
        case .battlePass:
            hasBattlePass = true
            
        // Weapon Logic
        case .shotgunRental:
            UpgradeManager.shared.rentWeapon(.shotgun, days: 15)
        case .shotgunLifetime:
            UpgradeManager.shared.unlockWeaponPermanently(.shotgun)
            
        case .railgunRental:
            UpgradeManager.shared.rentWeapon(.railgun, days: 15)
        case .railgunLifetime:
            UpgradeManager.shared.unlockWeaponPermanently(.railgun)
            
        case .turretSlot1:
            UpgradeManager.shared.turretSlotsUnlocked = max(UpgradeManager.shared.turretSlotsUnlocked, 1)
        case .turretSlot2:
            UpgradeManager.shared.turretSlotsUnlocked = max(UpgradeManager.shared.turretSlotsUnlocked, 2)
        case .turretSlot3:
            UpgradeManager.shared.turretSlotsUnlocked = max(UpgradeManager.shared.turretSlotsUnlocked, 3)
        case .turretSlot4:
            UpgradeManager.shared.turretSlotsUnlocked = max(UpgradeManager.shared.turretSlotsUnlocked, 4)
            
        case .bladeWeapon:
            UpgradeManager.shared.isBladeUnlocked = true
        }
        
        Analytics.logEvent("iap_purchase", parameters: [
            "product": productID,
            "gems": product.gemAmount
        ])
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        print("[IAPManager] Loaded \(products.count) products")
        
        for invalidID in response.invalidProductIdentifiers {
            print("[IAPManager] Invalid product ID: \(invalidID)")
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("[IAPManager] Failed to load products: \(error.localizedDescription)")
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchase(productID: transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
                purchaseCompletion?(true, nil)
                purchaseCompletion = nil
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                let errorMessage = transaction.error?.localizedDescription ?? "Unknown error"
                purchaseCompletion?(false, errorMessage)
                purchaseCompletion = nil
                
            case .restored:
                handlePurchase(productID: transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred, .purchasing:
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        purchaseCompletion?(true, nil)
        purchaseCompletion = nil
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        purchaseCompletion?(false, error.localizedDescription)
        purchaseCompletion = nil
    }
}
