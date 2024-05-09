//
//  ProfileScreenViewModel.swift
//  addy
//
//  Created by Stijn van de Water on 08/05/2024.
//

import Foundation
import Combine

class ProfileScreenViewModel: ObservableObject {
    
    @Published var avatarImage: String = "profileAvatar"
    @Published var userName: String = "Alisa Millford"
    @Published var profession: String = "UX/UI designer"
    @Published var address: String = "116 Black Fox Rd, Parker, PA, 16049"
    @Published var grade: Double = 4.8
    @Published var reviewCount: Int = 1708
    @Published var skils: [String] = ["UX research", "Wireframing", "UX writing", "Coding", "Analytical", "UI prototyping"]
    @Published var description: String = """
    Hello! I am a Pennsylvania-based designer and researcher working with interactive web, moving image and futurescaping. She explores platforms and subversive technologies, unpacking their political and cultural implications.
    """
    @Published var portfolio: [String] = ["profile1", "profile2", "profile3", "profile4", "profile5", "profile6", "profile7", "profile8", "profile9"]
}
