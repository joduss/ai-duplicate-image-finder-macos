import Foundation
import CoreML

class ImageDuplicateClassifierInputBatch: MLBatchProvider {
    public private(set) var imageRepresentations: [(ImageEmbedding, ImageEmbedding)]
    
    var count: Int {
        return self.imageRepresentations.count
    }
    
    
    init(imageRepresentations: [(ImageEmbedding, ImageEmbedding)]) {
        self.imageRepresentations = imageRepresentations
    }
    
    init(size: Int) {
        self.imageRepresentations = []
        self.imageRepresentations.reserveCapacity(size)
    }
    
    func features(at index: Int) -> MLFeatureProvider {
        
        let representations = imageRepresentations[index]
        
        return ImageDuplicateClassifierInputFeatures(imageA: representations.0, imageB: representations.1)
    }
    
    func add(_ representations: (ImageEmbedding, ImageEmbedding)) {
        self.imageRepresentations.append(representations)
    }
}
