//

import SwiftUI
import os.log

struct HomeView: View {
    
    @EnvironmentObject var state: ImageDuplicateAnalysis
    @State var selectedDirectory: URL!
    
    var body: some View {
        VStack {
            Button("Click to Select a Directory", action: { () in
                os_log("Selected directory", type: .info)
                
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                
                panel.runModal()
                
                guard panel.urls.count > 0 else { return }
                
                selectedDirectory = panel.urls[0]
                
            }).padding()
            Text("OR")
            Group {
                Text("Drop a Directory").foregroundColor(.white).padding()
            }.frame(height: 150).background(.black)
            
            Divider().padding()
            
            if selectedDirectory != nil {
                Text(selectedDirectory.path)
            } else {
                Text("No Directory Selected")
            }
                        
            Button("Analyze", action: { () in
                print("ok")
                state.selectedDirectory = selectedDirectory
            }).disabled(selectedDirectory == nil).padding()
                
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
