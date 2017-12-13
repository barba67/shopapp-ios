//
//  HomeViewController.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 9/14/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class HomeViewController: BaseViewController<HomeViewModel>, HomeTableDataSourceProtocol, HomeTableDelegateProtocol, LastArrivalsCellDelegate, PopularCellDelegate, HomeHeaderViewProtocol {
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: HomeTableDataSource?
    var delegate: HomeTableDelegate?
    
    override func viewDidLoad() {
        viewModel = HomeViewModel()
        super.viewDidLoad()
        
        setupTableView()
        setupViewModel()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavigationBar()
    }
    
    private func updateNavigationBar() {
        tabBarController?.navigationItem.titleView = nil
        tabBarController?.title = NSLocalizedString("ControllerTitle.Home", comment: String())
        updateCartBarItem()
    }
    
    private func setupTableView() {
        let lastArrivalsNib = UINib(nibName: String(describing: LastArrivalsTableViewCell.self), bundle: nil)
        tableView.register(lastArrivalsNib, forCellReuseIdentifier: String(describing: LastArrivalsTableViewCell.self))
        
        let popularNib = UINib(nibName: String(describing: PopularTableViewCell.self), bundle: nil)
        tableView.register(popularNib, forCellReuseIdentifier: String(describing: PopularTableViewCell.self))
        
        let newInBlogNib = UINib(nibName: String(describing: ArticleTableViewCell.self), bundle: nil)
        tableView.register(newInBlogNib, forCellReuseIdentifier: String(describing: ArticleTableViewCell.self))
                
        dataSource = HomeTableDataSource(delegate: self)
        tableView.dataSource = dataSource
        
        delegate = HomeTableDelegate(delegate: self)
        tableView.delegate = delegate
        
        tableView?.contentInset = TableView.homeContentInsets
    }
    
    private func updateCartBarItem() {
        Repository.shared.getCartProductList { [weak self] (products, error) in
            let cartItemsCount = products?.count ?? 0
            self?.addCartBarButton(with: cartItemsCount)
        }
    }
    
    private func setupViewModel() {
        viewModel.data.asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateCartBarItem()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadData() {
        viewModel.loadData(with: disposeBag)
    }
    
    // MARK: - HomeTableDataSourceProtocol
    func lastArrivalsObjects() -> [Product] {
        return viewModel.data.value.latestProducts
    }
    
    func popularObjects() -> [Product] {
        return viewModel.data.value.popularProducts
    }
    
    func articlesCount() -> Int {
        return viewModel.data.value.articles.count
    }
    
    func article(at index: Int) -> Article? {
        if index < viewModel.data.value.articles.count {
            return viewModel.data.value.articles[index]
        }
        return nil
    }
    
    // MARK: - HomeTableDelegateProtocol
    func didSelectArticle(at index: Int) {
        if index < viewModel.data.value.articles.count {
            let article = viewModel.data.value.articles[index]
            pushArticleDetailsController(with: article.id)
        }
    }
    
    // MARK: - LastArrivalsCellDelegate
    func didSelectLastArrivalsProduct(at index: Int) {
        openProductDetails(with: viewModel.data.value.latestProducts, index: index)
    }
    
    // MARK: - PopularCellDelegate
    func didSelectPopularProduct(at index: Int) {
        openProductDetails(with: viewModel.data.value.popularProducts, index: index)
    }
    
    private func openProductDetails(with products: [Product], index: Int) {
        if index < products.count {
            let selectedProduct = products[index]
            pushDetailController(with: selectedProduct)
        }
    }
    
    // MARK: - HomeHeaderViewProtocol
    func didTapSeeAll(type: HomeTableViewType) {
        switch type {
        case .latestArrivals:
            pushLastArrivalsController()
        case .popular:
        // TODO:
            break
        case .blogPosts:
            pushArticlesListController()
        }
    }
    
    // MARK: - ErrorViewProtocol
    func didTapTryAgain() {
        viewModel.loadData(with: disposeBag)
    }
}
