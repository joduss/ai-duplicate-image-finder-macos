import SwiftUI

struct AnalysisView: View {
    
    @EnvironmentObject var duplicateImageAnalysis: ImageDuplicateAnalysisViewModel
    
    @State private var images: [URL] = []
    
    var body: some View {
        VStack {
            Text("Searching and Analysing images").font(.title).padding()
            ProgressView(duplicateImageAnalysis.progressInformation, value: duplicateImageAnalysis.progressValue,
                         total: duplicateImageAnalysis.progressTotal)
            .padding()
            .onAppear() {
                duplicateImageAnalysis.startAnalysis()
            }
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}
