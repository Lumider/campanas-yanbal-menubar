import SwiftUI

/// Isotipo (símbolo "Y") de Yanbal como `Shape` nativo de SwiftUI.
///
/// Trazado del SVG oficial entregado por diseño (viewBox `0 0 11 8`). El `viewBox`
/// incluye a propósito **espacio vacío a la derecha** de la Y (la figura llega hasta
/// x≈7.67 de 11), que sirve como separación horneada frente a "C7 · S3" en la barra.
/// Al ser vectorial se ve nítido a cualquier tamaño y toma el color con `.fill(...)`.
/// Se escala manteniendo proporción y centrado en su rect.
public struct YanbalIso: Shape {
  public init() {}

  /// Proporción del viewBox (ancho/alto), útil para enmarcarlo sin deformar.
  public static let aspect: CGFloat = 11.0 / 8.0

  public func path(in rect: CGRect) -> Path {
    let vbW: CGFloat = 11, vbH: CGFloat = 8
    let scale = min(rect.width / vbW, rect.height / vbH)
    let offX = rect.minX + (rect.width - vbW * scale) / 2
    let offY = rect.minY + (rect.height - vbH * scale) / 2

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: offX + x * scale, y: offY + y * scale)
    }

    var path = Path()

    // Trazo diagonal (asta de la "Y").
    path.move(to: p(1.16931, 0.864588))
    path.addLine(to: p(2.4651, 0.864588))
    path.addLine(to: p(4.91854, 4.32599))
    path.addLine(to: p(4.91854, 6.98327))
    path.addLine(to: p(3.8648, 6.98327))
    path.addLine(to: p(3.88191, 4.59691))
    path.addLine(to: p(1.16931, 0.864588))
    path.closeSubpath()

    // Brazo curvo superior.
    path.move(to: p(5.29811, 4.06372))
    path.addCurve(to: p(5.22049, 3.3994), control1: p(5.24616, 3.85403), control2: p(5.22049, 3.62641))
    path.addCurve(to: p(7.40622, 0.812012), control1: p(5.22049, 2.05344), control2: p(6.07559, 0.812012))
    path.addCurve(to: p(7.66537, 0.829331), control1: p(7.48384, 0.812012), control2: p(7.62198, 0.820671))
    path.addLine(to: p(5.29872, 4.06372))
    path.addLine(to: p(5.29811, 4.06372))
    path.closeSubpath()

    return path
  }
}
