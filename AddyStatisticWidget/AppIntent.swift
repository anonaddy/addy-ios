//
//  AppIntent.swift
//  AddyStatisticWidget
//
//  Created by Stijn van de Water on 18/07/2024.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "configuration" }
    static var description: IntentDescription { "widget_configuration_description" }

    // An example configurable parameter.
    @Parameter(title: "widget_configuration_parameter_colorful_background", default: false)
    var colorfulBackground: Bool
}
