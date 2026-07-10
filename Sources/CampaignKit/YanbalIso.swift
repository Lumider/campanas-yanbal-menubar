import SwiftUI

/// Isotipos (símbolo "Y") de Yanbal como `Shape` nativos de SwiftUI, según los SVG
/// oficiales de diseño. Hay dos versiones porque el contexto es distinto:
/// - `YanbalIso`     → panel/popover interno (viewBox 18×18, ajustada y centrada).
/// - `YanbalIsoBar`  → barra de menú (viewBox 11×8, con margen derecho horneado
///   que sirve de separación frente a "C7 · S3").
/// Al ser vectoriales se ven nítidas a cualquier tamaño y toman el color con `.fill(...)`.

/// Iso para el panel interno (PanelView). viewBox `0 0 18 18`.
public struct YanbalIso: Shape {
  public init() {}
  public static let aspect: CGFloat = 1  // 18/18

  public func path(in rect: CGRect) -> Path {
    let vb: CGFloat = 18
    let scale = min(rect.width, rect.height) / vb
    let offX = rect.minX + (rect.width - vb * scale) / 2
    let offY = rect.minY + (rect.height - vb * scale) / 2
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: offX + x * scale, y: offY + y * scale)
    }
    var path = Path()
    path.move(to: p(1, 2.12779))
    path.addLine(to: p(4.14958, 2.12779))
    path.addLine(to: p(10.113, 10.5411))
    path.addLine(to: p(10.113, 17))
    path.addLine(to: p(7.55171, 17))
    path.addLine(to: p(7.59331, 11.1997))
    path.addLine(to: p(1, 2.12779))
    path.closeSubpath()
    path.move(to: p(11.0356, 9.90368))
    path.addCurve(to: p(10.8469, 8.28897), control1: p(10.9093, 9.39401), control2: p(10.8469, 8.84073))
    path.addCurve(to: p(16.1596, 2), control1: p(10.8469, 5.01744), control2: p(12.9253, 2))
    path.addCurve(to: p(16.7895, 2.0421), control1: p(16.3482, 2), control2: p(16.684, 2.02105))
    path.addLine(to: p(11.037, 9.90368))
    path.addLine(to: p(11.0356, 9.90368))
    path.closeSubpath()
    return path
  }
}

/// Iso para la barra de menú. viewBox `0 0 11 8`: incluye a propósito espacio vacío
/// a la derecha de la Y (llega a x≈7.67 de 11) como separación horneada.
public struct YanbalIsoBar: Shape {
  public init() {}
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
    path.move(to: p(1.16931, 0.864588))
    path.addLine(to: p(2.4651, 0.864588))
    path.addLine(to: p(4.91854, 4.32599))
    path.addLine(to: p(4.91854, 6.98327))
    path.addLine(to: p(3.8648, 6.98327))
    path.addLine(to: p(3.88191, 4.59691))
    path.addLine(to: p(1.16931, 0.864588))
    path.closeSubpath()
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
