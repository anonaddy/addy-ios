//
//  DeleteAccountConfirmationView.swift
//  addy
//
//  Created by Stijn van de Water on 23/09/2024.
//


import SwiftUI
import addy_shared

class TimerViewModel: ObservableObject {
    @Published var secondsRemaining = 10
    private var timer: Timer?
    
    init() {
        resetTimer()
    }
    
    func resetTimer() {
        secondsRemaining = 10
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            if self?.secondsRemaining ?? 0 > 0 {
                self?.secondsRemaining -= 1
            } else {
                self?.timer?.invalidate()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
}

struct DeleteAccountConfirmationView: View {
    @StateObject private var viewModel = TimerViewModel()
    
    let addyButtonDeleteStyle = AddyButtonStyle(width: .infinity,
                                  height: 56,
                                  cornerRadius: 12,
                                  backgroundColor: Color.softRed,
                                  strokeWidth: 5,
                                  strokeColor: .gray)
    
    let addyButtonGrayStyle = AddyButtonStyle(width: .infinity,
                                  height: 56,
                                  cornerRadius: 12,
                                  backgroundColor: Color.gray,
                                  strokeWidth: 5,
                                  strokeColor: .gray)
    
    
    
    @State private var showAlert: Bool = false
    @State private var alertMessage = String(localized: "delete_account_confirmation_alert")
    @State private var password = ""

    var body: some View {
        VStack {
            ContentUnavailableView {
                Label(String(localized: "delete_account_confirmation"), systemImage: "person.fill.badge.minus")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.red)
                    .padding()
                
                Text(LocalizedStringKey(String(localized: "delete_account_confirmation_desc")))
                    .font(.subheadline)
                    .padding(.bottom)
            }
            Spacer()
            if viewModel.secondsRemaining > 0 {
                AddyButton(action: {}, style: addyButtonGrayStyle) {
                    Text(String(format: String(localized: "delete_account_countdown"), String(viewModel.secondsRemaining)))
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }.padding()
            } else {
                AddyButton(action: {
                    showAlert = true
                }, style: addyButtonDeleteStyle) {
                    Text(String(localized: "delete_account"))
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }.padding()
            }
        }
        .alert(String(localized: "delete_account"), isPresented: $showAlert) {
            SecureField(String(localized: "delete_account_confirmation_password"), text: $password)
            Button(String(localized: "delete_account"), role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    
        
        .navigationTitle(String(localized: "delete_account"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteAccount() async{
        let networkHelper = NetworkHelper()
            await networkHelper.deleteAccount(password: password, completion: { result in
                switch result {
                case "204":
                    SettingsManager(encrypted: true).clearSettingsAndCloseApp()
                case "422":
                    alertMessage = String(localized: "delete_account_failed")
                    showAlert = true
                default:
                    alertMessage = result
                    showAlert = true
                }
            })

    }
}

#Preview {
    DeleteAccountConfirmationView()
}
