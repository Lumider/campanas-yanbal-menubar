import SwiftUI

/// Isotipo (símbolo "Y") de Yanbal como `Shape` nativo de SwiftUI.
///
/// Trazado extraído de `public/brand/iso-yanbal.svg` (viewBox 51 52.5 58 55).
/// Al ser vectorial se ve nítido a cualquier tamaño y toma el color con `.fill(...)`;
/// sirve igual en la barra de menú (macOS), en el widget y en la app (iOS), y en
/// modo claro/oscuro. Se escala manteniendo proporción y centrado en su rect.
public struct YanbalIso: Shape {
  public init() {}

  public func path(in rect: CGRect) -> Path {
    // viewBox original del SVG.
    let vbX: CGFloat = 51, vbY: CGFloat = 52.5, vbW: CGFloat = 58, vbH: CGFloat = 55
    let scale = min(rect.width / vbW, rect.height / vbH)
    let offX = rect.minX + (rect.width - vbW * scale) / 2
    let offY = rect.minY + (rect.height - vbH * scale) / 2

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: offX + (x - vbX) * scale, y: offY + (y - vbY) * scale)
    }

    var path = Path()

    // Trazo diagonal (asta de la "Y").
    path.move(to: p(51.4287, 53.3195))
    path.addLine(to: p(62.8272, 53.3195))
    path.addLine(to: p(84.409, 83.7679))
    path.addLine(to: p(84.409, 107.143))
    path.addLine(to: p(75.1397, 107.143))
    path.addLine(to: p(75.2902, 86.1511))
    path.addLine(to: p(51.4287, 53.3195))
    path.closeSubpath()

    // Brazo curvo superior.
    path.move(to: p(87.7479, 81.4608))
    path.addCurve(to: p(87.065, 75.6171), control1: p(87.2909, 79.6163), control2: p(87.065, 77.614))
    path.addCurve(to: p(106.292, 52.8571), control1: p(87.065, 63.7773), control2: p(94.5869, 52.8571))
    path.addCurve(to: p(108.572, 53.0094), control1: p(106.975, 52.8571), control2: p(108.19, 52.9332))
    path.addLine(to: p(87.7532, 81.4608))
    path.addLine(to: p(87.7479, 81.4608))
    path.closeSubpath()

    return path
  }
}
