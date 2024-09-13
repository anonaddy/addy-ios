//
//  ChartData.swift
//  addy_shared
//
//  Created by Stijn van de Water on 01/07/2024.
//

import Foundation

public struct AddyChartData: Codable {
    
    public init(forwardsData: [Int], labels: [String], outboundMessageTotals: [Int], repliesData: [Int], sendsData: [Int]) {
        self.forwardsData = forwardsData
        self.labels = labels
        self.outboundMessageTotals = outboundMessageTotals
        self.repliesData = repliesData
        self.sendsData = sendsData
    }
    
    public var forwardsData: [Int]
    public var labels: [String]
    public var outboundMessageTotals: [Int]
    public var repliesData: [Int]
    public var sendsData: [Int]
}
