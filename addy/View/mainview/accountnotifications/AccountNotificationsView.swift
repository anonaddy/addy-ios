//
//  AccountNotificationsView.swift
//  addy
//
//  Created by Stijn van de Water on 23/08/2024.
//


import SwiftUI
import addy_shared

struct AccountNotificationsView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @StateObject var accountNotificationsViewModel = AccountNotificationsViewModel()
    
    enum ActiveAlert {
        case error
    }
    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    
    @State private var accountNotificationToShow: AccountNotifications? = nil
    
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
  
    @State var horizontalSize: UserInterfaceSizeClass
    var onRefreshGeneralData: (() -> Void)? = nil

    @Environment(\.dismiss) var dismiss

    init(horizontalSize: UserInterfaceSizeClass?, onRefreshGeneralData: (() -> Void)? = nil) {
        self.horizontalSize = horizontalSize ?? UserInterfaceSizeClass.compact
        self.onRefreshGeneralData = onRefreshGeneralData
    }
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        NavigationStack{
            List {
                if let accountNotifications = accountNotificationsViewModel.accountNotifications{
                    if !accountNotifications.data.isEmpty {
                        Section {
                            
                            ForEach (accountNotifications.data) { accountNotification in
                                VStack(alignment: .leading) {
                                    VStack(alignment: .leading) {
                                        Text(accountNotification.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .lineLimit(2)
                                        Text(DateTimeUtils.turnStringIntoLocalString(accountNotification.created_at))
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                            .italic()
                                            .padding(.bottom, 4)
                                        
                                        Text(accountNotification.textAsMarkdown())
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .lineLimit(4)
                                    }.padding(EdgeInsets())
                                    Button(action: {
                                        self.accountNotificationToShow = accountNotification
                                    }) {
                                        HStack {
                                            Text(String(localized: "view_details"))
                                                .font(.system(size: 16, weight: .medium))
                                            Spacer()
                                            Image(systemName: "text.justify.leading")
                                        }
                                        .padding(.horizontal).padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }header: {
                            HStack(spacing: 6){
                                Text(String(localized: "all_account_notifications"))
                                
                                
                                if (accountNotificationsViewModel.isLoading){
                                    ProgressView()
                                        .frame(maxHeight: 4)
                                    
                                }
                            }
                            // When this section is visible that means there is data. Make sure to update the amount of account notifications in cache
                        }.onAppear(perform: {
                            updateTheCacheANCount(count: accountNotifications.data.count)
                        })
                    }
                }
                
            }.refreshable {
                if horizontalSize == .regular {
                    // When in regular size (tablet) mode, refreshing this also ask the mainView to update general data
                    self.onRefreshGeneralData?()
                }
                
                await self.accountNotificationsViewModel.getAccountNotifications()
            }
            .sheet(item: $accountNotificationToShow) { accountNotification in
                NavigationStack {
                    AccountNotificationBottomSheet(accountNotification: accountNotification)
                }
                .presentationDetents([.large])
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
            .overlay(Group {
                
                
                // If there is an accountNotifications (aka, if the list is visible)
                if let accountNotifications = accountNotificationsViewModel.accountNotifications{
                    if accountNotifications.data.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "no_account_notifications"), systemImage: "bell.badge.fill")
                        } description: {
                            Text(String(localized: "no_account_notifications_desc"))
                        }
                    }
                } else {
                    // If there is NO accountNotifications (aka, if the list is not visible)
                    
                    // No accountNotifications, check if there is an error
                    if (accountNotificationsViewModel.networkError != ""){
                        
                        
                            // Error screen
                            ContentUnavailableView {
                                Label(String(localized: "something_went_wrong_retrieving_account_notifications"), systemImage: "wifi.slash")
                            } description: {
                                Text(accountNotificationsViewModel.networkError)
                            } actions: {
                                Button(String(localized: "try_again")) {
                                    Task {
                                        await accountNotificationsViewModel.getAccountNotifications()
                                    }
                                }
                            }
                        
                        
                    } else {
                        // No accountNotifications and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_account_notifications"), systemImage: "globe")
                            } description: {
                                Text(String(localized: "obtaining_desc"))
                            }
                            
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight:50)
                            Spacer()
                        }
                    }
                    
                }
            })
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(String(localized: "account_notifications"))
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Label(String(localized: "dismiss"), systemImage: "xmark.circle.fill")
                }
            }
            
        }
        .onAppear(perform: {
            if let accountNotifications = accountNotificationsViewModel.accountNotifications{
                if (accountNotifications.data.isEmpty) {
                    Task {
                        await accountNotificationsViewModel.getAccountNotifications()
                    }
                }
            }
        })
    }
    
    private func updateTheCacheANCount(count: Int){
        // Set the count of account notifications so that we can use it for the backgroundservice AND mark this a read for the badge
        MainViewState.shared.encryptedSettingsManager.putSettingsInt(
            key: .backgroundServiceCacheAccountNotificationsCount,
            int: count
        )
            
    }
    
}
