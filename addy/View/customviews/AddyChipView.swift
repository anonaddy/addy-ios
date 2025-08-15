//
//  AddyChipModel.swift
//  addy
//
//  Created by Stijn van de Water on 14/05/2024.
//

import SwiftUI
import WrappingHStack
import addy_shared

struct AddyChipView: View {

    @Binding var chips: [AddyChipModel]
    @Binding var selectedChip:String
    var singleLine:Bool
    
    let onTap: (AddyChipModel) -> Void
    
    init(chips: Binding<[AddyChipModel]>, selectedChip: Binding<String>, singleLine: Bool, onTap: @escaping (AddyChipModel) -> Void) {
        self._chips = chips
        self._selectedChip = selectedChip
        self.singleLine = singleLine
        self.onTap = onTap
    }
    
    var body: some View {

        if (self.singleLine){
            ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(chips) { chip in
                                    Button(action: {
                                        HapticHelper.playHapticFeedback(hapticType: .tap)
                                        self.onTap(chip)
                                    }, label: {
                                        HStack {
                                            if self.selectedChip == chip.chipId {
                                                Image(systemName: "checkmark")
                                            }
                                            Text(chip.label)
                                        }
                                        .fixedSize()
                                    })
                                    .apply { View in
                                        if #available(iOS 26.0, *) {
                                            if self.selectedChip == chip.chipId {
                                                View.buttonStyle(.glassProminent)
                                            } else {
                                                View.buttonStyle(.glass)
                                            }
                                        } else {
                                            if self.selectedChip == chip.chipId {
                                                View.buttonStyle(.borderedProminent)
                                            } else {
                                                View.buttonStyle(.bordered)
                                            }
                                        }
                                    }
                                }
                            }.textCase(nil)
                        }
        } else {
            WrappingHStack(alignment: .leading) {
                    ForEach(chips) { chip in
                        Button(action: {
                            HapticHelper.playHapticFeedback(hapticType: .tap)
                            self.onTap(chip)
                        }, label: {
                            HStack {
                                if self.selectedChip == chip.chipId {
                                    Image(systemName: "checkmark")
                                }
                                Text(chip.label)
                            }
                            .fixedSize()
                        })
                        .apply { View in
                            if #available(iOS 26.0, *) {
                                if self.selectedChip == chip.chipId {
                                    View.buttonStyle(.glassProminent)
                                } else {
                                    View.buttonStyle(.glass)
                                }
                            } else {
                                if self.selectedChip == chip.chipId {
                                    View.buttonStyle(.borderedProminent)
                                } else {
                                    View.buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }.textCase(nil)
            
        }
        
    }
    

    
}

struct AddyChip_Preview: PreviewProvider{

    static var previews: some View{
        
        NavigationView {
                    VStack {
                        @State var selectedChip:String = "test3"
                        @State var chips = [
                            AddyChipModel(chipId: "test",label: "test"),
                            AddyChipModel(chipId: "test2",label: "test2"),
                            AddyChipModel(chipId: "test3",label: "test3"),
                            AddyChipModel(chipId: "test4",label: "test4"),
                            AddyChipModel(chipId: "test5",label: "test5"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                            AddyChipModel(chipId: "test6",label: "test6"),
                        ]
                        
                        VStack(spacing: 0){

                            AddyChipView(chips: $chips, selectedChip: $selectedChip, singleLine: true) { onTappedChip in
                                //print("\(onTappedChip.label) is selected")
                                selectedChip = onTappedChip.label
                            }
                            
                            Text("TEST")
                            Spacer()
                        }
                    }
                }
        
    }
    
}
