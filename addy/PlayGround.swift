//
//  PLayGround.swift
//  addy
//
//  Created by Stijn van de Water on 26/06/2024.
//

import SwiftUI

struct PlayGround: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                    Color.gray.opacity(0.1)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            BarChart()
                                .data([123, 34, 32, 42])
                                .chartStyle(ChartStyle(backgroundColor: .white,
                                                       foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                         ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                         ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                         ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                .padding(.horizontal).padding(.top)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .frame(maxWidth: 120)
                
               

                
                VStack(alignment: .trailing) {
                    Text(verbatim: "VeryLongEmailAdress1220h328@justplayinghard.ga")
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    VStack(alignment: .trailing){
                        
                        Label(title: {
                            Text(String(format: String(localized: "d_forwarded"), "\(123)"))
                                .font(.subheadline)
                                .foregroundStyle(Color.gray)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                        }, icon: {
                            Image(systemName: "tray")
                                .foregroundColor(.portalOrange)
                                .font(.system(size: 18, weight: .bold))
                        } )
                        Label(title: {
                            Text(String(format: String(localized: "d_replied"), "\(34)"))
                                .font(.subheadline)
                                .foregroundStyle(Color.gray)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                        }, icon: {
                            Image(systemName: "arrow.turn.up.left")
                                .foregroundColor(.easternBlue)
                                .font(.system(size: 18, weight: .bold))
                        } )
                        Label(title: {
                            Text(String(format: String(localized: "d_sent"), "\(32)"))
                                .font(.subheadline)
                                .foregroundStyle(Color.gray)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                        }, icon: {
                            Image(systemName: "paperplane")
                                .foregroundColor(.portalBlue)
                                .font(.system(size: 18, weight: .bold))
                        } )
                        Label(title: {
                            Text(String(format: String(localized: "d_blocked"), "\(42)"))
                                .font(.subheadline)
                                .foregroundStyle(Color.gray)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                        }, icon: {
                            Image(systemName: "slash.circle")
                                .foregroundColor(.softRed)
                                .font(.system(size: 18, weight: .bold))
                        } )
                    }
                    .labelStyle(MyAliasLabelStyle())
                }
                
            }
            Color.gray.opacity(0.1)
                .overlay(
                    Label(String(localized: "you_ll_be_notified_if_this_alias_has_activity"), systemImage: "eyes").foregroundColor(.gray.opacity(0.4))
                )
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .frame(maxWidth: .infinity, maxHeight: 50)
        }.padding()
    }
}

#Preview {
    PlayGround()
}
