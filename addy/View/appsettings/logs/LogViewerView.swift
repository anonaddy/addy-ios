//
//  LogViewerView.swift
//  addy
//
//  Created by Stijn van de Water on 11/06/2024.
//

import SwiftUI
import addy_shared

struct LogViewerView: View {
    @StateObject var logsViewModel = LogsViewModel()
    
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        List {
            if let logs = logsViewModel.logs{
                if !logs.isEmpty {
                    Section {
                        ForEach (logs) { logEntry in
                            let logToShare = "\(logEntry.message)\n\(logEntry.method ?? "")\n\(logEntry.extra ?? "")"
                            ShareLink(item: logToShare) {
                                
                                HStack {
                                    Capsule()
                                        .frame(maxWidth: 8, maxHeight: .infinity)
                                        .foregroundStyle(self.getImportanceColor(importance: logEntry.importance)).padding(.vertical).padding(.trailing, 4)
                                    VStack(alignment: .leading){
                                        Text(logEntry.dateTime).fontWeight(.medium).padding(.bottom, 4)
                                        Text(logEntry.message)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                    }
                                }
                            }.buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        HStack(spacing: 6){
                            Text(String(localized: "logs"))
                            
                            if (logsViewModel.isLoading){
                                ProgressView()
                                    .frame(maxHeight: 4)
                                
                            }
                        }
                        
                    }
                }
                
            }
            
        }.refreshable {
            self.logsViewModel.getLogs()
        }.overlay(Group {
            
            if let logs = logsViewModel.logs{
                if logs.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "no_logs"), systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text(String(localized: "no_logs_desc"))
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 0) {
                    Spacer()
                    ContentUnavailableView {
                        Label(String(localized: "obtaining_logs"), systemImage: "magnifyingglass")
                    } description: {
                        Text(String(localized: "obtaining_desc"))
                    }
                    
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight:50)
                    Spacer()
                }
            }
        })
        .navigationTitle(String(localized: "logs"))
        .navigationBarTitleDisplayMode(.inline)

        .toolbar(content: {
            
            ToolbarItem(placement: .topBarTrailing) {
                
                Menu(content: {
                    Button(String(localized: "clear_logs")) {
                        LoggingHelper().clearLogs()
                        logsViewModel.getLogs()
                    }
                }, label: {
                    Label(String(localized: "menu"), systemImage: "ellipsis.circle")
                })
                
            }
            
        }).onAppear(perform: {
            if let logs = logsViewModel.logs{
                if (logs.isEmpty) {
                    logsViewModel.getLogs()
                    
                }
            }
        })
    }
    
    private func getImportanceColor(importance: LogImportance) -> Color {
        
        switch (importance) {
        case .critical:
            return Color.red
        case .warning:
            return Color.orange
        case .info:
            return Color.green
        }
    }
}

#Preview {
    LogViewerView()
}
