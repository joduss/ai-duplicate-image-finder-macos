//
import SwiftUI

struct AnalysisView: View {
    
    @EnvironmentObject var duplicateImageAnalysis: ImageDuplicateAnalysis
    
    @State private var images: [URL] = []
    
    var body: some View {
        VStack {
            Text("Searching and Analysing images").font(.title).padding()
            ProgressView(duplicateImageAnalysis.progressInformation, value: duplicateImageAnalysis.progressValue,
                         total: duplicateImageAnalysis.progressTotal)
            .padding()
            .onAppear() {
                duplicateImageAnalysis.start()
            }
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}
