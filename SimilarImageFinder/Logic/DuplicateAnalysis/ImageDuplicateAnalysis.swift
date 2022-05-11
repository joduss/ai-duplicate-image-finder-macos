import Foundation
import UniformTypeIdentifiers
import CoreML



class ImageDuplicateAnalysis: ObservableObject {
    
    private let analyzer = try! ImageDuplicateAnalyzer()
    
    @Published var selectedDirectory: URL! = nil
    private(set) var images: [URL] = []
    @Published private(set) var progressInformation: String = "Searching images..."
    
    @Published var progressValue: Double? = 0.0
    @Published var progressTotal: Double = 0.0
    
    private var imageEmbeddings: [ImageEmbedding] = []
    
    @Published var potentialDuplicateSearched = false
    @Published var duplicates: [ImageDuplicatePair] = []
    
    /// Start the analysis.
    func start() {
        Task.detached(priority: .userInitiated) { () in
            await self.searchImages()
            await self.computeImageEmbeddings()
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
    
    private func computeImageEmbeddings() async {
        let progress = ProgressTracker()
        
        let observer = progress.whenChanged().sink(receiveCompletion: {_ in }, receiveValue: {
            self.progressValue = progress.current
            self.progressTotal = progress.total
            self.progressInformation = "Analyzing image \(Int(progress.current)) / \(Int(progress.total))"
        })
        
        imageEmbeddings = await self.analyzer.computeEmbeddings(imageUrls: self.images, progressTracker: progress)
        observer.cancel()
    }
    
    private func detectDuplicates() async {
        
        let progress = ProgressTracker()
        
        let observer = progress.whenChanged().sink(receiveCompletion: {_ in }, receiveValue: {
            self.progressValue = progress.current
            self.progressTotal = progress.total
            self.progressInformation = "Comparison \(Int(progress.current)) / \(Int(progress.total))"
        })
        
        let potentialDuplicates = await analyzer.findDuplicates(imageEmbeddings: self.imageEmbeddings, progress: progress)
        let duplicates = potentialDuplicates.filter({$0.similarity > 0.5})
        
        await MainActor.run {
            self.duplicates = duplicates
            potentialDuplicateSearched = true
        }
        
        
        observer.cancel()
    }
}
