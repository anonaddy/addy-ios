//
//  AliasRowCardView.swift
//  addy
//
//  Created by Stijn van de Water on 09/05/2024.
//

import SwiftUI
import addy_shared

struct AliasRowView: View {
    //var demoData: [Double] = [100, 30, 40, 80]
    
    let alias: Aliases
    let isPreview: Bool
    var chartData: [Double]
    let aliasDescription:String
    
    init(alias: Aliases, isPreview: Bool) {
        self.alias = alias
        self.isPreview = isPreview
        
        var aliasTotalCount =  Double(alias.emails_forwarded + alias.emails_replied + alias.emails_sent + alias.emails_blocked)
        aliasTotalCount = aliasTotalCount != 0.0 ? aliasTotalCount : 10.0 // To prevent dividing by 0
        
        
        let aliasEmailForwardedProgress =  (Double(alias.emails_forwarded) / aliasTotalCount) * 100
        let aliasEmailRepliedProgress = (Double(alias.emails_replied) / aliasTotalCount) * 100
        let aliasEmailSentProgress = (Double(alias.emails_sent) / aliasTotalCount) * 100
        let aliasEmailBlockedProgress = (Double(alias.emails_blocked) / aliasTotalCount) * 100
        
        self.chartData = [aliasEmailForwardedProgress, aliasEmailRepliedProgress, aliasEmailSentProgress, aliasEmailBlockedProgress]
        
        
        if let description = alias.description {
            
            do {
                self.aliasDescription =  String(format: String(localized: "s_s_s"),
                                                description,
                                                String(format: NSLocalizedString("created_at_s", comment: ""),
                                                       try DateTimeUtils.convertStringToLocalTimeZoneDate(alias.created_at).aliasRowDateDisplay()),
                                                String(format: String(localized: "updated_at_s"),
                                                       try DateTimeUtils.convertStringToLocalTimeZoneDate(alias.updated_at).aliasRowDateDisplay()))
            }
            catch {
                self.aliasDescription =  String(format: String(localized: "s_s_s"),
                                                description,
                                                String(format: NSLocalizedString("created_at_s", comment: ""),
                                                       DateTimeUtils.convertStringToLocalTimeZoneString(alias.created_at)),
                                                String(format: String(localized: "updated_at_s"),
                                                       DateTimeUtils.convertStringToLocalTimeZoneString(alias.updated_at)))
            }
            
        } else {
            
            do {
                self.aliasDescription =  String(format: String(localized: "s_s"),
                                                String(format: NSLocalizedString("created_at_s", comment: ""),
                                                       try DateTimeUtils.convertStringToLocalTimeZoneDate(alias.created_at).aliasRowDateDisplay()),
                                                String(format: String(localized: "updated_at_s"),
                                                       try DateTimeUtils.convertStringToLocalTimeZoneDate(alias.updated_at).aliasRowDateDisplay()))
            }
            catch {
                self.aliasDescription =  String(format: String(localized: "s_s"),
                                                String(format: NSLocalizedString("created_at_s", comment: ""),
                                                       DateTimeUtils.convertStringToLocalTimeZoneString(alias.created_at)),
                                                String(format: String(localized: "updated_at_s"),
                                                       DateTimeUtils.convertStringToLocalTimeZoneString(alias.updated_at)))
            }
        }
    }
    
    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif
        if isPreview {
            
            VStack(alignment: .leading) {
                
                VStack(alignment: .trailing) {
                    Text(verbatim: alias.email)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                HStack(alignment: .center) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                BarChart()
                                    .data(chartData)
                                    .chartStyle(ChartStyle(backgroundColor: .white,
                                                           foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                             ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                             ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                             ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                    .allowsHitTesting(false)
                                    .padding(.horizontal).padding(.top)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .frame(maxWidth: 100)
                    
                   
                    Spacer()
                    
                        
                        VStack(alignment: .trailing){
                            Label(title: {
                                Text(String(format: String(localized: "d_forwarded"), "\(alias.emails_forwarded)"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                                
                            }, icon: {
                                Image(systemName: "tray")
                                    .foregroundColor(.portalOrange)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                            Label(title: {
                                Text(String(format: String(localized: "d_replied"), "\(alias.emails_replied)"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                                
                            }, icon: {
                                Image(systemName: "arrow.turn.up.left")
                                    .foregroundColor(.easternBlue)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                            Label(title: {
                                Text(String(format: String(localized: "d_sent"), "\(alias.emails_sent)"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                                
                            }, icon: {
                                Image(systemName: "paperplane")
                                    .foregroundColor(.portalBlue)
                                    .font(.system(size: 18, weight: .bold))
                            } )
                            Label(title: {
                                Text(String(format: String(localized: "d_blocked"), "\(alias.emails_blocked)"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
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
                if (AliasWatcher().getAliasesToWatch().contains(alias.id)){
                    Label(String(localized: "you_ll_be_notified_if_this_alias_has_activity"), systemImage: "eyes")
                        .foregroundColor(.gray.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top,4)
                        .padding(.bottom,4)
                }
            }.padding()
        } else {
                HStack{
 
                    
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                            .overlay(
                                BarChart()
                                    .data(chartData)
                                    .chartStyle(ChartStyle(backgroundColor: .white,
                                                           foregroundColor: [ColorGradient(.portalOrange, .portalOrange.opacity(0.7)),
                                                                             ColorGradient(.easternBlue, .easternBlue.opacity(0.7)),
                                                                             ColorGradient(.portalBlue, .portalBlue.opacity(0.7)),
                                                                             ColorGradient(.softRed, .softRed.opacity(0.7))]))
                                    .allowsHitTesting(false)
                                    .padding(.horizontal).padding(.top)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .frame(maxWidth: 50)
                            .grayscale(alias.active ? 0 : 1)
                            .padding(.trailing)

                    
                    VStack(alignment: .leading){
                        Text(alias.email)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(aliasDescription)
                            .font(.subheadline)
                            .lineLimit(2)

                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                }.frame(height: 90)
            
            
            
            
        }
    }
    
}

//#Preview {
//    AliasRowCardView()
//}

