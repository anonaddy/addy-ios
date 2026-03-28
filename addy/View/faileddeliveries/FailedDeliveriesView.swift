//
//  FailedDeliveriesView.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import addy_shared
import SwiftUI

struct FailedDeliveriesView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @StateObject var failedDeliveriesViewModel = FailedDeliveriesViewModel()

    enum ActiveAlert {
        case error, deleteFailedDelivery
    }

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false

    @State private var failedDeliveryToDelete: FailedDeliveries? = nil
    @State private var failedDeliveryToShow: FailedDeliveries? = nil

    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""

    @State var selectedFilterChip: String = "all"
    @State var filterChips: [AddyChipModel] = []

    @State var horizontalSize: UserInterfaceSizeClass
    var onRefreshGeneralData: (() -> Void)?

    @Environment(\.dismiss) var dismiss


    init(horizontalSize: UserInterfaceSizeClass?, onRefreshGeneralData: (() -> Void)? = nil) {
        self.horizontalSize = horizontalSize ?? UserInterfaceSizeClass.compact
        self.onRefreshGeneralData = onRefreshGeneralData
    }

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif
        NavigationStack {
            List {
                if let failedDeliveries = failedDeliveriesViewModel.failedDeliveries {
                    if !failedDeliveries.data.isEmpty {
                        Section {
                            ForEach(failedDeliveries.data) { failedDelivery in
                                VStack(alignment: .leading) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Text(String(localized: "alias"))
                                                    .font(.system(size: 16, weight: .medium))
                                                
                                                Text(failedDelivery.getEmailTypeLabel().uppercased())
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor.opacity(0.1))
                                                    .foregroundColor(.accentColor)
                                                    .cornerRadius(4)
                                            }
                                            Text(failedDelivery.alias_email ?? "")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text(String(localized: "created"))
                                                .font(.system(size: 16, weight: .medium))
                                            Text(DateTimeUtils.convertStringToLocalTimeZoneString(failedDelivery.created_at))
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    HStack {
                                        Text(String(localized: "code"))
                                            .font(.system(size: 16, weight: .medium))
                                        Text(failedDelivery.code)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }.padding(.top, 5)
                                    Button(action: {
                                        self.failedDeliveryToShow = failedDelivery
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
                            }.onDelete(perform: deleteFailedDelivery)

                            if !failedDeliveriesViewModel.hasArrivedAtTheLastPage {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 50)
                                    .onAppear {
                                        failedDeliveriesViewModel.loadMoreContent()
                                    }
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 24) {
                                AddyChipView(chips: $filterChips, selectedChip: $selectedFilterChip, singleLine: true) { onTappedChip in
                                    withAnimation {
                                        selectedFilterChip = onTappedChip.chipId
                                    }

                                    ApplyFilter(chipId: onTappedChip.chipId)
                                }.scrollClipDisabled()

                                HStack(spacing: 6) {
                                    Text(String(localized: "all_failed_deliveries"))

                                    if failedDeliveriesViewModel.isLoading {
                                        ProgressView()
                                            .frame(maxHeight: 4)
                                    }
                                }
                            }
                            // When this section is visible that means there is data. Make sure to update the amount of failed deliveries in cache
                        }.textCase(nil).onAppear(perform: {
                            updateTheCacheFDCount(count: failedDeliveries.meta?.total ?? failedDeliveries.data.count)
                        })
                    }
                }

            }.refreshable {
                if horizontalSize == .regular {
                    // When in regular size (tablet) mode, refreshing aliases also ask the mainView to update general data
                    self.onRefreshGeneralData?()
                }

                await self.failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
            }
            .sheet(item: $failedDeliveryToShow) { failedDelivery in
                NavigationStack {
                    FailedDeliveryBottomSheet(failedDelivery: failedDelivery) {
                        self.failedDeliveryToShow = nil

                        Task {
                            await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
                        }
                    }
                }
                .presentationDetents([.large])
            }
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .deleteFailedDelivery:
                    return Alert(title: Text(String(localized: "delete_failed_delivery")), message: Text(String(localized: "delete_failed_delivery_confirmation_desc")), primaryButton: .destructive(Text(String(localized: "delete"))) {
                        Task {
                            await self.deleteFailedDelivery(failedDelivery: self.failedDeliveryToDelete!)
                        }
                    }, secondaryButton: .cancel {
                        Task {
                            await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
                        }
                    })
                case .error:
                    return Alert(
                        title: Text(errorAlertTitle),
                        message: Text(errorAlertMessage)
                    )
                }
            }
            .overlay(Group {
                // If there is an failedDeliveries (aka, if the list is visible)
                if let failedDeliveries = failedDeliveriesViewModel.failedDeliveries {
                    if failedDeliveries.data.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "no_failed_deliveries"), systemImage: "exclamationmark.triangle.fill")
                        } description: {
                            Text(String(localized: "no_failed_deliveries_desc"))
                        }
                    }
                } else {
                    // If there is NO failedDeliveries (aka, if the list is not visible)

                    // No failedDeliveries, check if there is an error
                    if failedDeliveriesViewModel.networkError != "" {
                        if mainViewState.userResource!.hasUserFreeSubscription() {
                            // Error screen
                            ContentUnavailableView {
                                Label(String(localized: "no_failed_deliveries"), systemImage: "exclamationmark.triangle.fill")
                            } description: {
                                Text(String(localized: "feature_not_available_subscription"))
                            }
                        } else {
                            // Error screen
                            ContentUnavailableView {
                                Label(String(localized: "something_went_wrong_retrieving_failed_deliveries"), systemImage: "wifi.slash")
                            } description: {
                                Text(failedDeliveriesViewModel.networkError)
                            } actions: {
                                Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
                                    Task {
                                        await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
                                    }
                                }
                            }
                        }

                    } else {
                        // No failedDeliveries and no error. It must still be loading...
                        VStack(alignment: .center, spacing: 0) {
                            Spacer()
                            ContentUnavailableView {
                                Label(String(localized: "obtaining_failed_deliveries"), systemImage: "globe")
                            } description: {
                                Text(String(localized: "obtaining_desc", bundle: Bundle(for: SharedData.self)))
                            }

                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 50)
                            Spacer()
                        }
                    }
                }
            })
            .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
            .navigationTitle(String(localized: "failed_deliveries"))
            .toolbar {
                if horizontalSize == .regular {

                    ToolbarItem(placement: .topBarLeading) {
                        ProfilePicture().environmentObject(mainViewState)
                    }

                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(placement: .topBarLeading)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        AccountNotificationsIcon().environmentObject(mainViewState)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label(String(localized: "dismiss"), systemImage: "xmark")
                        }
                    }
                }
            }
        }
        .onAppear(perform: {
            LoadFilter()
            if let failedDeliveries = failedDeliveriesViewModel.failedDeliveries {
                if failedDeliveries.data.isEmpty {
                    Task {
                        await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
                    }
                }
            }
        })
    }

    func ApplyFilter(chipId: String) {
        switch chipId {
        case "inbound":
            failedDeliveriesViewModel.filter = "inbound"
        case "outbound":
            failedDeliveriesViewModel.filter = "outbound"
        case "all":
            failedDeliveriesViewModel.filter = nil
        default:
            failedDeliveriesViewModel.filter = nil
        }

        Task {
            await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
        }
    }

    func LoadFilter() {
        filterChips = GetFilterChips()
    }

    func GetFilterChips() -> [AddyChipModel] {
        return [
            AddyChipModel(chipId: "all", label: String(localized: "filter_all")),
            AddyChipModel(chipId: "inbound", label: String(localized: "filter_inbound")),
            AddyChipModel(chipId: "outbound", label: String(localized: "filter_outbound"))
        ]
    }

    private func updateTheCacheFDCount(count: Int) {
        // Set the count of failed deliveries so that we can use it for the backgroundservice AND mark this a read for the badge
        MainViewState.shared.encryptedSettingsManager.putSettingsInt(
            key: .backgroundServiceCacheFailedDeliveriesCount,
            int: count
        )
    }

    private func deleteFailedDelivery(failedDelivery: FailedDeliveries) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteFailedDelivery(failedDeliveryId: failedDelivery.id)
            if result == "204" {
                await failedDeliveriesViewModel.getFailedDeliveries(forceReload: true)
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_delete_failed_delivery")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_delete_failed_delivery")
            errorAlertMessage = error.localizedDescription
        }
    }

    func deleteFailedDelivery(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let failedDeliveries = failedDeliveriesViewModel.failedDeliveries?.data {
                let item = failedDeliveries[index]
                failedDeliveryToDelete = item
                activeAlert = .deleteFailedDelivery
                showAlert = true

                // Remove from the collection for the smooth animation
                failedDeliveriesViewModel.failedDeliveries?.data.remove(atOffsets: offsets)
            }
        }
    }
}
