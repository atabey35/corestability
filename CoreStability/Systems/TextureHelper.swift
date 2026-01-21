// TextureHelper.swift
// CoreStability
// Helper to generate SKTextures from SF Symbols

import SpriteKit
import UIKit

extension SKTexture {
    static func fromSymbol(name: String, pointSize: CGFloat, scale: UIImage.SymbolScale = .medium) -> SKTexture? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold, scale: scale)
        guard let symbol = UIImage(systemName: name, withConfiguration: config) else { return nil }
        
        // Explicitly rasterize to a white bitmap
        let renderer = UIGraphicsImageRenderer(size: symbol.size)
        let whiteImage = renderer.image { ctx in
            // Set context blend mode to destination in to keep alpha
            UIColor.white.setFill()
            symbol.withTintColor(.white, renderingMode: .alwaysOriginal).draw(at: .zero)
        }
        
        return SKTexture(image: whiteImage)
    }
}
