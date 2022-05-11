import Foundation


struct ImageEmbedding {

    let imageUrl: URL
    let embedding: ImageDuplicateEmbeddingModelOutput
    
    init(imageUrl: URL, embedding: ImageDuplicateEmbeddingModelOutput) {
        self.imageUrl = imageUrl
        self.embedding = embedding
    }
}
