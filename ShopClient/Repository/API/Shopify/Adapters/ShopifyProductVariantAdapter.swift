//
//  ShopifyProductVariantAdapter.swift
//  ShopClient
//
//  Created by Evgeniy Antonov on 10/25/17.
//  Copyright © 2017 Evgeniy Antonov. All rights reserved.
//

import MobileBuySDK

extension ProductVariant {
    convenience init?(with item: Storefront.ProductVariant?) {
        if item == nil {
            return nil
        }
        self.init()
        
        id = item?.id.rawValue ?? String()
        title = item?.title
        price = item?.price.description
        available = item?.availableForSale ?? false
        image = Image(with: item?.image)
    }
}
