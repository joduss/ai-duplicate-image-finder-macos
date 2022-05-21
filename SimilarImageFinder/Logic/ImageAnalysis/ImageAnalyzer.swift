import Foundation

protocol ImageAnalyzer {
    func start(images: [URL]) async
}
