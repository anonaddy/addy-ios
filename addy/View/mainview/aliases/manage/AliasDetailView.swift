//
//  AliasDetailView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import SwiftUI
import addy_shared
import Lottie
import UniformTypeIdentifiers

struct AliasDetailView: View {
    
    
    let aliasId: String
    let aliasEmail: String
    
    @State private var showReachedMaxAliasesWatchedAlert = false
    
    @State private var alias: Aliases? = nil
    @State private var isAliasActive: Bool = false
    @State private var isSwitchingAliasActiveState: Bool = false
    @State private var isAliasBeingWatched: Bool = false
    @State private var isPresentingEditAliasDescriptionBottomSheet = false
    
    @State private var copiedToClipboard: Bool = false
    
    
    @State private var chartData: [Double] = [0,0,0,0]
    
    init(aliasId: String, aliasEmail: String) {
        self.aliasId = aliasId
        self.aliasEmail = aliasEmail
    }
    
    
    var body: some View {
        
        if let alias = alias {
            Form {
                Section {
                    VStack(alignment: .leading){
                        HStack{
                            BarChart()
                                .data(chartData)
                                .chartStyle(ChartStyle(backgroundColor: .white,
                                                       foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                         ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                         ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                         ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                .frame(maxWidth: .infinity)
                            
                            
                            Spacer()
                            
                            VStack(alignment: .leading){
                                Spacer()
                                
                                Label(title: {
                                    Text(String(format: String(localized: "d_forwarded"), "\(alias.emails_forwarded)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "tray")
                                        .foregroundColor(.portalOrange)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_replied"), "\(alias.emails_replied)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "arrow.turn.up.left")
                                        .foregroundColor(.easternBlue)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_sent"), "\(alias.emails_sent)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "paperplane")
                                        .foregroundColor(.portalBlue)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                Label(title: {
                                    Text(String(format: String(localized: "d_blocked"), "\(alias.emails_blocked)"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.gray)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                    
                                }, icon: {
                                    Image(systemName: "slash.circle")
                                        .foregroundColor(.softRed)
                                        .font(.system(size: 18, weight: .bold))
                                } )
                                Spacer()
                                
                                
                            }
                            .padding(.leading, 15)
                            .labelStyle(MyAliasLabelStyle())
                        }
                        Spacer()
                        HStack {
                            
                            Button(action: {
                                self.copyToClipboard(alias: alias)
                            }) {
                                Label(copiedToClipboard ? String(localized: "copied") : String(localized: "copy_alias"), systemImage: copiedToClipboard ? "checkmark": "clipboard")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 16)
                                    .font(.system(size: 16))
                                
                                
                            }
                            .contentTransition(.symbolEffect(.replace))
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.7))
                            .cornerRadius(12)
                            Spacer()
                            Button(action: {
                                //self.copyToClipboard(alias: alias)
                            }) {
                                Label(String(localized: "send_mail"), systemImage: "paperplane")
                                    .foregroundColor(.white)
                                    .frame(maxWidth:.infinity, maxHeight: 16)
                                    .font(.system(size: 16))
                                
                                
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.7))
                            .cornerRadius(12)
                        }.padding(.top, 8)
                        
                        
                    }.frame(height: 200)}.buttonStyle(PlainButtonStyle())
                
                Section {
                    
                    AddyToggle(isOn: $isAliasActive, isLoading: isSwitchingAliasActiveState, title: alias.active ? String(localized: "alias_activated") : String(localized: "alias_deactivated"), description: String(localized: "watch_alias_desc"))
                        .onAppear {
                            self.isAliasActive = alias.active
                        }
                        .onChange(of: isAliasActive) {
                            
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAliasActive != alias.active){
                                //perform your action here...
                                self.isSwitchingAliasActiveState = true
                                
                                if (alias.active){
                                    DispatchQueue.global(qos: .background).async {
                                        self.deactivateAliasAlias(alias: alias)
                                    }
                                } else {
                                    DispatchQueue.global(qos: .background).async {
                                        self.activateAliasAlias(alias: alias)
                                    }
                                }
                            }
                            
                        }
                    
                    AddyToggle(isOn: $isAliasBeingWatched, title: String(localized: "watch_alias"), description: String(localized: "watch_alias_desc"))
                        .onAppear {
                            self.isAliasBeingWatched = AliasWatcher().getAliasesToWatch().contains(aliasId)
                        }
                        .onChange(of: isAliasBeingWatched) {
                            // Only fire when the value is NOT the same as the value already in the model
                            if (isAliasBeingWatched != AliasWatcher().getAliasesToWatch().contains(aliasId)){
                                if (AliasWatcher().getAliasesToWatch().contains(aliasId)){
                                    AliasWatcher().removeAliasToWatch(alias: aliasId)
                                } else {
                                    if (AliasWatcher().addAliasToWatch(alias: aliasId)) {
                                        
                                    } else {
                                        // Could not add to watchlist (watchlist reached max?)
                                        showReachedMaxAliasesWatchedAlert = true
                                    }
                                }
                            }
                        }
                    
                    AddySection(title: String(localized: "description"), description: alias.description ?? String(localized: "alias_no_description"), leadingSystemimage: nil, trailingSystemimage: "pencil")
                        .onTapGesture {
                            isPresentingEditAliasDescriptionBottomSheet = true
                        }
                }header: {
                    Text(String(localized: "general"))
                }
            }
            .navigationTitle(self.aliasEmail)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingEditAliasDescriptionBottomSheet) {
                EditAliasDescriptionBottomSheet(aliasId: alias.id, description: alias.description ?? ""){ alias in
                    self.alias = alias
                    isPresentingEditAliasDescriptionBottomSheet = false

                }
            }
            .alert(isPresented: $showReachedMaxAliasesWatchedAlert, content: {
                Alert(title: Text(String(localized: "aliaswatcher_max_reached")), message: Text(String(localized: "aliaswatcher_max_reached_desc")), dismissButton: .default(Text(String(localized: "understood"))))
            })
            
        } else {
            VStack(spacing: 20) {
                LottieView(animation: .named("gray_ic_loading_logo.shapeshifter"))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .animationSpeed(Double(2))
                    .frame(maxHeight: 128)
                    .opacity(0.5)
                
            }.task {
                getAlias(aliasId: self.aliasId)
            }
            .navigationTitle(self.aliasEmail)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func updateUi(alias: Aliases){
        var aliasTotalCount =  Double(alias.emails_forwarded + alias.emails_replied + alias.emails_sent + alias.emails_blocked)
        aliasTotalCount = aliasTotalCount != 0.0 ? aliasTotalCount : 10.0 // To prevent dividing by 0
        
        
        let aliasEmailForwardedProgress =  (Double(alias.emails_forwarded) / aliasTotalCount) * 100
        let aliasEmailRepliedProgress = (Double(alias.emails_replied) / aliasTotalCount) * 100
        let aliasEmailSentProgress = (Double(alias.emails_sent) / aliasTotalCount) * 100
        let aliasEmailBlockedProgress = (Double(alias.emails_blocked) / aliasTotalCount) * 100
        
        self.chartData = [aliasEmailForwardedProgress, aliasEmailRepliedProgress, aliasEmailSentProgress, aliasEmailBlockedProgress]
        
        
    }
    
    func copyToClipboard(alias: Aliases) {
        UIPasteboard.general.setValue(alias.email,forPasteboardType: UTType.plainText.identifier)
        
        
        self.copiedToClipboard = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.copiedToClipboard = false
            
        }
        
    }
    
    private func activateAliasAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.activateSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                self.isSwitchingAliasActiveState = false
                
                if let alias = alias {
                    self.alias = alias
                    self.isAliasActive = true
                } else {
                    self.isAliasActive = false
                    print("Error: \(String(describing: error))")
                    //self.showError = true
                }
            }
        },aliasId: alias.id)
    }
    
    private func deactivateAliasAlias(alias:Aliases) {
        let networkHelper = NetworkHelper()
        networkHelper.deactivateSpecificAlias(completion: { result in
            DispatchQueue.main.async {
                self.isSwitchingAliasActiveState = false
                
                if result == "204" {
                    self.alias?.active = false
                    self.isAliasActive = false
                } else {
                    self.isAliasActive = true
                    print("Error: \(String(describing: result))")
                    //self.showError = true
                }
            }
        },aliasId: alias.id)
    }
    
    private func getAlias(aliasId: String) {
        let networkHelper = NetworkHelper()
        networkHelper.getSpecificAlias(completion: { alias, error in
            DispatchQueue.main.async {
                if let alias = alias {
                    withAnimation {
                        self.alias = alias
                        self.updateUi(alias: alias)
                    }

                } else {
                    print("Error: \(String(describing: error))")
                    //self.showError = true
                }
            }
        },aliasId: aliasId)
    }
}


#Preview {
    AliasDetailView(aliasId: "6a866f49-5a0b-4c7e-bc45-f46bf019c4ed", aliasEmail: "PLACEHOLDER")
}
