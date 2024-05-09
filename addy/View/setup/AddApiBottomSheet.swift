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
        
    }
    
      
    @State private var instanceError:String?
    @State private var apiKeyError:String?
    @State private var instance:String
    @State private var apiKey = String(localized: "APIKey_desc")
    
    @State var isLoadingSignIn: Bool = false
    
    var body: some View {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        VStack{
            
            Text(String(localized: "APIKey"))
                .font(.system(.title2))
                .fontWeight(.medium)
                .padding(.top, 25)
                .padding(.bottom, 15)
            
            Divider()
            
            ScrollView {
                
                VStack {
                    Text(String(localized: "api_setup_qr_code_scan"))
                        .font(.system(.body, design: .rounded))
                        .opacity(0.7)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text(cameraAuthorizationStatus == .authorized ? String(localized: "api_setup_qr_code_scan_desc") : String(localized: "qr_permissions_required"))
                        .font(.system(.footnote))
                        .opacity(0.7)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                }.padding()
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
                }.frame(width: 85, height: 85)
                    .cornerRadius(28)
                    .padding(.bottom, 25)
                    .alert(isPresented: $showInvalidQrAlert, content: {
                        Alert(title: Text(String(localized: "api_setup_qr_code_scan_wrong")), message: Text(String(localized: "api_setup_qr_code_scan_wrong_desc")), dismissButton: .default(Text(String(localized: "understood"))))
                    })
                
                Divider()
                
                
                
                @Environment(\.openURL) var openURL
                
                VStack{
                    Text(String(localized: "api_obtain"))
                        .font(.system(.body, design: .rounded))
                        .opacity(0.7)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text(String(localized: "api_obtain_desc"))
                        .font(.system(.footnote))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    
                    Spacer(minLength: 25)
                    
                    
                    
                    ValidatingTextField(value: $instance, placeholder:
                                            String(localized: "addyio_instance"), fieldType: .url, error: $instanceError).disabled(apiBaseUrl != nil)
                    ValidatingTextField(value: $apiKey, placeholder: String(localized: "APIKey_desc"), fieldType: .bigText, error: $apiKeyError)
                    
                    
                }.padding(.vertical)
                
                
                AddyLoadingButton(action: {
                    if (instanceError == nil && apiKeyError == nil){
                        DispatchQueue.global(qos: .background).async {
                            isLoadingSignIn = true;
                            self.verifyApiKey(apiKey: apiKey, baseUrl: instance)
                        }
                    } else {
                        //FIXME This is a workaround to get the animation to run
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isLoadingSignIn = false
                        }
                    }
                }, isLoading: $isLoadingSignIn) {
                    Text(String(localized: "sign_in")).foregroundColor(Color.white)
                }.frame(minHeight: 56)
                
                Button(action: {
                    openURL(URL(string: "\(instance)/settings/api")!)
                }) {
                    Text(String(localized: "get_my_key"))
                }.padding()
                
                
                
                
            }
            .padding(.horizontal)
            
        }.presentationDetents([.large])
            .presentationDragIndicator(.visible)
        
        
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
