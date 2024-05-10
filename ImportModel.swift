//
//  ImportModel.swift
//  GuidedCapture
//
//  Created by Matyas Vascak on 07.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation

struct ImportModel{
    
    struct IdentifiableURL: Identifiable {
        let id: UUID = UUID()
        let url: URL
    }
}

