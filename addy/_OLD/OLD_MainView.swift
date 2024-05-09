//
//  MainView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import ScalingHeaderScrollView

class OldMainViewState: ObservableObject {
    @Published var apiKey: String? = SettingsManager(encrypted: true).getSettingsString(key: .apiKey)
    @Published var encryptedSettingsManager = SettingsManager(encrypted: true)
    
    @Published var userResourceData: String? {
        didSet {
            userResourceData.map { encryptedSettingsManager.putSettingsString(key: .userResource, string: $0) }
        }
    }
    
    var userResource: UserResource? {
        get {
            if let jsonString = userResourceData,
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResource.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userResourceData = jsonString
                }
            }
        }
    }
    
    @Published var userResourceExtendedData: Data? {
        didSet {
            if let data = userResourceExtendedData,
               let jsonString = String(data: data, encoding: .utf8) {
                encryptedSettingsManager.putSettingsString(key: .userResourceExtended, string: jsonString)
            }
        }
    }
    
    var userResourceExtended: UserResourceExtended? {
        get {
            if let jsonString = encryptedSettingsManager.getSettingsString(key: .userResourceExtended),
               let jsonData = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                return try? decoder.decode(UserResourceExtended.self, from: jsonData)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(newValue) {
                    userResourceExtendedData = jsonData
                }
            }
        }
    }

}


struct OldMainView: View {
    @StateObject private var mainViewState = MainViewState()
    @StateObject private var appBarViewState = AppBarViewState()
@State private var isLoading = false
    
    
    @ObservedObject private var viewModel = ProfileScreenViewModel()
        @Environment(\.presentationMode) var presentationMode

        @State var progress: CGFloat = 0
        
        private let minHeight = 110.0
        private let maxHeight = 220.0
    
    @State private var selectedTab = 0

    
    var body: some View {
        if (mainViewState.userResourceData == nil){
            SplashView().environmentObject(mainViewState)
        } else {
            ZStack {
                
                ScalingHeaderScrollView {
                    ZStack {
                        Color.white.edgesIgnoringSafeArea(.all)
                        largeHeader(progress: progress)
                    }
                } content: {
                    //profilerContentView
                    if selectedTab == 0 {
                        profilerContentView
                    } else if selectedTab == 1 {
                        Text("Tab 2 content")
                    } else if selectedTab == 2 {
                        Text("Tab 3 content")
                    }
                }
                .height(min: minHeight, max: maxHeight)
                .collapseProgress($progress)
                .allowsHeaderGrowth()
                .pullToRefresh(isLoading: $isLoading) {
                            print("RELOAD")
                        }
                
                topButtons
                
                VStack {
                                Spacer()
                                TabBar(selectedTab: $selectedTab)
                            }

            }
            .ignoresSafeArea()
            
//            VStack {
//                AppBarView().environmentObject(appBarViewState)
//                Spacer()
//                BottomNavigationView().environmentObject(mainViewState)
//            }
        }
        
    }
    
    struct TabBar: View {
        @Binding var selectedTab: Int

        var body: some View {
            HStack {
                Button(action: { selectedTab = 0 }) {
                    VStack {
                        Image(systemName: "1.square.fill")
                        Text("Tab 1")
                    }
                }
                .padding()
                .background(selectedTab == 0 ? Color.blue : Color.clear)
                .cornerRadius(10)

                Button(action: { selectedTab = 1 }) {
                    VStack {
                        Image(systemName: "2.square.fill")
                        Text("Tab 2")
                    }
                }
                .padding()
                .background(selectedTab == 1 ? Color.blue : Color.clear)
                .cornerRadius(10)

                Button(action: { selectedTab = 2 }) {
                    VStack {
                        Image(systemName: "3.square.fill")
                        Text("Tab 3")
                    }
                }
                .padding()
                .background(selectedTab == 2 ? Color.blue : Color.clear)
                .cornerRadius(10)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
    }
    
    
    private var topButtons: some View {
        VStack {
            HStack {
                Button("", action: { self.presentationMode.wrappedValue.dismiss() })
                    .buttonStyle(CircleButtonStyle(imageName: "arrow.backward"))
                    .padding(.leading, 17)
                    .padding(.top, 50)
                Spacer()
                Button("", action: { print("Info") })
                    .buttonStyle(CircleButtonStyle(imageName: "ellipsis"))
                    .padding(.trailing, 17)
                    .padding(.top, 50)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }

    private var hireButton: some View {
        VStack {
            Spacer()
            ZStack {
                VisualEffectView(effect: UIBlurEffect(style: .regular))
                    .frame(height: 180)
                    .padding(.bottom, -100)
                HStack {
                    Button("Hire", action: { print("hire") })
                        .buttonStyle(HireButtonStyle())
                        .padding(.horizontal, 15)
                        .frame(width: 396, height: 60, alignment: .bottom)
                }
            }
        }
        .ignoresSafeArea()
        .padding(.bottom, 40)
    }

    private var smallHeader: some View {
        HStack(spacing: 12.0) {
            Image(viewModel.avatarImage)
                .resizable()
                .frame(width: 40.0, height: 40.0)
                .clipShape(RoundedRectangle(cornerRadius: 6.0))

            Text(viewModel.userName)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
        }
    }

    private func largeHeader(progress: CGFloat) -> some View {
        ZStack {
            Image(viewModel.avatarImage)
                .resizable()
                .scaledToFill()
                .frame(height: maxHeight)
                .opacity(1 - progress)
            
            VStack {
                Spacer()
                
                HStack(spacing: 4.0) {
                    Capsule()
                        .frame(width: 40.0, height: 3.0)
                        .foregroundColor(.white)
                    
                    Capsule()
                        .frame(width: 40.0, height: 3.0)
                        .foregroundColor(.white.opacity(0.2))
                    
                    Capsule()
                        .frame(width: 40.0, height: 3.0)
                        .foregroundColor(.white.opacity(0.2))
                }
                
                ZStack(alignment: .leading) {

                    VisualEffectView(effect: UIBlurEffect(style: .regular))
                        .mask(Rectangle().cornerRadius(40, corners: [.topLeft, .topRight]))
                        .offset(y: 10.0)
                        .frame(height: 80.0)

                    RoundedRectangle(cornerRadius: 40.0, style: .circular)
                        .foregroundColor(.clear)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.white.opacity(0.0), .white]), startPoint: .top, endPoint: .bottom)
                        )

                    userName
                        .padding(.leading, 24.0)
                        .padding(.top, 10.0)
                        .opacity(1 - max(0, min(1, (progress - 0.75) * 4.0)))

                    smallHeader
                        .padding(.leading, 85.0)
                        .opacity(progress)
                        .opacity(max(0, min(1, (progress - 0.75) * 4.0)))
                }
                .frame(height: 80.0)
            }
        }
    }

    private var profilerContentView: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(1..<666) { i in
                        Text("Hello World")
                    }
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var personalInfo: some View {
            VStack(alignment: .leading) {
                profession
                address
            }
        }

        private var userName: some View {
            Text(viewModel.userName)
        }

        private var profession: some View {
            Text(viewModel.profession)
        }

        private var address: some View {
            Text(viewModel.address)
        }

        private var reviews: some View {
            HStack(alignment: .center , spacing: 8) {
                Image("Star")
                    .offset(y: -3)
                grade
                reviewCount
            }
        }

        private var grade: some View {
            Text(String(format: "%.1f", viewModel.grade))
        }

        private var reviewCount: some View {
            Text("\(viewModel.reviewCount) reviews")
        }

        private var skills: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Skills")
                HStack {
                    ForEach((0 ..< 3)) { col in
                        skillView(for: viewModel.skils[col])
                    }
                }
                HStack {
                    ForEach((0 ..< 3)) { col in
                        skillView(for: viewModel.skils[col + 3])
                    }
                }
            }
        }

        func skillView(for skill: String) -> some View {
            Text(skill)
                .padding(.vertical, 5)
                .padding(.horizontal, 14)
                .lineLimit(1)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red))
                )
        }

        private var description: some View {
            Text(viewModel.description)
        }

        private var portfolio: some View {
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 100)),
                GridItem(.flexible(minimum: 100)),
                GridItem(.flexible(minimum: 100))
            ]) {
                ForEach(viewModel.portfolio, id: \.self) { imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }
            }
        }

}




#Preview {
    MainView()
}
