////
////  PageViewNew.swift
////  Zay
////
////  Created by Alexey Gromov on 9/18/19.
////  Copyright © 2019 Peter Williams. All rights reserved.
////

import SwiftUI
import Combine


@available(iOS 13.0, *)


//Only for all types of Views
public struct PageViewNew: View {
    @EnvironmentObject var pageViewClass : PageViewClass
    
    public var width: CGFloat = 0
    public var height: CGFloat = 0
    public var isTapped : Bool = false
    @State public var listEnd : Bool = false
    
    @State public var curDragOffset: CGFloat = 0
    @State var endDragOffset: CGFloat = 0
    
    @State public var curPage: Int = 0
    @State public var nextPage: Int = 0
    public var pageArrayViews:[AnyView] = []
    @State public var finished:Bool = false
    @State public var loopMode: Bool = true
    @State public var showFullImage: Bool = false
    public var animDuration: TimeInterval = 0.3
    public var distToChange: CGFloat = 50
    public enum ScrollState{
        case idle
        case dragging
        case animating
    }
    
    @State public var state: ScrollState = .idle
    public init(width: CGFloat = 0,height: CGFloat = 0,pageArrayViews:[AnyView]) {
        
        self.width = width
        self.height = height
        self.pageArrayViews = pageArrayViews
    }
    
    public var body: some View {
        
        let drag = DragGesture()
            .onChanged {
                self.curDragOffset = $0.translation.width;
                self.state = .dragging
        }
    
        .onEnded { theGesture in
            withAnimation(.linear(duration: self.animDuration)) {
                
                self.endDragOffset = theGesture.translation.width
                self.state = .animating
                self.culculateNextPage()
            }
            
            Timer.scheduledTimer(withTimeInterval: self.animDuration, repeats: false) {_ in
                if self.state == .animating{
                    self.state = .idle
                }
                self.curPage = self.nextPage
            }
        }
        
        return
            
            Group {
                
                if finished == false {
                    
                        ZStack{
                            GeometryReader { g in
                                
                            
                            self.currentPage().offset(x: self.curPageOffset()).frame(width: g.size.width, height: self.height).clipped()
                            
                           
                            if (self.pageArrayViews.count > 1){
                                
                                
                                self.prevPage().offset(x:self.prevPageOffset()).frame(width: g.size.width, height: self.height).clipped()
                                
                                self.incomingPage()
                                    .offset(x: self.nextPageOffset()).frame(width: g.size.width, height: self.height).clipped()
                                
                                VStack(alignment: .center) {
                                    Spacer()
                                    
                                    PageControl(defaultImage: Image(systemName: "circle")
                                                                       .resizable()
                                                                       , selectedImage: Image(systemName: "circle.fill").resizable(), count: self.pageArrayViews.count, curPage: self.curPage)
                                    Spacer()
                                    
                                }
                                
                               
                            }
                            if self.loopMode == false {
                                HStack {
                                    Spacer()
                                    Button(action: { self.finished = true
                                        UserDefaults.standard.set(true, forKey: "AfterFirstRun")
                                    }) { Text("Skip")}
                                }.padding(.leading)
                                    .padding(.trailing)
                                    .offset(y: (self.height/2) - 30)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .onTapGesture(count: 2) {
                        if let actionHandler = actionHandler {
                            actionHandler()
                        }else {
                            //Default Action
                            self.showFullImage = true
                        }
                    }
                    .onTapGesture(count: 1) {
                        self.showFullImage = true
                    }
                    .sheet(isPresented: self.$showFullImage) {
                        self.currentPage()
                    }
                    .frame(width: self.width, height: self.height)
                    .simultaneousGesture(pageArrayViews.count > 1 ? drag : nil)
                } else {
                    // AppChrome()
                }
        }
        
    }
    
    
    func blendImage(img : Image) {
        let rect = CGRect(x: 0, y: 0, width: 414, height:414)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 414, height: 414))
        
        let result = renderer.image { ctx in
            // fill the background with white so that translucent colors get lighter
            UIColor.white.set()
            ctx.fill(rect)
            
            img.renderingMode(.original)
            img.drawingGroup(opaque: true, colorMode: .linear)
            
        }
    }
    func isLeftEdge()->Bool{
        return curPage == 0
    }
    
    func isRightEdge()->Bool{
        //        let isEnd = curPage == pageArrayViews.count - 1
        //        if(isEnd) {
        //            self.pageViewClass.AtListEnd = true
        //        }
        return curPage == pageArrayViews.count - 1
    }
    
    
    func prevPage()->AnyView{
        if isLeftEdge(){
            return pageArrayViews.last!
        }
        return pageArrayViews[curPage-1]
    }
    
    func currentPage()->AnyView{
        return self.pageArrayViews[curPage]
    }
    
    func incomingPage()->AnyView{
        
        if isRightEdge(){
            return pageArrayViews.first!
        }
        return pageArrayViews[curPage+1]
    }
    
    
    func curPageOffset()->CGFloat{
        switch(state){
        case .idle:
            return 0
        case .dragging:
            return self.curDragOffset
        case .animating:
            
            if abs(endDragOffset) < distToChange{
                return 0
            }
            else{
                return( endDragOffset < 0 ? -1 : 1 ) * self.width
            }
        }
    }
    
    
    
    func prevPageOffset()->CGFloat{
        switch(state){
        case .idle:
            return -self.width
        case .dragging:
            return self.curDragOffset - self.width
        case .animating:
            if abs(endDragOffset) < distToChange{
                return   -self.width
            }
            else{
                return (endDragOffset < 0  ? -2 :  0 ) * self.width
            }
        }
    }
    
    func nextPageOffset()->CGFloat{
        switch(state){
        case .idle:
            return self.width
        case .dragging:
            return self.curDragOffset + self.width
        case .animating:
            if abs(endDragOffset) < distToChange{
                return  self.width
            }
            else{
                return (endDragOffset < 0 ? 0 : 2) * self.width
            }
        }
    }
    
    func culculateNextPage(){
        if endDragOffset < -distToChange {
            if self.curPage != self.pageArrayViews.count-1{
                self.nextPage = self.curPage + 1
            }
            else{
                self.nextPage = 0
            }
        } else if endDragOffset > distToChange {
            if self.curPage == 0{
                self.nextPage =  self.pageArrayViews.count-1
            }
            else{
                self.nextPage -=  1
            }
        }
    }
    
}

//#if DEBUG
//struct PagesViewNNew_Previews: PreviewProvider {
//    static var previews: some View {
//        PageViewNew(width: 414, height: 309)
//    }
//}
//#endif

@available(iOS 13.0, *)
public struct PageControl: View{
    
    public var defaultImage: Image
    public var selectedImage: Image
    public var count: Int = 0
    public var curPage: Int
    
    public var body: some View {
        HStack{
            ForEach(0..<count) { i in
                self.curPage == i ? self.selectedImage.frame(width:10, height:10).foregroundColor(.white) :  self.defaultImage.frame(width:10, height:10).foregroundColor(.white)
            }
        }.background(Color.yellow)
    }
}
@available(iOS 13.0, *)
class PageViewClass: ObservableObject {
    
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    var AtListEnd : Bool = false {
        willSet {
            self.objectWillChange.send()
        }
    }
}
@available(iOS 13.0, *)
var actionHandler: (() -> Void)?
@available(iOS 13.0, *)
extension PageViewNew {
    public func onDoubleTap(handler: @escaping () -> Void) -> PageViewNew {
        actionHandler = handler
        return self
    }
    
    public func resizeImage() -> PageViewNew {
//        guard let abc = self.currentPage() as? Image else {
//            return self
//        }
        return self
    }
    
}

//Only for image View

//import SwiftUI
//
//struct PageViewNew<Page: View>: View {
//
//    @EnvironmentObject var TheEnvironment: TTSEnvironment
//    var width: CGFloat
//    var height: CGFloat
//
//
//    @State var curDragOffset: CGFloat = 0
//    @State var endDragOffset: CGFloat = 0
//
//    @State var curPage: Int = 0
//    @State var nextPage: Int = 0
//    @State var images:[Page] = []
//    @State var finished:Bool = false
//    @State var loopMode: Bool = true
//    @State var ShowFullImage: Bool = false
//    var animDuration: TimeInterval = 0.3
//    var distToChange: CGFloat = 50
//
//    enum ScrollState{
//        case idle
//        case dragging
//        case animating
//    }
//
//    @State var state: ScrollState = .idle
//
//
//    var body: some View {
//
//        let drag = DragGesture()
//            .onChanged {
//                self.curDragOffset = $0.translation.width;
//                self.state = .dragging
//        }
//
//        .onEnded { theGesture in
//            withAnimation(.linear(duration: self.animDuration)) {
//
//                self.endDragOffset = theGesture.translation.width
//                self.state = .animating
//                self.culculateNextPage()
//            }
//
//            Timer.scheduledTimer(withTimeInterval: self.animDuration, repeats: false) {_ in
//                if self.state == .animating{
//                    self.state = .idle
//                }
//                self.curPage = self.nextPage
//            }
//        }
//
//        return
//
//            Group {
//                if finished == false {
//                    ZStack{
//
//                        currentPage().offset(x: curPageOffset()).frame(width: self.TheEnvironment.ScreenWidth, height: self.height).scaledToFill().clipped()
//
//                    if (images.count > 1){
//
//                        prevPage().offset(x:prevPageOffset()).frame(width: self.TheEnvironment.ScreenWidth, height: self.height).scaledToFill().clipped()
//
//                        incomingPage()
//                            .offset(x: nextPageOffset()).frame(width: self.TheEnvironment.ScreenWidth, height: self.height).scaledToFill().clipped()
//
//                        PageControl(defaultImage: Image(systemName: "circle")
//                                                        .resizable()
//                            , selectedImage: Image(systemName: "circle.fill").resizable(), count: images.count, curPage: self.curPage).offset(y: height * 0.4)
//                    }
//                    if loopMode == false {
//                        HStack {
//                        Spacer()
//                    Button(action: { self.finished = true
//                        UserDefaults.standard.set(true, forKey: "AfterFirstRun")
//                     }) { Text("Skip")}
//                        }.padding(.leading)
//                .padding(.trailing)
//                            .offset(y: (self.height/2) - 30)
//                .font(.subheadline)
//                .foregroundColor(.black)
//                        }
//                }
//                .onTapGesture(count: 2) {
//                            self.ShowFullImage = true
//                        }
//                    .sheet(isPresented: self.$ShowFullImage) {
//                        self.currentPage().environmentObject(self.TheEnvironment)
//                    }
//                .frame(width: self.width, height: self.height)
//                    .simultaneousGesture(images.count > 1 ? drag : nil)
//                } else {
//                    AppChrome()
//                }
//        }
//
//    }
//
//    func isLeftEdge()->Bool{
//        return curPage == 0
//    }
//
//    func isRightEdge()->Bool{
//        return curPage == images.count - 1
//    }
//
//
//    func prevPage()->Page{
//        if isLeftEdge(){
//            return images.last!
//        }
//        return images[curPage-1]
//    }
//
//    func currentPage()->Page{
//         return self.images[curPage]
//    }
//
//    func incomingPage()->Page{
//
//        if isRightEdge(){
//            return images.first!
//        }
//        return images[curPage+1]
//    }
//
//
//    func curPageOffset()->CGFloat{
//        switch(state){
//        case .idle:
//            return 0
//        case .dragging:
//            return self.curDragOffset
//        case .animating:
//
//            if abs(endDragOffset) < distToChange{
//                return 0
//            }
//            else{
//                return( endDragOffset < 0 ? -1 : 1 ) * self.width
//            }
//        }
//    }
//
//
//    func prevPageOffset()->CGFloat{
//        switch(state){
//        case .idle:
//            return -self.width
//        case .dragging:
//            return self.curDragOffset - self.width
//        case .animating:
//            if abs(endDragOffset) < distToChange{
//                return   -self.width
//            }
//            else{
//                return (endDragOffset < 0  ? -2 :  0 ) * self.width
//            }
//        }
//    }
//
//    func nextPageOffset()->CGFloat{
//        switch(state){
//        case .idle:
//            return self.width
//        case .dragging:
//            return self.curDragOffset + self.width
//        case .animating:
//            if abs(endDragOffset) < distToChange{
//                return  self.width
//            }
//            else{
//                return (endDragOffset < 0 ? 0 : 2) * self.width
//            }
//        }
//    }
//
//    func culculateNextPage(){
//        if endDragOffset < -distToChange {
//            if self.curPage != self.images.count-1{
//                self.nextPage = self.curPage + 1
//            }
//            else{
//                self.nextPage = 0
//            }
//        } else if endDragOffset > distToChange {
//            if self.curPage == 0{
//                self.nextPage =  self.images.count-1
//            }
//            else{
//                self.nextPage -=  1
//            }
//        }
//    }
//
//}
//
////struct PageViewNew_Previews: PreviewProvider {
////
////    static var previews: some View {
////        PageViewNew(height: 309)
////    }
////}
//
//
//struct PageControl: View{
//
//    var defaultImage: Image
//    var selectedImage: Image
//    var count: Int = 0
//    var curPage: Int
//
//    var body: some View {
//        HStack{
//            ForEach(0..<count) { i in
//                self.curPage == i ? self.selectedImage.frame(width:10, height:10).foregroundColor(.white) :  self.defaultImage.frame(width:10, height:10).foregroundColor(.white)
//            }
//        }
//    }
//}
//
