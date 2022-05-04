//

import Foundation


struct ImageFeaturesRepresentation {

    let imageUrl: URL
    let featuresRepresentation: ImageRepresentationModelOutput
    
    init(imageUrl: URL, featuresRepresentation: ImageRepresentationModelOutput) {
        self.imageUrl = imageUrl
        self.featuresRepresentation = featuresRepresentation
    }
}
