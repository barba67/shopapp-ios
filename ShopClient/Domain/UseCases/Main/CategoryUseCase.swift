//
//  CategoryUseCase.swift
//  ShopClient
//
//  Created by Radyslav Krechet on 12/29/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import ShopClient_Gateway

class CategoryUseCase {
    private lazy var repository = AppDelegate.getRepository()

    func getCategory(with id: String, paginationValue: Any?, sortingValue: SortingValue, reverse: Bool, _ callback: @escaping RepoCallback<Category>) {
        repository.getCategoryDetails(id: id, perPage: kItemsPerPage, paginationValue: paginationValue, sortBy: sortingValue, reverse: reverse, callback: callback)
    }
}
