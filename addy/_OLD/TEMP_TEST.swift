//
//  TEMP_TEST.swift
//  addy
//
//  Created by Stijn van de Water on 10/05/2024.
//

import SwiftUI

struct TEMP_TEST: View {
    var demoData: [Double] = [18, 30, 40, 80]

    var body: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading){
                Text(verbatim: "Emailadres@justplayinghard.ha")
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                Text("Creatduwdaudhwadhawdhwaidhuawidhuwaidhwauidhwauidhuwaidhawuidhwauidhauwidhuawidhawuidhawidhuihbfgihfuhefhfueisfhuifhuseifheuifhesuifheuifheufihseffhuseifhuiesfhuisefhuisefhisefhuisefhuisefhuiesfhuisefhushfseiufhufhseifhided 09-12-1999, 12:10\nUpdated 09-12-1999, 12:10\nUpdated 09-12-1999, 12:10\nUpdated 09-12-1999, 12:10")
                    .font(.subheadline)
                    .lineLimit(2)
        
            }.padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))

            HStack{
                
                BarChart()
                    .data(demoData)
                    .chartStyle(ChartStyle(backgroundColor: .white,
                                           foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                             ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                             ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                             ColorGradient(.softRed, .softRed.opacity(0.7))]))
                    .frame(maxWidth: .infinity)

                
                
                VStack(alignment: .leading){
                    Label(title: {
                                Text(String(format: String(localized: "d_forwarded"), "1"))
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                            }, icon: {
                                Image(systemName: "tray")
                                    .foregroundColor(.portalOrange)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                    Spacer()
                    Label(title: {
                                Text(String(format: String(localized: "d_replied"), "1"))
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                            }, icon: {
                                Image(systemName: "arrow.turn.up.left")
                                    .foregroundColor(.easternBlue)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                    Spacer()
                    Label(title: {
                                Text(String(format: String(localized: "d_sent"), "1"))
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                            }, icon: {
                                Image(systemName: "paperplane")
                                    .foregroundColor(.portalBlue)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                    Spacer()
                    Label(title: {
                                Text(String(format: String(localized: "d_blocked"), "1"))
                            .font(.subheadline)
                            .foregroundStyle(Color.gray)
                            }, icon: {
                                Image(systemName: "slash.circle")
                                    .foregroundColor(.softRed)
                                    .font(.system(size: 18, weight: .bold))
                            } )

                }
                .labelStyle(MyAliasLabelStyle())
                .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            }

        }.padding().frame(height: 300)
        
        Label(String(localized: "you_ll_be_notified_if_this_alias_has_activity"), systemImage: "eyes").foregroundColor(.gray.opacity(0.4)).padding()

    }
}

#Preview {
    TEMP_TEST()
}
