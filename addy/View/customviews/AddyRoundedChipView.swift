//
//  AddyChipModel.swift
//  addy
//
//  Created by Stijn van de Water on 14/05/2024.
//

import SwiftUI
import WrappingHStack
import addy_shared

public struct AddyRoundedChipView: View {
    @Binding var chips: [AddyChipModel]
    @Binding var selectedChip:String
    var singleLine:Bool
    
    let onTap: (AddyChipModel) -> Void
    
    public init(chips: Binding<[AddyChipModel]>, selectedChip: Binding<String>, singleLine: Bool, onTap: @escaping (AddyChipModel) -> Void) {
        self._chips = chips
        self._selectedChip = selectedChip
        self.singleLine = singleLine
        self.onTap = onTap
    }
    
    public var body: some View {

        if (self.singleLine){
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(chips) { chip in
                        Text(chip.label)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(self.selectedChip == chip.chipId ? Color.accentColor.opacity(0.7) : Color.gray.opacity(0.7)))
                            .foregroundColor(.white.opacity(0.8))
                            .onTapGesture{
                                HapticHelper.playHapticFeedback(hapticType: .tap)
                                self.onTap(chip)
                            }
                    }
                }
            }.scrollClipDisabled()
        } else {
            WrappingHStack(alignment: .leading) {
                    ForEach(chips) { chip in
                        Text(chip.label)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(self.selectedChip == chip.chipId ? Color.accentColor.opacity(0.7) : Color.gray.opacity(0.7)))
                            .foregroundColor(.white.opacity(0.8))
                            .onTapGesture{
                                HapticHelper.playHapticFeedback(hapticType: .tap)
                                    self.onTap(chip)
                                
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
                        
                        AddyRoundedChipView(chips: $chips, selectedChip: $selectedChip, singleLine: false) { onTappedChip in
                            print("\(onTappedChip.label) is selected")
                            selectedChip = onTappedChip.label
                        }
                    }
                }
        
    }
    
}
