//
//  AddDomainBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 03/06/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared
import Combine

struct AddDomainBottomSheet: View {
    @State var domain: String = ""
    @State var domainPlaceHolder: String = String(localized: "address")
    let onAdded: () -> Void
    
    init(onAdded: @escaping () -> Void) {
        self.onAdded = onAdded
    }
    
    @State private var domainValidationError:String?
    @State private var domainRequestError:String?
    
    @State var domainVerificationStatusText: String = ""
    @State var IsLoadingAddButton: Bool = false
    @State var isWaitingForDomainVerification: Bool = false
    @Environment(\.dismiss) var dismiss
    
    @State private var timer: Timer? = nil
    
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        Group {
            if isWaitingForDomainVerification {
                Text(domainVerificationStatusText).transition(.opacity).multilineTextAlignment(.center)
                ProgressView()
            } else {
                VStack{
                    
                    Form {
                        
                        Section{
                            ValidatingTextField(value: self.$domain, placeholder: self.$domainPlaceHolder, fieldType: .domain, error: $domainValidationError)
                            
                        } header: {
                            Text(String(localized: "add_domain_desc"))
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                            
                        } footer: {
                            if let error = domainRequestError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 15))
                                    .multilineTextAlignment(.leading)
                                    .padding([.horizontal], 0)
                                    .onAppear{
                                        HapticHelper.playHapticFeedback(hapticType: .error)
                                    }
                            }
                            
                        }.textCase(nil)
                        
                        Section{
                            AddyLoadingButton(action: {
                                // Since the ValidatingTextField is also handling validationErrors (and resetting these errors on every change)
                                // We should not allow any saving until the validationErrors are nil
                                if (domainValidationError == nil){
                                    IsLoadingAddButton = true;
                                    
                                    Task {
                                        await self.addDomainToAccount(domain: self.domain)
                                    }
                                } else {
                                        IsLoadingAddButton = false
                                    
                                }
                            }, isLoading: $IsLoadingAddButton) {
                                Text(String(localized: "add")).foregroundColor(Color.white)
                            }.frame(minHeight: 56)
                        }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                        
                        
                        
                        
                    }.navigationTitle(String(localized: "add_domain")).pickerStyle(.navigationLink)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(content: {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    dismiss()
                                } label: {
                                    Text(String(localized: "cancel"))
                                }
                                
                            }
                        })
                    
                    
                }
            }
        }.onDisappear {
            self.timer?.invalidate()
        }
       
    }

    
    private func addDomainToAccount(domain: String) async {
        domainRequestError = nil
        let networkHelper = NetworkHelper()
        do {
            let (_, error, body) = try await networkHelper.addDomain(domain: domain)
                switch error {
                case "404": openSetup(body: String(body ?? ""))
                case "201": self.onAdded()
                default:
                    IsLoadingAddButton = false
                    domainRequestError = error
                }
            
        } catch {
            domainRequestError = error.localizedDescription
        }
    }

    
    private func openSetup(body: String) {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isWaitingForDomainVerification = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.domainVerificationStatusText = body
            }
        }
        
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            Task {
                await self.addDomainToAccount(domain: self.domain)
            }
        }
        
    }
}

#Preview {
    AddDomainBottomSheet() {
        // Dummy function for preview
    }
}
