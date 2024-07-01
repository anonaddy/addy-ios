//
//  ChartData.swift
//  addy_shared
//
//  Created by Stijn van de Water on 01/07/2024.
//

import Foundation

public struct AddyChartData: Codable {
    public var forwardsData: [Int]
    public var labels: [String]
    public var outboundMessageTotals: [Int]
    public var repliesData: [Int]
    public var sendsData: [Int]
}
