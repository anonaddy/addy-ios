//
//  AddApiBottomSHeet.swift
//  addy
//
//  Created by Stijn van de Water on 07/05/2024.
//

import SwiftUI
import AVFoundation
import CodeScanner
import addy_shared

struct AddApiBottomSheet: View {
    @State private var showInvalidQrAlert = false
    let apiBaseUrl: String?
    let addKey: (String,String) -> Void
    
    init(apiBaseUrl: String?, addKey: @escaping (String, String) -> Void) {
        self.apiBaseUrl = apiBaseUrl
        self.addKey = addKey
        self.instance = apiBaseUrl ?? String(localized: "default_base_url")
        self.apiKey = ""
        
    }
    
    @State private var instanceError:String?
    @State private var apiKeyError:String?
    @State private var instance:String
    @State private var instancePlaceholder:String = String(localized: "addyio_instance")
    @State private var apiKey:String
    @State private var apiKeyPlaceholder = String(localized: "APIKey_desc")
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    
    @State var isLoadingSignIn: Bool = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL


    var body: some View {
        Form{
            
            
            Section {
                
                ZStack(alignment: .center) {
                   
                    
                    CodeScannerView(codeTypes: [.qr], scanMode: .continuous) { response in
                        if case let .success(result) = response {
                            
                            if isQrCodeFormattedCorrect(text: result.string) {
                                // if apiBaseUrl set, do not set the baseURL using QR
                                if apiBaseUrl == nil {
                                    // Get the string part before the | delimiter
                                    instance = result.string.components(separatedBy: "|").first ?? ""
                                }
                                // Get the string part after the | delimiter
                                apiKey = result.string.components(separatedBy: "|").last ?? ""
                                
                                isLoadingSignIn = true
                                // Call back to SetupView
                                self.verifyApiKey(apiKey: apiKey, baseUrl: instance)
                            } else {
                                self.showInvalidQrAlert = true
                            }
                            
                            
                        }
                    }.onTapGesture {
                        if (cameraAuthorizationStatus != .authorized){
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }.frame(maxHeight: .infinity)
                        .alert(isPresented: $showInvalidQrAlert, content: {
                            Alert(title: Text(String(localized: "api_setup_qr_code_scan_wrong")), message: Text(String(localized: "api_setup_qr_code_scan_wrong_desc")), dismissButton: .default(Text(String(localized: "understood"))))
                        })
                    
                    if (cameraAuthorizationStatus != .authorized){
                        Text(String(localized: "qr_permissions_required_short"))
                            .font(.system(.body, design: .rounded))
                            .opacity(0.7)
                            .fontWeight(.medium)
                    }
                   
                    
                   
                    
                }.frame(height: 200).listRowInsets(EdgeInsets())
                
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "qr_code_setup"))
                    
                }
            } footer: {
                
                if (cameraAuthorizationStatus == .authorized) {
                    Text(String(localized: "api_setup_qr_code_scan_desc"))
                } else {
                    Text(String(localized: "qr_permissions_required"))
                        .foregroundStyle(.red)
                }
                
                
            }
            
            Section {
                ValidatingTextField(value: $instance, placeholder:
                                        $instancePlaceholder, fieldType: .url, error: $instanceError).disabled(apiBaseUrl != nil)
                
                ValidatingTextField(value: $apiKey, placeholder: $apiKeyPlaceholder, fieldType: .bigText, error: $apiKeyError)
                
            } header: {
                VStack(alignment: .leading){
                    Text(String(localized: "api_obtain"))
                    
                }
            } footer: {
                Text(String(localized: "api_obtain_desc"))
                   
            }
            
            Section {
                AddyLoadingButton(action: {
                    if (instanceError == nil && apiKeyError == nil){
                        isLoadingSignIn = true;
                        
                        DispatchQueue.global(qos: .background).async {
                            self.verifyApiKey(apiKey: apiKey, baseUrl: instance)
                        }
                    } else {
                        DispatchQueue.main.async {
                            isLoadingSignIn = false
                        }
                    }
                }, isLoading: $isLoadingSignIn) {
                    Text(String(localized: "sign_in")).foregroundColor(Color.white)
                }.frame(minHeight: 56)}.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            
        }.navigationTitle(String(localized: "APIKey")).pickerStyle(.navigationLink)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "cancel"))
                    }
                    
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Menu(content: {
                        Button(String(localized: "get_my_key")) {
                            openURL(URL(string: "\(instance)/settings/api")!)
                        }
                    }, label: {
                        Label(String(localized: "menu"), systemImage: "ellipsis.circle")
                    })
                    
                }
                
            })
            .onAppear{
                cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        
        
    }
    
    
    private func verifyApiKey(apiKey: String, baseUrl: String = AddyIo.API_BASE_URL) {
        let networkHelper = NetworkHelper()
        networkHelper.verifyApiKey(baseUrl: baseUrl, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                if result == "200" {
                    self.addKey(apiKey, baseUrl)
                } else {
                    isLoadingSignIn = false
                    apiKeyError = String(localized: "api_invalid")
                }
            }
        }
    }
    
    private func isQrCodeFormattedCorrect(text: String) -> Bool {
        return text.contains("|") && text.contains("http")
    }
}

#Preview {
    AddApiBottomSheet(apiBaseUrl: "TEST", addKey: { apiKey, baseUrl in
        // Dummy function for preview
    })
}
