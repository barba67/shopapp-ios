//
//  LoginViewModel.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 11/14/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import RxSwift

private let kPasswordCharactersCountMin = 6

class LoginViewModel: BaseViewModel {
    var emailText = Variable<String>(String())
    var passwordText = Variable<String>(String())
    
    var loginSuccess = Variable<Bool>(false)
    
    var isValid: Observable<Bool> {
        return Observable.combineLatest(emailText.asObservable(), passwordText.asObservable()) { email, password in
            email.isValidAsEmais() && password.characters.count >= kPasswordCharactersCountMin
        }
    }
    
    var loginPressed: AnyObserver<()> {
        return AnyObserver { [weak self] event in
            self?.login()
        }
    }
    
    private func login() {
        state.onNext((.loading, nil))
        Repository.shared.login(with: emailText.value, password: passwordText.value) {[weak self] (success, error) in
            if let success = success {
                self?.loginSuccess.value = success
                self?.state.onNext((.content, nil))
            }
            if let error = error {
                self?.state.onNext((.error, error))
            }
        }
    }
}
