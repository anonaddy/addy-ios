//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Charts


struct HomeView: View {

    @EnvironmentObject var mainViewState: MainViewState
    @Binding var horizontalSize: UserInterfaceSizeClass
    
    enum ActiveAlert {
        case error
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @State private var chartData: AddyChartData? = nil
    
    var onRefreshGeneralData: (() -> Void)? = nil

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        
        NavigationStack(){
            ZStack {
                Rectangle()
                    .fill(.nightMode)
                    .opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack{
                        if let chartData = chartData {
                            ForEach(1..<666) { i in
                                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                            }
                        }

                       

                        
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [Color("SecondaryColor"), Color("AccentColor")]),
                                       startPoint: .top, endPoint: .bottom))
            .navigationTitle(String(localized: "home"))
            .toolbar {
                ProfilePicture().environmentObject(mainViewState)
                FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
            }
        }.refreshable {
            // When refreshing aliases also ask the mainView to update general data
            self.onRefreshGeneralData?()
            
            await self.getChartData()
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .error:
                return Alert(
                    title: Text(errorAlertTitle),
                    message: Text(errorAlertMessage)
                )
            }
        }
        .task {
            await getChartData()
        }
        
           


    }
    
    private func getChartData() async {
        let networkHelper = NetworkHelper()
        do {
            let chartData = try await networkHelper.getChartData()
            if var chartData = chartData {
                
#if DEBUG
                chartData.forwardsData = [45,43,53,53,23,42,54]
                chartData.sendsData = [12,26,26,32,12,32,12]
                chartData.repliesData = [12,21,24,24,12,23,2]
#endif
                
                withAnimation {
                    self.chartData = chartData
                }
            } else {
                activeAlert = .error
                showAlert = true
            }
        } catch {
            print("Failed to get chartData: \(error)")
        }
    }
}



#Preview {
    HomeView(horizontalSize: .constant(.compact))
}
