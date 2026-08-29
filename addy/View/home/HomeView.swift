//
//  HomeView.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import addy_shared
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var mainViewState: MainViewState
    @EnvironmentObject var aliasesViewState: AliasesViewState

    @StateObject private var viewModel = HomeViewModel()
    @Binding var horizontalSize: UserInterfaceSizeClass

    var onRefreshGeneralData: (() -> Void)? = nil

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: .systemBackground))
                    .opacity(0.6)
                    .edgesIgnoringSafeArea(.all)

                if let userResource = mainViewState.userResource {
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                VStack {
                                    HStack {
                                        Text(String(localized: "monthly_bandwidth"))
                                            .fontWeight(.medium)
                                            .lineSpacing(24)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(viewModel.bandwidthText(userResource: userResource))
                                            .fontWeight(.medium)
                                            .lineSpacing(24)
                                            .foregroundColor(.white)
                                            .opacity(0.80)
                                    }

                                    GradientProgressBar(value: $viewModel.progress)
                                        .frame(maxWidth: .infinity, minHeight: 28)
                                        .onAppear {
                                            viewModel.updateProgress(userResource: mainViewState.userResource)
                                        }
                                        .onReceive(mainViewState.userResourceChanged) { _ in
                                            viewModel.updateProgress(userResource: mainViewState.userResource)
                                        }
                                        .apply {
                                            // Apply the shimmering effect when no limit
                                            if (userResource.bandwidth_limit ?? 0) == 0 {
                                                $0.shimmering(animation: .easeInOut(duration: 7).repeatForever(),
                                                              gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.5), .white.opacity(0.5), .white.opacity(0.6), .white.opacity(0.5)]))
                                            } else {
                                                $0
                                            }
                                        }

                                }.padding()
                                    .frame(maxWidth: .infinity, maxHeight: 92)
                                    .background(.homeColor1)
                                    .cornerRadius(16)
                                    .shadow(
                                        color: Color(red: 0, green: 0, blue: 0, opacity: 0.08), radius: 12
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "statistics"))
                                    .fontWeight(.semibold)
                                    .opacity(0.60)
                                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                HStack(alignment: .top, spacing: 4) {
                                    HomeCardView(title: String(localized: "emails_forwarded"), value: userResource.total_emails_forwarded, backgroundColor: .homeColor1, systemImage: "tray", systemImageOpacity: 1.0)

                                    HomeCardView(title: String(localized: "emails_blocked"), value: userResource.total_emails_blocked, backgroundColor: .homeColor1, systemImage: "slash.circle", systemImageOpacity: 1.0)
                                }

                                HStack(alignment: .top, spacing: 4) {
                                    HomeCardView(title: String(localized: "email_replies"), value: userResource.total_emails_replied, backgroundColor: .homeColor1, systemImage: "arrow.turn.up.left", systemImageOpacity: 1.0)

                                    HomeCardView(title: String(localized: "emails_sent"), value: userResource.total_emails_sent, backgroundColor: .homeColor1, systemImage: "paperplane", systemImageOpacity: 1.0)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "aliases", bundle: Bundle(for: SharedData.self)))
                                    .fontWeight(.semibold)
                                    .opacity(0.60)
                                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                HStack(alignment: .top, spacing: 4) {
                                    HomeCardView(title: String(localized: "total_aliases"), value: userResource.total_aliases, backgroundColor: .homeColor2, systemImage: "at", systemImageOpacity: 0.5) {
                                        mainViewState.selectedTab = .aliases
                                        aliasesViewState.applyFilterChip = "filter_all_aliases"
                                    }

                                    HomeCardView(title: String(localized: "active"), value: userResource.total_active_aliases, backgroundColor: .homeColor2, systemImage: "at", systemImageOpacity: 0.5) {
                                        mainViewState.selectedTab = .aliases
                                        aliasesViewState.applyFilterChip = "filter_active_aliases"
                                    }
                                }

                                HStack(alignment: .top, spacing: 4) {
                                    HomeCardView(title: String(localized: "inactive"), value: userResource.total_inactive_aliases, backgroundColor: .homeColor2, systemImage: "at", systemImageOpacity: 0.5) {
                                        mainViewState.selectedTab = .aliases
                                        aliasesViewState.applyFilterChip = "filter_inactive_aliases"
                                    }

                                    HomeCardView(title: String(localized: "deleted"), value: userResource.total_deleted_aliases, backgroundColor: .homeColor2, systemImage: "at", systemImageOpacity: 0.5) {
                                        mainViewState.selectedTab = .aliases
                                        aliasesViewState.applyFilterChip = "filter_deleted_aliases"
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "recipients"))
                                    .fontWeight(.semibold)
                                    .opacity(0.60)
                                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                HomeCardView(title: String(localized: "total_recipients"), value: userResource.recipient_count, backgroundColor: .homeColor3, systemImage: "person.2.fill", systemImageOpacity: 0.5) {
                                    mainViewState.selectedTab = .recipients
                                }
                            }
                        }.padding(.bottom).padding(.horizontal)
                    }
                }

            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color("HomeColor2"), Color("AccentColor")]),
                                           startPoint: .top, endPoint: .bottom))
                .navigationTitle(String(localized: "home"))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ProfilePicture().environmentObject(mainViewState)
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(placement: .topBarLeading)
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        FailedDeliveriesIcon(horizontalSize: $horizontalSize).environmentObject(mainViewState)
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        AccountNotificationsIcon().environmentObject(mainViewState)
                    }
                }
        }.refreshable {
            // When refreshing aliases also ask the mainView to update general data
            self.onRefreshGeneralData?()
        }
    }
}

#Preview {
    HomeView(horizontalSize: .constant(.compact))
}
