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
    
    private let representationModel: ImageRepresentationModel
    private let similarityModel: ImageSimilarityModel
    
    private let minimumSimilarityScore: Float = 0.25
    
    init() throws {
        representationModel = try ImageRepresentationModel(configuration: MLModelConfiguration())
        similarityModel = try ImageSimilarityModel(configuration: MLModelConfiguration())
    }
    
    func createImageRepresentation(imageUrls: [URL], progressTracker: ProgressTracker? = nil) async -> [ImageFeaturesRepresentation] {
        progressTracker?.setTotal(Double(imageUrls.count))
                
        return await Task.detached { () -> [ImageFeaturesRepresentation] in
//            var outputs = SyncArray<ImageFeaturesRepresentation>()
            
            
            var outputs = await withTaskGroup(of: ImageFeaturesRepresentation?.self, returning: [ImageFeaturesRepresentation].self, body: {
                group in
                
                for url in imageUrls {
                    
                    group.addTask(operation: {
                        guard let result = try? self.representationModel.prediction(input: ImageRepresentationModelInput(input_model_part_1At: url)) else {
                            return nil
                        }
                        
                        progressTracker?.update(1)
                        
                        return ImageFeaturesRepresentation(imageUrl: url, featuresRepresentation: result)
                    })
                    
                }
                
                var outputs = Array<ImageFeaturesRepresentation>()
                //
                //                var a = await group.filter({$0 != nil})
                
                for await a in group {
                    if let a = a {
                        outputs.append(a)
                    }
                }
                
                return outputs
            })
            //            var q = OperationQueue()
            //
            //            for url in imageUrls {
//                q.addOperation {
//                    guard let result = try? self.representationModel.prediction(input: ImageRepresentationModelInput(input_model_part_1At: url)) else {
//                        return
//                    }
//
//                    await outputs.append(ImageFeaturesRepresentation(imageUrl: url, featuresRepresentation: result))
//                    progressTracker?.update(1)
//                }
//            }
            
            return outputs
        }.value
    }
    
    func findDuplicates(imageRepresentations: [ImageFeaturesRepresentation], progress: ProgressTracker? = nil) async -> [ImagePotentialDuplicate] {
        
        let batchSize = 128
        progress?.setTotal(pow(Double(imageRepresentations.count), 2))
                
        return await Task.detached { () in
            
            let count = Int(ceil((pow(Double(imageRepresentations.count), 2.0))))

            let mlModel = self.similarityModel.model
            
            var index = 0
            var batch = ImageSimilarityModelInputBatch(size: batchSize)
            
            var predictions: [ImagePotentialDuplicate] = []
            predictions.reserveCapacity(count / 10)
            
            while(index < count) {
                let bIdx = index % imageRepresentations.count
                let aIdx = Int(floor(Double(index) / Double(imageRepresentations.count)))
                
                let imgA = imageRepresentations[aIdx]
                let imgB = imageRepresentations[bIdx]
                
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
    
    private func processBatchSimilarityPredictions(_ predictions: MLBatchProvider?, for batchFeatures: ImageSimilarityModelInputBatch) -> [ImagePotentialDuplicate] {
        guard let predictions = predictions else {
            return  []
        }

        var potentialDuplicates: [ImagePotentialDuplicate] = []
        
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
                ImagePotentialDuplicate(pathImageA: imageRepresentations.0.imageUrl,
                                        pathImageB: imageRepresentations.1.imageUrl,
                                        similarity: predictionValue)
            )
        }
        
        return potentialDuplicates
    }
    
    class ImageSimilarityModelInputBatch: MLBatchProvider {
        public private(set) var imageRepresentations: [(ImageFeaturesRepresentation, ImageFeaturesRepresentation)]

        var count: Int {
            return self.imageRepresentations.count
        }
        
        
        init(imageRepresentations: [(ImageFeaturesRepresentation, ImageFeaturesRepresentation)]) {
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
        
        func add(_ representations: (ImageFeaturesRepresentation, ImageFeaturesRepresentation)) {
            self.imageRepresentations.append(representations)
        }
    }
    
    class ImageSimilarityModelInputFeatures: MLFeatureProvider {
        var featureNames: Set<String> = Set<String>(arrayLiteral: "input1_model_part_2", "input2_model_part_2")
        
        private let imageA: ImageFeaturesRepresentation
        private let imageB: ImageFeaturesRepresentation
        
        init(imageA: ImageFeaturesRepresentation, imageB: ImageFeaturesRepresentation) {
            self.imageA = imageA
            self.imageB = imageB
        }
        
        func featureValue(for featureName: String) -> MLFeatureValue? {
            if (featureName == "input1_model_part_2") {
                return MLFeatureValue(multiArray: imageA.featuresRepresentation.Identity)
            }
            else {
                return MLFeatureValue(multiArray: imageB.featuresRepresentation.Identity)
            }
        }
    }
    
 
//    class ImageRepresentationModelInputBatch: MLBatchProvider {
//
//        private(set) var items: [ImageRepresentationModelInputFeature] = []
//
//        var count: Int {
//            return items.count
//        }
//
//        func features(at index: Int) -> MLFeatureProvider {
//            <#code#>
//        }
//
//
//        init(batchSize: Int) {
//            items.reserveCapacity(batchSize)
//        }
//
//
//    }
//
//    class ImageRepresentationModelInputFeature : MLFeatureProvider {
//        var featureNames: Set<String> {
//            return Set(["input1_model_part_2"])
//        }
//
//        func featureValue(for featureName: String) -> MLFeatureValue? {
//            return MLFeatureValue(imageAt: self.imageUrl, orientation: .up, constraint: ImageRepresentationModelConfig() ?? <#default value#>, options: nil)
//        }
//
//
//        private let imageUrl: URL
//
//        init(imageUrl: URL) {
//            self.imageUrl = imageUrl
//        }
//
//    }
}
