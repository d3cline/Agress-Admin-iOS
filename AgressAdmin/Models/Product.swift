import Foundation

struct Product: Identifiable, Codable {
    var id: Int?
    var name: String
    var price: Double
    var currency: String
    var description: String
    var image: String
    
    // Decoded image (excluded from serialization)
    var decodedImage: Data? {
        // Remove the data URI prefix for supported image types
        let prefixes = [
            "data:image/jpeg;base64,",
            "data:image/png;base64,",
            "data:image/webp;base64,"
        ]
        
        var base64String = image
        for prefix in prefixes {
            if image.starts(with: prefix) {
                base64String = image.replacingOccurrences(of: prefix, with: "")
                break
            }
        }
        
        return Data(base64Encoded: base64String)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, currency, description, image
    }
}
 
