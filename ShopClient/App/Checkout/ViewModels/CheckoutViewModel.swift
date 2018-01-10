//
//  CheckoutViewModel.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 12/20/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import RxSwift

enum CheckoutSection: Int {
    case cart
    case shippingAddress
    case payment
    
    static let allValues = [cart, shippingAddress, payment]
}

class CheckoutViewModel: BaseViewModel {
    var cartItems = [CartProduct]()
    var checkout = Variable<Checkout?>(nil)
    
    var billingAddress: Address?
    var creditCard: CreditCard?
    
    private let checkoutUseCase = CheckoutUseCase()
    private let cartProductListUseCase = CartProductListUseCase()
    private let customerUseCase = CustomerUseCase()
    
    var placeOrderPressed: AnyObserver<()> {
        return AnyObserver { [weak self] event in
            self?.placeOrderAction()
        }
    }
    
    public func loadData(with disposeBag: DisposeBag) {
        state.onNext(.loading(showHud: true))
        checkoutCreateSingle.subscribe(onSuccess: { [weak self] (checkout) in
            self?.checkout.value = checkout
            self?.getCustomer()
        }) { [weak self] (error) in
            let castedError = error as? RepoError
            self?.state.onNext(.error(error: castedError))
        }
        .disposed(by: disposeBag)
    }
    
    public func getCheckout() {
        let checkoutId = checkout.value?.id ?? String()
        checkoutUseCase.getCheckout(with: checkoutId) { [weak self] (result, error) in
            if let error = error {
                self?.state.onNext(.error(error: error))
            }
            if let checkout = result {
                self?.checkout.value = checkout
                self?.state.onNext(.content)
            }
        }
    }
    
    public func updateCheckoutShippingAddress(with address: Address, isDefaultAddress: Bool) {
        state.onNext(.loading(showHud: true))
        let checkoutId = checkout.value?.id ?? String()
        checkoutUseCase.updateCheckoutShippingAddress(with: checkoutId, address: address) { [weak self] (success, error) in
            if let error = error {
                self?.state.onNext(.error(error: error))
            } else if let success = success, success == true {
                self?.processUpdateCheckoutShippingAddress(address: address, isDefaultAddress: isDefaultAddress)
            } else {
                self?.state.onNext(.error(error: RepoError()))
            }
            
        }
    }
    
    // MARK: - private
    private var cartItemsSingle: Single<[CartProduct]> {
        return Single.create(subscribe: { [weak self] (event) in
            self?.cartProductListUseCase.getCartProductList({ [weak self] (result) in
                self?.cartItems = result
                event(.success(result))
            })
            return Disposables.create()
        })
    }
    
    private var checkoutCreateSingle: Single<Checkout> {
        return cartItemsSingle.flatMap({ (cartItems) in
            Single.create(subscribe: { [weak self] (event) in
                self?.checkoutUseCase.createCheckout(cartProducts: cartItems, callback: { (checkout, error) in
                    if let error = error {
                        event(.error(error))
                    }
                    if let checkout = checkout {
                        event(.success(checkout))
                    }
                })
                return Disposables.create()
            })
        })
    }
    
    private func getCustomer() {
        customerUseCase.getCustomer { [weak self] (customer, error) in
            if let address = customer?.defaultAddress {
                self?.updateCheckoutShippingAddress(with: address, isDefaultAddress: false)
            } else {
                self?.state.onNext(.content)
            }
        }
    }
    
    private func processUpdateCheckoutShippingAddress(address: Address, isDefaultAddress: Bool) {
        customerUseCase.addAddress(with: address) { [weak self] (addressId, error) in
            if let addressId = addressId {
                self?.processCustomerAddingAddress(with: addressId, isDefaultAddress: isDefaultAddress)
            } else {
                self?.getCheckout()
            }
        }
    }
    
    private func processCustomerAddingAddress(with addressId: String, isDefaultAddress: Bool) {
        if isDefaultAddress {
            updateCustomerDefaultAddress(with: addressId)
        } else {
            getCheckout()
        }
    }
    
    private func updateCustomerDefaultAddress(with addressId: String) {
        customerUseCase.updateDefaultAddress(with: addressId) { [weak self] (success, error) in
            self?.getCheckout()
        }
    }
    
    private func placeOrderAction() {
        if let checkout = checkout.value, let card = creditCard, let billingAddress = billingAddress {
            state.onNext(.loading(showHud: true))
            checkoutUseCase.pay(with: card, checkout: checkout, billingAddress: billingAddress) { [weak self] (success, error) in
                if let error = error {
                    self?.state.onNext(.error(error: error))
                }
                if let success = success {
                    self?.processPlaceOrderResponse(with: success)
                    self?.state.onNext(.content)
                }
            }
        }
    }
    
    private func processPlaceOrderResponse(with success: Bool) {
        // TODO:
    }
}
