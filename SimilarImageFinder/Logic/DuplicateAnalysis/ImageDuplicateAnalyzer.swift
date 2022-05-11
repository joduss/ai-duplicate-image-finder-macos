//

import Foundation
import CoreML
import Vision
import AppKit

actor SyncArray<T> {
    private var array: [T] = []
    
    public func append(_ item: T) {
        array.append(item)
    }
    
    public func toArray() -> [T] {
        return array
    }
}

class ImageDuplicateAnalyzer: ObservableObject {
    
    private let embeddingModel: ImageDuplicateEmbeddingModel
    private let similarityModel: ImageDuplicateClassifier
    
    private let minimumSimilarityScore: Float = 0.25
    
    init() throws {
        embeddingModel = try ImageDuplicateEmbeddingModel(configuration: MLModelConfiguration())
        similarityModel = try ImageDuplicateClassifier(configuration: MLModelConfiguration())
    }
    
    func computeEmbeddings(imageUrls: [URL], progressTracker: ProgressTracker? = nil) async -> [ImageEmbedding] {
        progressTracker?.setTotal(Double(imageUrls.count))
                
        return await Task.detached { () -> [ImageEmbedding] in
            return await withTaskGroup(of: ImageEmbedding?.self, returning: [ImageEmbedding].self, body: {
                group in
                
                for url in imageUrls {
                    group.addTask(operation: {
                        guard let embeddingOutput = self.computeEmbedding(imageUrl: url) else {
                            return nil
                        }
                        
                        progressTracker?.update(1)
                        
                        return ImageEmbedding(imageUrl: url, embedding: embeddingOutput)
                    })
                }
                
                var embeddings = Array<ImageEmbedding>()
                
                for await a in group {
                    if let a = a {
                        embeddings.append(a)
                    }
                }
                
                return embeddings
            })
        }.value
    }
    
    func computeEmbedding(imageUrl: URL) -> ImageDuplicateEmbeddingModelOutput? {
        return try? self.embeddingModel.prediction(
            input: ImageDuplicateEmbeddingModelInput(input_model_part_1At: imageUrl)
        )
    }
    
    func findDuplicates(imageEmbeddings: [ImageEmbedding], progress: ProgressTracker? = nil) async -> [ImageDuplicatePair] {
        
        let batchSize = 128
        progress?.setTotal(pow(Double(imageEmbeddings.count), 2))
                
        return await Task.detached { () in
            let mlModel = self.similarityModel.model
            
            let count = Int(ceil((pow(Double(imageEmbeddings.count), 2.0))))
            var index = 0
            var batch = ImageSimilarityModelInputBatch(size: batchSize)
            
            var predictions: [ImageDuplicatePair] = []
            predictions.reserveCapacity(count / 10)
            
            while(index < count) {
                let bIdx = index % imageEmbeddings.count
                let aIdx = Int(floor(Double(index) / Double(imageEmbeddings.count)))
                
                let imgA = imageEmbeddings[aIdx]
                let imgB = imageEmbeddings[bIdx]
                
                batch.add((imgA, imgB))
                
                if batch.count == batchSize {
                    let batchPotentialDuplicates = self.processBatchSimilarityPredictions(try? mlModel.predictions(fromBatch: batch), for: batch)
                    
                    predictions.append(contentsOf: batchPotentialDuplicates)
                    batch = ImageSimilarityModelInputBatch(size: batchSize)
                    progress?.update(batchSize)
                }
                
                index += 1
            }
            
            if batch.count > 0 {
                let batchPotentialDuplicates = self.processBatchSimilarityPredictions(try? mlModel.predictions(fromBatch: batch), for: batch)
                predictions.append(contentsOf: batchPotentialDuplicates)
                progress?.setCurrent(count)
            }
            
            return predictions
            
        }.value
    }
    
    
    private func processBatchSimilarityPredictions(_ predictions: MLBatchProvider?, for batchFeatures: ImageSimilarityModelInputBatch) -> [ImageDuplicatePair] {
        guard let predictions = predictions else {
            return  []
        }

        var potentialDuplicates: [ImageDuplicatePair] = []
        
        for idx in 0..<predictions.count {
            guard let predictionValue = predictions.features(at: idx)
                .featureValue(for: "Identity")?
                .multiArrayValue![0]
                .floatValue else {
                continue
            }
            
            if predictionValue < minimumSimilarityScore { continue }
            
            let imageRepresentations = batchFeatures.imageRepresentations[idx]
            
            potentialDuplicates.append(
                ImageDuplicatePair(pathImageA: imageRepresentations.0.imageUrl,
                                        pathImageB: imageRepresentations.1.imageUrl,
                                        similarity: predictionValue)
            )
        }
        
        return potentialDuplicates
    }
    
    
    class ImageSimilarityModelInputBatch: MLBatchProvider {
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
            
            return ImageSimilarityModelInputFeatures(imageA: representations.0, imageB: representations.1)
        }
        
        func add(_ representations: (ImageEmbedding, ImageEmbedding)) {
            self.imageRepresentations.append(representations)
        }
    }
    
    class ImageSimilarityModelInputFeatures: MLFeatureProvider {
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
    
}
