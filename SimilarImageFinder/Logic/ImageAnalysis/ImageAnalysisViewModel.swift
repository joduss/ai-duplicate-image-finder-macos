import Foundation

/// Default implementation for any kind of image analysis ViewModel.
class ImageAnalysisViewModel: ObservableObject {
    
    private let imageAnalyzer: ImageAnalyzer
    
    @Published var progressInformation: String = "Searching images..."
    @Published var progressValue: Double? = 0.0
    @Published var progressTotal: Double = 0.0
    
    @Published var selectedDirectory: URL! = nil
    
    init(imageAnalyzer: ImageAnalyzer) {
        self.imageAnalyzer = imageAnalyzer
    }
            
    /// Starts the analysis
    func startAnalysis() {
        Task.detached {
            await self.searchImages()
            await imageAnalyzer.start(images: )
        }
    }
    
    
    private func searchImages() async -> [URL] {
        let fileEnumerator = FileManager().enumerator(at: selectedDirectory, includingPropertiesForKeys: [.contentTypeKey])
        
        var images: [URL] = []
        
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
        
        return images
    }
}
