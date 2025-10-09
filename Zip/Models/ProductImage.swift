//
//  ProductImage.swift
//  Zip
//

import Foundation

final class ProductImage: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let productName: String
    var imageURL: String? // Made optional and mutable to handle null values and URL conversion
    let altText: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), productId: UUID, productName: String, imageURL: String?, altText: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.imageURL = imageURL
        self.altText = altText
        self.createdAt = createdAt
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case imageURL = "image_url"
        case altText = "alt_text"
        case createdAt = "created_at"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        productId = try container.decode(UUID.self, forKey: .productId)
        productName = try container.decode(String.self, forKey: .productName)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        altText = try container.decodeIfPresent(String.self, forKey: .altText)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(productId, forKey: .productId)
        try container.encode(productName, forKey: .productName)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(altText, forKey: .altText)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
