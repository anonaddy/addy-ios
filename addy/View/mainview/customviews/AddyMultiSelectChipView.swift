//
//  AddyCHip.swift
//  addy
//
//  Created by Stijn van de Water on 14/05/2024.
//

import SwiftUI
import WrappingHStack


struct AddyMultiSelectChipView: View {
    @Binding var chips: [AddyChipModel]
    @Binding var selectedChips:[String]
    var singleLine:Bool

    let onTap: (AddyChipModel) -> Void
    
    var body: some View {
        
        if (self.singleLine){
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(chips) { chip in
                        
                        if self.selectedChips.contains(chip.chipId) {
                            Label(chip.label, systemImage: "checkmark")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)).fill(Color.accentColor.opacity(0.7)))
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture{
                                    self.onTap(chip)
                                }
                        } else {
                            Text(chip.label)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)).fill(Color.gray.opacity(0.7)))
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture{
                                    self.onTap(chip)
                                }
                        }
                    }
                }
            }.scrollClipDisabled()
        } else {
            WrappingHStack(alignment: .leading) {
                    ForEach(chips) { chip in
                        
                        if self.selectedChips.contains(chip.chipId) {
                            Label(chip.label, systemImage: "checkmark")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)).fill(Color.accentColor.opacity(0.7)))
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture{
                                    self.onTap(chip)
                                }
                        } else {
                            Text(chip.label)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)).fill(Color.gray.opacity(0.7)))
                                .foregroundColor(.white.opacity(0.8))
                                .onTapGesture{
                                    self.onTap(chip)
                                }
                        }
                    }
                }
            
        }
        
    }
    
}

struct AddyMultiSelectChipView_Preview: PreviewProvider{

    static var previews: some View{
        
        NavigationView {
                    VStack {
                        @State var selectedChips:[String] = ["test3", "test"]
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
                        
                        AddyMultiSelectChipView(chips: $chips, selectedChips: $selectedChips, singleLine: false) { onTappedChip in
                            print("\(onTappedChip.label) is selected")
                            if (selectedChips.contains(onTappedChip.chipId)){
                                if let index = selectedChips.firstIndex(of: onTappedChip.chipId) {
                                    selectedChips.remove(at: index)
                                }
                            } else {
                                selectedChips.append(onTappedChip.chipId)
                            }
                        }
                    }
                }
        
    }
    
}
