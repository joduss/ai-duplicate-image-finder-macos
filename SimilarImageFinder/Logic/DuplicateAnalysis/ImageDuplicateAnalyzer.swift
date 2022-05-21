import Foundation
import CoreML
import Vision
import AppKit


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
            var batch = ImageDuplicateClassifierInputBatch(size: batchSize)
            
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
                    batch = ImageDuplicateClassifierInputBatch(size: batchSize)
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
    
    
    private func processBatchSimilarityPredictions(_ predictions: MLBatchProvider?, for batchFeatures: ImageDuplicateClassifierInputBatch) -> [ImageDuplicatePair] {
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
}
