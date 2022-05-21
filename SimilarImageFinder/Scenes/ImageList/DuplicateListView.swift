import Foundation
import SwiftUI
import AppKit


class DuplicateListViewController: NSViewController, NSCollectionViewDataSource {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private let analyzis: ImageDuplicateAnalysisViewModel
    
    var potentialDuplicates: [ImageDuplicatePair] = []
    
    init(analyzis: ImageDuplicateAnalysisViewModel) {
        self.analyzis = analyzis
        self.potentialDuplicates = analyzis.duplicates
        super.init(nibName: "DuplicateListViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.analyzis = ImageDuplicateAnalysisViewModel()
        self.potentialDuplicates = analyzis.duplicates
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        self.collectionView.dataSource = self
        self.potentialDuplicates = analyzis.duplicates
        
        self.collectionView.register(NSNib(nibNamed: "DuplicateListViewCell", bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier("item"))
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return potentialDuplicates.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("item"), for: indexPath) as! DuplicateListViewCell
        item.configure(potentialDuplicate: potentialDuplicates[indexPath.item])
        
        return item
    }
}


struct DuplicateListView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = DuplicateListViewController
    
    @EnvironmentObject var analysis: ImageDuplicateAnalysisViewModel

    
    func makeNSViewController(context: Context) -> DuplicateListViewController {
        return DuplicateListViewController(analyzis: self.analysis)
    }
    
    func updateNSViewController(_ nsViewController: DuplicateListViewController, context: Context) {
        return
    }
}
