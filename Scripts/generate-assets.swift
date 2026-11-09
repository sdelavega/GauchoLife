// Regenerates the app icon set and the screen saver thumbnails.
// Usage: swift Scripts/generate-assets.swift <repository root>
import CoreGraphics
import Foundation
import ImageIO

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
let background = CGColor(colorSpace: srgb, components: [0.08, 0.08, 0.123, 1])!

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(r), CGFloat(g), CGFloat(b), 1])!
}

func context(width: Int, height: Int) -> CGContext {
    CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
              space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func write(_ ctx: CGContext, to url: URL) {
    let image = ctx.makeImage()!
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest), "could not write \(url.path)")
    print("wrote", url.path)
}

/// Rounded dark tile with a glider, the universal Life symbol.
func drawIcon(pixels: Int) -> CGContext {
    let ctx = context(width: pixels, height: pixels)
    let side = CGFloat(pixels)
    // Apple's macOS icon grid: the tile occupies 824/1024 of the canvas.
    let inset = side * 100 / 1024
    let tile = CGRect(x: inset, y: inset, width: side - 2 * inset, height: side - 2 * inset)
    let radius = tile.width * 0.2237

    ctx.setShadow(offset: CGSize(width: 0, height: -side * 0.01), blur: side * 0.02,
                  color: CGColor(colorSpace: srgb, components: [0, 0, 0, 0.35]))
    ctx.setFillColor(background)
    ctx.addPath(CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // 5x5 grid inside the tile, glider in the middle 3x3, drawn in rainbow order by "age".
    let cell = tile.width / 5
    let glider: [(x: Int, y: Int, color: CGColor)] = [
        (2, 3, rgb(1, 0.2, 0.1)),
        (3, 2, rgb(1, 0.55, 0)),
        (1, 1, rgb(1, 0.9, 0.1)),
        (2, 1, rgb(0.35, 0.9, 0.2)),
        (3, 1, rgb(0.2, 0.55, 1)),
    ]
    let dot = cell * 0.84
    for g in glider {
        let center = CGPoint(x: tile.minX + (CGFloat(g.x) + 0.5) * cell, y: tile.minY + (CGFloat(g.y) + 0.5) * cell)
        ctx.setFillColor(g.color)
        ctx.fillEllipse(in: CGRect(x: center.x - dot / 2, y: center.y - dot / 2, width: dot, height: dot))
    }
    return ctx
}

/// Static picture of a mid-run board for the System Settings tile.
func drawThumbnail(width: Int, height: Int, scale: Int) -> CGContext {
    let ctx = context(width: width * scale, height: height * scale)
    ctx.setFillColor(background)
    ctx.fill(CGRect(x: 0, y: 0, width: width * scale, height: height * scale))
    let cell = CGFloat(6 * scale)
    let columns = Int(CGFloat(width * scale) / cell), rows = Int(CGFloat(height * scale) / cell)
    let origin = CGPoint(x: (CGFloat(width * scale) - CGFloat(columns) * cell) / 2,
                         y: (CGFloat(height * scale) - CGFloat(rows) * cell) / 2)
    let palette = [rgb(1, 0, 0), rgb(1, 0.5, 0), rgb(1, 1, 0), rgb(0, 1, 0), rgb(0, 0, 1), rgb(0.5, 0, 0.5)]
    // A handful of recognisable patterns: glider, blinker, block, beehive, loaf.
    let cells: [(Int, Int, Int)] = [
        (1, 7, 0), (2, 6, 0), (0, 5, 0), (1, 5, 0), (2, 5, 0),            // glider
        (6, 2, 3), (7, 2, 3), (8, 2, 3),                                  // blinker
        (12, 6, 5), (13, 6, 5), (12, 7, 5), (13, 7, 5),                   // block
        (7, 6, 2), (8, 6, 2), (6, 7, 2), (9, 7, 2), (7, 8, 2), (8, 8, 2), // beehive
        (11, 1, 4), (12, 1, 4), (10, 2, 4), (13, 2, 4), (11, 3, 4), (13, 3, 4), (12, 4, 4), // loaf
        (3, 1, 1), (4, 1, 1), (3, 2, 1), (4, 2, 1),                       // block
    ]
    for (x, y, colorIndex) in cells where x < columns && y < rows {
        ctx.setFillColor(palette[colorIndex])
        ctx.fillEllipse(in: CGRect(x: origin.x + CGFloat(x) * cell, y: origin.y + CGFloat(y) * cell, width: cell, height: cell))
    }
    return ctx
}

// App icon set
let iconSet = root.appendingPathComponent("Gaucho Life/Assets.xcassets/AppIcon.appiconset")
var images: [[String: String]] = []
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(base)x\(base)" + (scale == 2 ? "@2x" : "") + ".png"
        write(drawIcon(pixels: base * scale), to: iconSet.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(base)x\(base)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
let json = try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try! json.write(to: iconSet.appendingPathComponent("Contents.json"))
print("wrote", iconSet.appendingPathComponent("Contents.json").path)

// Screen saver thumbnails
let saverDir = root.appendingPathComponent("Gaucho Lifesaver")
write(drawThumbnail(width: 90, height: 58, scale: 1), to: saverDir.appendingPathComponent("thumbnail.png"))
write(drawThumbnail(width: 90, height: 58, scale: 2), to: saverDir.appendingPathComponent("thumbnail@2x.png"))
