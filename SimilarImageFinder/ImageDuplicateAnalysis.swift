//

import Foundation
import UniformTypeIdentifiers
import CoreML



class ImageDuplicateAnalysis: ObservableObject {
    
    private let analyzer = ImageDuplicateAnalyzer()
    
    @Published var selectedDirectory: URL! = nil
    private(set) var images: [URL] = []
    @Published private(set) var progressInformation: String = "Searching images..."
    
    @Published var progressValue: Double? = 0.0
    @Published var progressTotal: Double = 0.0
    
    private var imageProcessed: Array<MLMultiArray> = []
    
    @Published var potentialDuplicateSearched = false
    @Published var potentialDuplicate: [ImagePotentialDuplicate] = []
    
    /// Start the analysis.
    func start() {
        Task.detached(priority: .userInitiated) {() in
            await self.searchImages()
            await self.analyzeImages()
            await self.detectDuplicates()
        }
    }
    
    private func searchImages() async {
        let fileEnumerator = FileManager().enumerator(at: selectedDirectory, includingPropertiesForKeys: [.contentTypeKey])
        
        while let file = fileEnumerator?.nextObject() as? URL {
            do {
                guard let contentType = try file.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                    continue
                }
                
                if contentType.conforms(to: .image) && (contentType.conforms(to: UTType.jpeg) || contentType.conforms(to: UTType.png) || contentType.conforms(to: UTType.heic) || contentType.conforms(to: UTType.heif))  {
                    images.append(file)
                                        
                    await MainActor.run {
                        if (images.count % 100 == 0) {
                            progressInformation = "\(images.count) images found"
                        }
                    }
                }
            } catch {
                print("Error \(error)")
            }
        }
        
        await MainActor.run {
            if (images.count % 100 == 0) {
                progressInformation = "\(images.count) images found."
            }
        }
    }
    
    
    private func analyzeImages() async {
        await MainActor.run {
            self.progressTotal = Double(self.images.count)
        }
                
        for i in 0..<Int(self.progressTotal) {
            try? await Task.sleep(nanoseconds: UInt64(0.001 * 1e9))
            await MainActor.run {
//                if i % 31 == 0 {
                    self.progressValue = self.progressValue ?? 0 + Double(i)
                    self.progressInformation = "Analyze image \(i + 1) / \(self.images.count)"
//                }
            }
            
            analyzer.analyze(imageUrl: self.images[i])
        }
    }
    
    
    private func detectDuplicates() async {
        await MainActor.run {
            self.progressTotal = Double(self.images.count)

        }
        
        var list: [ImagePotentialDuplicate] = []
        
        for i in 0..<Int(self.progressTotal) {
            try? await Task.sleep(nanoseconds: UInt64(0.001 * 1e9))
            await MainActor.run {
                self.progressValue = self.progressValue ?? 0 + Double(i)
                self.progressInformation = "Searching for duplicates \(i + 1) / \(self.images.count)"
            }
            
            list.append(ImagePotentialDuplicate(pathImageA: self.images[i], pathImageB: self.images[i], name: self.images[i].lastPathComponent, similarity: 0.1))
        }
        
        let l = list
        await MainActor.run {
            potentialDuplicate = l
            potentialDuplicateSearched = true
        }
    }
}
