//

import Foundation

struct ImagePotentialDuplicate: Hashable, Identifiable {
    
    var id: ObjectIdentifier
    
    var pathImageA: URL
    var pathImageB: URL

    var name: String
    var similarity: Float
    
    init(pathImageA: URL, pathImageB: URL, name: String, similarity: Float) {
        self.pathImageA = pathImageA
        self.pathImageB = pathImageB
        self.name = name
        self.similarity = similarity
        self.id = ObjectIdentifier(ImagePotentialDuplicate.self)
    }
    
    // MARK: - Hashable
    
    static func == (lhs: ImagePotentialDuplicate, rhs: ImagePotentialDuplicate) -> Bool {
        lhs.pathImageA == rhs.pathImageA && lhs.pathImageB == rhs.pathImageB
    }
}
