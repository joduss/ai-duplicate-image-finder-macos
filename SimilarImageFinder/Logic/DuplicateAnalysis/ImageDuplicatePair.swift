//

import Foundation

struct ImageDuplicatePair: Hashable, Identifiable {
    
    var id: ObjectIdentifier
    
    var pathImageA: URL
    var pathImageB: URL

    var similarity: Float
    
    var imageAName: String {
        return pathImageA.lastPathComponent
    }
    
    var imageBName: String {
        return pathImageA.lastPathComponent
    }
    
    init(pathImageA: URL, pathImageB: URL, similarity: Float) {
        self.pathImageA = pathImageA
        self.pathImageB = pathImageB
        self.similarity = similarity
        self.id = ObjectIdentifier(ImageDuplicatePair.self)
    }
    
    // MARK: - Hashable
    
    static func == (lhs: ImageDuplicatePair, rhs: ImageDuplicatePair) -> Bool {
        lhs.pathImageA == rhs.pathImageA && lhs.pathImageB == rhs.pathImageB
    }
}
