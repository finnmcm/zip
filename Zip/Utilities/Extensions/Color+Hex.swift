//
//  Color+Hex.swift
//  Zip
//

import SwiftUI

extension Color {
    init(hex: String) {
        let r, g, b, a: Double
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        if hexString.count == 6 { hexString.append("FF") }
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xFF000000) >> 24) / 255
            g = Double((hexNumber & 0x00FF0000) >> 16) / 255
            b = Double((hexNumber & 0x0000FF00) >> 8) / 255
            a = Double(hexNumber & 0x000000FF) / 255
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        }
        self = .clear
    }
}


