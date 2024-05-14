//
//  AddyCHip.swift
//  addy
//
//  Created by Stijn van de Water on 14/05/2024.
//

import SwiftUI

class AddyChipModel:Identifiable{
    let id = UUID()
    let filterId: String
    let label:String
    
    init(filterId:String, label: String) {
        self.filterId = filterId
        self.label = label
    }
}

struct AddyChipView: View {
    @Binding var chips: [AddyChipModel]
    @Binding var selectedChip:String
    let onTap: (AddyChipModel) -> Void
    
    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(chips) { chip in
                    Text(chip.label)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(self.selectedChip == chip.filterId ? Color.accentColor.opacity(0.7) : Color.gray.opacity(0.7)))
                        .foregroundColor(.white.opacity(0.8))
                        .onTapGesture{
                            // Only trigger on change
                            if (selectedChip != chip.filterId){
                                self.onTap(chip)
                            }
                        }
                }
            }
        }
    }
    
}

struct AddyChip_Preview: PreviewProvider{

    static var previews: some View{
        
        NavigationView {
                    VStack {
                        @State var selectedChip:String = "test3"
                        @State var chips = [
                            AddyChipModel(filterId: "test",label: "test"),
                            AddyChipModel(filterId: "test2",label: "test2"),
                            AddyChipModel(filterId: "test3",label: "test3"),
                            AddyChipModel(filterId: "test4",label: "test4"),
                            AddyChipModel(filterId: "test5",label: "test5"),
                            AddyChipModel(filterId: "test6",label: "test6"),
                        ]
                        
                        AddyChipView(chips: $chips, selectedChip: $selectedChip) { onTappedChip in
                            print("\(onTappedChip.label) is selected")
                            selectedChip = onTappedChip.label
                        }
                    }
                }
        
    }
    
}
