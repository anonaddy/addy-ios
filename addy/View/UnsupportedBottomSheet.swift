//
//  UnsupportedBottomSheet.swift
//  addy
//
//  Created by Stijn van de Water on 12/05/2024.
//

import SwiftUI


struct UnsupportedBottomSheet: View {

    let onClickHowToUpdate: () -> Void
    let onClickIgnore: () -> Void

    init(onClickHowToUpdate: @escaping () -> Void, onClickIgnore: @escaping () -> Void) {
        self.onClickHowToUpdate = onClickHowToUpdate
        self.onClickIgnore = onClickIgnore
    }

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif

            List {
                
                Section{
                    VStack{
                        AddyButton(action: {
                            self.onClickHowToUpdate()
                            }) {
                            Text(String(localized: "how_to_update")).foregroundColor(Color.white)
                        }
                    }
                } header: {
                    VStack(alignment: .leading){
                        Text(String(localized: "addyio_instance_version_unsupported"))
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                        
                    }.textCase(nil)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                Section{
                    Button(String(localized: "ignore_and_continue")){
                        self.onClickIgnore()
                    }        .frame(maxWidth: .infinity)

                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                
                
                
            }.navigationTitle(String(localized: "note"))
            .listSectionSpacing(.compact)
                .navigationBarTitleDisplayMode(.inline)
        }
}

#Preview {
    UnsupportedBottomSheet {
        //
    } onClickIgnore: {
        //
    }

}
