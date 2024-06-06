//
//  CreateRulesView.swift
//  addy
//
//  Created by Stijn van de Water on 06/06/2024.
//

import SwiftUI

struct CreateRulesView: View {
    @EnvironmentObject var mainViewState: MainViewState

    let ruleId: String
    let ruleName: String

    
    @Binding var shouldReloadDataInParent: Bool

    
    init(ruleId: String, ruleName: String, shouldReloadDataInParent: Binding<Bool>) {
        self.ruleId = ruleId
        self.ruleName = ruleName
        _shouldReloadDataInParent = shouldReloadDataInParent
    }
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

//#Preview {
//    CreateRulesView()
//}
