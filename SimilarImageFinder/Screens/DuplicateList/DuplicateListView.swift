//

import SwiftUI

struct DuplicateListView: View {
    @EnvironmentObject private var analysis: ImageDuplicateAnalysis
    
    var body: some View {
        //        Table(analysis.potentialDuplicate) {
        //            TableColumn("Name", value:\.name)
        //            TableColumn("Test", value:\.pathImageA.path)
        //        }
        List(analysis.potentialDuplicate, id:\.self) { c in
            HStack {
                AsyncImage(url: c.pathImageA) { image in
                    image.resizable().frame(width: 100, height: 100, alignment: .center).aspectRatio(contentMode: .fit).background(Color.black)
                } placeholder: {
                    Text("...")
                }
//                Text(c.name)
            }.scaledToFill().padding().background(Color("cell-background-color"))
                .cornerRadius(10)
        }.frame(width: .infinity)
    }
}

struct DuplicateListView_Previews: PreviewProvider {
    static var previews: some View {
        DuplicateListView().environmentObject(createAnalysis())
    }
    
    static func createAnalysis() -> ImageDuplicateAnalysis {
        let analysis = ImageDuplicateAnalysis()
        analysis.potentialDuplicate = [
            ImagePotentialDuplicate(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img1", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img2", ofType: "jpg")!),
//                name: "Grace Hopper",
                similarity: 0.1),
            
            ImagePotentialDuplicate(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img2", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img3", ofType: "jpg")!),
//                name: "P4329349",
                similarity: 0.1),
            
            ImagePotentialDuplicate(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img1", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img3", ofType: "jpg")!),
//                name: "Blabla",
                similarity: 0.1),
        ]
        
        return analysis
    }
}
