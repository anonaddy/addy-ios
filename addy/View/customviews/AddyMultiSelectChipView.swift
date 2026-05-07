//
//  AddyMultiSelectChipView.swift
//  addy
//
//  Created by Stijn van de Water on 14/05/2024.
//

import addy_shared
import SwiftUI
import WrappingHStack

struct AddyMultiSelectChipView: View {
    @Binding var chips: [AddyChipModel]
    @Binding var selectedChips: [String]

    var singleLine: Bool
    let onTap: (AddyChipModel) -> Void

    var body: some View {
        if singleLine {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(chips) { chip in
                        Button(action: {
                            HapticHelper.playHapticFeedback(hapticType: .tap)
                            self.onTap(chip)
                        }, label: {
                            HStack {
                                if self.selectedChips.contains(chip.chipId) {
                                    Image(systemName: "checkmark")
                                }
                                Text(chip.label)
                            }
                            .fixedSize()
                        })
                        .apply { View in
                            if #available(iOS 26.0, *) {
                                if self.selectedChips.contains(chip.chipId) {
                                    View.buttonStyle(.glassProminent)
                                } else {
                                    View.buttonStyle(.glass)
                                }
                            } else {
                                if self.selectedChips.contains(chip.chipId) {
                                    View.buttonStyle(.borderedProminent)
                                } else {
                                    View.buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            WrappingHStack(alignment: .leading) {
                ForEach(chips) { chip in
                    Button(action: {
                        HapticHelper.playHapticFeedback(hapticType: .tap)
                        self.onTap(chip)
                    }, label: {
                        HStack {
                            if self.selectedChips.contains(chip.chipId) {
                                Image(systemName: "checkmark")
                            }
                            Text(chip.label)
                        }
                        .fixedSize()
                    })
                    .apply { View in
                        if #available(iOS 26.0, *) {
                            if self.selectedChips.contains(chip.chipId) {
                                View.buttonStyle(.glassProminent)
                            } else {
                                View.buttonStyle(.glass)
                            }
                        } else {
                            if self.selectedChips.contains(chip.chipId) {
                                View.buttonStyle(.borderedProminent)
                            } else {
                                View.buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddyMultiSelectChipView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                @State var selectedChips: [String] = ["test3", "test"]
                @State var chips = [
                    AddyChipModel(chipId: "test", label: "test"),
                    AddyChipModel(chipId: "test2", label: "test2"),
                    AddyChipModel(chipId: "test3", label: "test3"),
                    AddyChipModel(chipId: "test4", label: "test4"),
                    AddyChipModel(chipId: "test5", label: "test5"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                    AddyChipModel(chipId: "test6", label: "test6"),
                ]

                AddyMultiSelectChipView(chips: $chips, selectedChips: $selectedChips, singleLine: true) { onTappedChip in
                    // print("\(onTappedChip.label) is selected")
                    if selectedChips.contains(onTappedChip.chipId) {
                        if let index = selectedChips.firstIndex(of: onTappedChip.chipId) {
                            selectedChips.remove(at: index)
                        }
                    } else {
                        selectedChips.append(onTappedChip.chipId)
                    }
                }.scrollClipDisabled()
            }
        }
    }
}
