//

import SwiftUI

@main
struct SimilarImageFinderApp: App {
    
    @StateObject var state: ImageDuplicateAnalysis = ImageDuplicateAnalysis()
    
    var body: some Scene {
        WindowGroup {
            
            if state.selectedDirectory == nil {
                HomeView().environmentObject(state).frame(minWidth: 400, idealWidth: 400, maxWidth: 600, minHeight: 400, idealHeight: 400, maxHeight: 400)
            } else if state.potentialDuplicateSearched == false {
                AnalysisView().environmentObject(state).frame(minWidth: 400, idealWidth: 400, maxWidth: 600, minHeight: 400, idealHeight: 400, maxHeight: 400)
            } else {
                DuplicateListView().environmentObject(state)
            }
            
        }.commands {
            CommandGroup(after: .newItem, addition: { () in
                Text("Select a Directory")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.orange)
            })
        }
    }
}
