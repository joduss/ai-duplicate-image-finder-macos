//

import Foundation
import AppKit


class DuplicateListViewCell: NSCollectionViewItem {
    
    @IBOutlet weak var imageLeftView: NSImageView!
    @IBOutlet weak var imageRightView: NSImageView!
    @IBOutlet weak var similarityLabel: NSTextField!
    @IBOutlet weak var imageLeftLabel: NSTextField!
    @IBOutlet weak var imageRightLabel: NSTextField!
    
    private let imageLoaderRight = CellImageLoader()
    private let imageLoaderLeft = CellImageLoader()

    
    func configure(potentialDuplicate: ImageDuplicatePair) {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        self.setImageLeft(url: potentialDuplicate.pathImageA)
        self.setImageRight(url: potentialDuplicate.pathImageB)
        self.imageLeftLabel.stringValue = potentialDuplicate.imageAName
        self.imageRightLabel.stringValue = potentialDuplicate.imageBName
        self.similarityLabel.stringValue = numberFormatter.string(from: potentialDuplicate.similarity as NSNumber) ?? "?"
    }
    
    private func setImageRight(url: URL) {
        imageLoaderRight.load(url: url, completed: { image in
            self.imageRightView.image = image
        }, width: 200, height: 200)
    }
    
    private func setImageLeft(url: URL) {
        imageLoaderLeft.load(url: url, completed: { image in
            self.imageLeftView.image = image
        }, width: 200, height: 200)
    }
    
    override func prepareForReuse() {
        imageLoaderRight.cancel()
        imageLoaderLeft.cancel()
        imageRightView.image = nil
        imageLeftView.image = nil
    }
}
