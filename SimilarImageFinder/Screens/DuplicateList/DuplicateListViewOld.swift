//

import SwiftUI
import AppKit.NSImage
import Combine

// List is unusable on macOS. Very slow, very buggy.


class IndexCell {
    static let instance = IndexCell()
    
    var idx = 0
}

class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    //    private let url: URL?
    private var cancellable: AnyCancellable?
    
    
    deinit {
        cancellable?.cancel()
    }
    
    init() {}
    
    func load(url: URL, width: Int? = nil, height: Int? = nil) {
        print("Will load \(url.lastPathComponent)")
        Task.detached(operation: {() in
            await self.loadImage(url: url, width: width, height: height)
        })
    }
    
    private func loadImage(url: URL, width: Int? = nil, height: Int? = nil) async {
        //        guard let url = self.url else {
        //            return
        //        }
        
        guard let image = NSImage(contentsOf: url) else {
            return
        }
        
        guard let height = height, let width = width else {
            await MainActor.run {
                self.image = image
            }
            return
        }
        
        let resizedImage = self.resize(image: image, width: width, height: height)
        
        await MainActor.run {
            //            print("Did load \(url.lastPathComponent)")
            self.image = resizedImage
        }
    }
    
    private func resize(image: NSImage, width: Int, height: Int) -> NSImage {
        
        let resizedImg = NSImage(size: NSSize(width: width, height: height))
        resizedImg.lockFocus()
        
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        
        let ct = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let ctx = NSGraphicsContext(cgContext: ct, flipped: false)
        ctx.imageInterpolation = NSImageInterpolation.medium
        
        
        image.draw(in: NSRect(x: 0, y: 0, width: width, height: height),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        
        resizedImg.unlockFocus()
        
        return resizedImg
    }
    
    func cancel() {
        //        self.image = nil
        cancellable?.cancel()
    }
}


struct OptimizedImage<Placeholder: View>: View {
    
    @StateObject private var imageLoader: ImageLoader = ImageLoader()
    var placeholder: (() -> Placeholder)?
    
    let a: Int
    
    private(set) var url: URL
    
    var body: some View {
        image
            .onAppear(perform: { () in
                print("(\(a)) onAppear: \(url.lastPathComponent)")
                imageLoader.load(url: url, width: 100, height: 100)})
            .onDisappear {
                () in
                print("(\(a)) onDisappear: \(url.lastPathComponent)")
                imageLoader.cancel()
            }
    }
    
    private var image: some View {
        Group {
            if let image = self.imageLoader.image {
                VStack {
                    Text("Cell \(a)")
                    Image(nsImage: image)
                }
            } else if let placeholder = self.placeholder {
                //                placeholder()
                Text("disappearace \(a)").frame(width: 100, height: 100)
            }
        }
    }
    
    init(url: URL, placeholder: (() -> Placeholder)? = nil) {
        self.url = url
        self.placeholder = placeholder
        a = IndexCell.instance.idx
        IndexCell.instance.idx += 1
        //        self.initLoadImage()
    }
    
    
    //    @MainActor
    //    private func setBody(image: NSImage) {
    //        self.image = image
    //    }
    //
    //    private func loadImage() async {
    //        guard let image = NSImage(contentsOf: self.url) else {
    //            return
    //        }
    //
    //        await self.setBody(image: image)
    //    }
    //
    //    private func resizeImage(image: NSImage, height: Int, width: Int) async -> NSImage {
    //        try? await Task.sleep(nanoseconds: 2 * UInt64(NSEC_PER_SEC))
    //
    //        return image
    //    }
}

struct DuplicateListViewOld: View {
    @EnvironmentObject private var analysis: ImageDuplicateAnalysis
    
    var body: some View {
        //        Table(analysis.potentialDuplicates) {
        //            TableColumn("Name", value:\.name)
        //            TableColumn("Test", value:\.pathImageA.path)
        //        }
        List(analysis.duplicates.sorted(by: {$0.similarity > $1.similarity}), id:\.self) { c in
            HStack {
                VStack {
                    OptimizedImage(url: c.pathImageA) {
                        Text("Loading...")
                    }
                    Text("\(c.pathImageA.lastPathComponent)")
                }
                VStack {
                    OptimizedImage(url: c.pathImageB) {
                        Text("Loading...")
                    }
                    Text("\(c.pathImageB.lastPathComponent)")
                }
                //                AsyncImage(url: c.pathImageA) { image in
                //                    image.resizable().frame(width: 100, height: 100, alignment: .center).aspectRatio(contentMode: .fit).background(Color.black)
                //                } placeholder: {
                //                    Text("...")
                //                }
                //                AsyncImage(url: c.pathImageB) { image in
                //                    image.resizable().frame(width: 100, height: 100, alignment: .center).aspectRatio(contentMode: .fit).background(Color.black)
                //                } placeholder: {
                //                    Text("...")
                //                }
                Text("\(c.similarity)")
            }.scaledToFill().padding().background(Color("cell-background-color"))
                .cornerRadius(10)
        }
        
        //        ScrollView {
        //            LazyVStack {
        //                ForEach(0..<analysis.potentialDuplicates.count) { i in
        ////                    ThumbnailView(analysis.potentialDuplicates[i])
        ////
        ////                }
        ////                ForEach(analysis.potentialDuplicates) { c in
        ////                    ThumbnailView(c)
        //                    HStack {
        //                        Image(nsImage: NSImage(contentsOfFile: analysis.potentialDuplicates[i].pathImageA.path)!).resizable().aspectRatio(contentMode: .fit).frame(width: 225, height: 225, alignment: .center)
        //                        Image(nsImage: NSImage(contentsOfFile: analysis.potentialDuplicates[i].pathImageB.path)!).resizable().aspectRatio(contentMode: .fit).frame(width: 225, height: 225, alignment: .center)
        ////                        AsyncImage(url: analysis.potentialDuplicates[i].pathImageA) { image in
        ////                            VStack {
        ////                                image.resizable().frame(width: 225, height: 150, alignment: .center)
        //////                                image.
        //////                                image..resizable().frame(width: 100, height: 100, alignment: .center).aspectRatio(contentMode: .fit).background(Color.black)
        //////                                    .rotationEffect(.zero)
        ////                                Text("a")
        ////                            }
        ////                        } placeholder: {
        ////                            ProgressView()
        ////                        }
        ////                        AsyncImage(url: analysis.potentialDuplicates[i].pathImageB) { image in
        ////                            image.resizable().aspectRatio(contentMode: .fit).frame(width: 225, height: 150, alignment: .center).background(Color.black)
        ////                        } placeholder: {
        ////                            ProgressView()
        ////                        }
        //                        Text("\(analysis.potentialDuplicates[i].similarity)")
        //                    }.scaledToFill().padding().background(Color("cell-background-color"))
        //                        .cornerRadius(10)
        //                }
        //            }
        //        }
    }
}

struct ThumbnailView: View {
    //    let row: Int
    private var imagePo : ImageDuplicatePair
    
    
    init(_ imagePo: ImageDuplicatePair) {
        self.imagePo = imagePo
        //        _thumbnailGenerator = StateObject(wrappedValue: imagePo())
    }
    
    var body: some View {
        //        HStack {
        Text("Filename \(imagePo.similarity)")
        //        }.padding()
    }
}


struct DuplicateListView_Previews: PreviewProvider {
    static var previews: some View {
        DuplicateListViewOld().environmentObject(createAnalysis())
    }
    
    static func createAnalysis() -> ImageDuplicateAnalysis {
        let analysis = ImageDuplicateAnalysis()
        analysis.duplicates = [
            ImageDuplicatePair(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img1", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img2", ofType: "jpg")!),
                //                name: "Grace Hopper",
                similarity: 0.1),
            
            ImageDuplicatePair(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img2", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img3", ofType: "jpg")!),
                //                name: "P4329349",
                similarity: 0.25),
            
            ImageDuplicatePair(
                pathImageA: URL(fileURLWithPath: Bundle.main.path(forResource: "img1", ofType: "jpg")!),
                pathImageB: URL(fileURLWithPath: Bundle.main.path(forResource: "img3", ofType: "jpg")!),
                //                name: "Blabla",
                similarity: 0.65),
        ]
        
        return analysis
    }
}
