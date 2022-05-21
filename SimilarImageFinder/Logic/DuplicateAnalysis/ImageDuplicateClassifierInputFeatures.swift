import Foundation
import CoreML

class ImageDuplicateClassifierInputFeatures: MLFeatureProvider {
    var featureNames: Set<String> = Set<String>(arrayLiteral: "input1_model_part_2", "input2_model_part_2")
    
    private let imageA: ImageEmbedding
    private let imageB: ImageEmbedding
    
    init(imageA: ImageEmbedding, imageB: ImageEmbedding) {
        self.imageA = imageA
        self.imageB = imageB
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input1_model_part_2") {
            return MLFeatureValue(multiArray: imageA.embedding.Identity)
        }
        else {
            return MLFeatureValue(multiArray: imageB.embedding.Identity)
        }
    }
    }
