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
    static let phone = "513-594-7595"
    static let phoneDialable = "5135947595"
    static let email = "taulbeepainting2@gmail.com"
    static let website = "taulbeepainting.app"
    static let websiteURL = "https://taulbeepainting.app"

    /// Prefilled mailto link for requesting a quote/estimate from the team.
    static var quoteMailto: String {
        let subject = "Quote request from the Taulbee Painting app"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        return "mailto:\(email)?subject=\(encoded)"
    }
}
