//
//  LabelsView.swift
//  addy
//
//  Created by Stijn van de Water on 24/06/2026.
//

import addy_shared
import SwiftUI

struct LabelsView: View {
    @EnvironmentObject var mainViewState: MainViewState

    @StateObject var labelsViewModel = LabelsViewModel()

    @State private var activeAlert: ActiveAlert = .error
    @State private var showAlert: Bool = false
    @State private var labelToDelete: Labels? = nil
    @State private var isPresentingAddLabelBottomSheet = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""

    @State private var label_count: Int = 0
    @State private var label_limit: Int = 0

    @Binding var horizontalSize: UserInterfaceSizeClass

    enum ActiveAlert {
        case error, deleteLabel
    }

    var onRefreshGeneralData: (() -> Void)? = nil

    var body: some View {
        #if DEBUG
            let _ = Self._printChanges()
        #endif

        Group {
            if horizontalSize == .regular {
                NavigationStack {
                    labelsViewBody
                }
            } else {
                labelsViewBody
            }
        }.onAppear(perform: {
            if let labels = labelsViewModel.labels {
                if labels.data.isEmpty {
                    Task {
                        await labelsViewModel.getLabels()
                    }
                }
            }
        })
        .task {
            await getUserResource()
        }
    }

    private var labelsViewBody: some View {
        List {
            if let labels = labelsViewModel.labels {
                Section {
                    ForEach(labels.data) { label in
                        LabelRowView(label: label)
                    }.onDelete(perform: deleteLabel)
                } header: {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 6) {
                            Text(String(localized: "labels"))

                            if let count = labelsViewModel.labels?.data.count, count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            if labelsViewModel.isLoading {
                                ProgressView()
                                    .frame(maxHeight: 4)
                            }
                        }
                    }

                } footer: {
                    Text("You've created \(label_count) out of \(label_limit) labels.")
                        .padding(.top)
                }.textCase(nil)
            }

        }.refreshable {
            if horizontalSize == .regular {
                self.onRefreshGeneralData?()
            }
            await self.labelsViewModel.getLabels()
            await self.getUserResource()
        }
        .sheet(isPresented: $isPresentingAddLabelBottomSheet) {
            NavigationStack {
                AddLabelBottomSheet {_ in 
                    Task {
                        await labelsViewModel.getLabels()
                    }
                    isPresentingAddLabelBottomSheet = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .deleteLabel:
                return Alert(title: Text(String(localized: "delete_label")), message: Text(String(localized: "delete_label_desc")), primaryButton: .destructive(Text(String(localized: "delete"))) {
                    Task {
                        await self.deleteLabel(label: self.labelToDelete!)
                    }
                }, secondaryButton: .cancel {
                    Task {
                        await labelsViewModel.getLabels()
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
            if let labels = labelsViewModel.labels {
                if labels.data.isEmpty, !labelsViewModel.searchQuery.isEmpty {
                    ContentUnavailableView.search(text: labelsViewModel.searchQuery)
                } else if labels.data.isEmpty, labelsViewModel.searchQuery.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "no_labels"), systemImage: "tag")
                    } description: {
                        Text(String(localized: "no_labels_desc"))
                    }
                }
            } else {
                if labelsViewModel.networkError != "" {
                    ContentUnavailableView {
                        Label(String(localized: "something_went_wrong_retrieving_labels"), systemImage: "wifi.slash")
                    } description: {
                        Text(labelsViewModel.networkError)
                    } actions: {
                        Button(String(localized: "try_again", bundle: Bundle(for: SharedData.self))) {
                            Task {
                                await labelsViewModel.getLabels()
                            }
                        }
                    }
                } else {
                    VStack(alignment: .center, spacing: 0) {
                        Spacer()
                        ContentUnavailableView {
                            Label(String(localized: "obtaining_labels"), systemImage: "globe")
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
        .navigationTitle(String(localized: "manage_labels"))
        .navigationBarTitleDisplayMode(horizontalSize == .regular ? .automatic : .inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    self.isPresentingAddLabelBottomSheet = true
                }) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
            }
        }
        .searchable(text: $labelsViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "search"))
        .onSubmit(of: .search) {
            Task {
                await labelsViewModel.searchLabels(searchQuery: labelsViewModel.searchQuery)
            }
        }
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
    }

    private func deleteLabel(label: Labels) async {
        let networkHelper = NetworkHelper()
        do {
            let result = try await networkHelper.deleteLabel(labelId: label.id)
            if result == "204" {
                await labelsViewModel.getLabels()
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = String(localized: "error_deleting_label")
                errorAlertMessage = result
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "error_deleting_label")
            errorAlertMessage = error.localizedDescription
        }
    }

    func deleteLabel(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            if let labels = labelsViewModel.labels?.data {
                let item = labels[index]
                labelToDelete = item
                activeAlert = .deleteLabel
                showAlert = true
                labelsViewModel.labels?.data.remove(atOffsets: offsets)
            }
        }
    }

    private func getUserResource() async {
        let networkHelper = NetworkHelper()
        do {
            let userResource = try await networkHelper.getUserResource()
            if let userResource = userResource {
                // Don't update mainView, this will refresh the entire view hierarchy
                label_limit = 100
                label_count = labelsViewModel.labels?.data.count ?? 0
            } else {
                activeAlert = .error
                showAlert = true
                errorAlertTitle = ""
                errorAlertMessage = String(localized: "something_went_wrong_retrieving_labels")
            }
        } catch {
            activeAlert = .error
            showAlert = true
            errorAlertTitle = String(localized: "something_went_wrong_retrieving_labels")
            errorAlertMessage = error.localizedDescription
        }
    }
}
