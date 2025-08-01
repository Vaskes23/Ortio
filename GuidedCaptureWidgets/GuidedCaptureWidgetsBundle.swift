//
//  GuidedCaptureWidgetsBundle.swift
//  GuidedCaptureWidgets
//
//  Created by Matyas Vascak on 27.06.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct GuidedCaptureWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GuidedCaptureWidgets()
        GuidedCaptureWidgetsLiveActivity()
    }
}
