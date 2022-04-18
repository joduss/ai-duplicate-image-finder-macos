//

import Foundation
import CoreML
import Vision
import AppKit

class ImageDuplicateAnalyzer: ObservableObject {
    
    private let model = try! DuplicateAI(configuration: MLModelConfiguration())
    
    init() {
        
    }
    
    
    func analyze(imageUrl: URL) -> [MLMultiArray] {
//        let img = NSImage(contentsOfFile: imageUrl.path)
//        guard let cgImg = img?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
//            print("Failed")
//            return
//        }
//        let request = VNImageRequestHandler(cgImage: cgImg!)
//
//        reque
        
        
        
        let result = try? model.prediction(input: DuplicateAIInput(input_model_part_1At: imageUrl))
        print(result)
        
        return result?.Identity
    }
    
    func analyze(imageUrls: [URL]) -> [MLMultiArray] {
        //        let img = NSImage(contentsOfFile: imageUrl.path)
        //        guard let cgImg = img?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        //            print("Failed")
        //            return
        //        }
        //        let request = VNImageRequestHandler(cgImage: cgImg!)
        //
        //        reque
        
        var outputs = [MLMultiArray]()
        
        for url in imageUrls {
            guard let result = try? model.prediction(input: DuplicateAIInput(input_model_part_1At: url)) else {
                continue
            }

            outputs.append(result.Identity)
        }
        
        return outputs
    }
    
}
