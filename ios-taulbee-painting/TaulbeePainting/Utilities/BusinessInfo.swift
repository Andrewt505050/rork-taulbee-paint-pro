//
//  BusinessInfo.swift
//  TaulbeePainting
//
//  Central place for Taulbee Painting contact details. Update these values
//  with the real business information.
//

import Foundation

enum BusinessInfo {
    static let name = "Taulbee Painting"
    static let tagline = "Quality interior & exterior painting"
    static let phone = "(555) 123-4567"
    static let phoneDialable = "5551234567"
    static let email = "hello@taulbeepainting.com"
    static let website = "taulbeepainting.com"
    static let websiteURL = "https://taulbeepainting.com"

    /// Prefilled mailto link for requesting a quote/estimate from the team.
    static var quoteMailto: String {
        let subject = "Quote request from the Taulbee Painting app"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        return "mailto:\(email)?subject=\(encoded)"
    }
}
