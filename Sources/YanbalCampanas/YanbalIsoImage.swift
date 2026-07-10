import AppKit
import CampaignKit
import SwiftUI

/// Convierte el iso de Yanbal (el `Shape` de CampaignKit) en una imagen de
/// **plantilla** (`isTemplate = true`) para usarla en la barra de menú.
///
/// macOS no dibuja bien una figura SwiftUI arbitraria directamente en la barra;
/// en cambio, una imagen de plantilla se pinta **monocroma** según el tema (negro
/// en claro, blanco en oscuro), igual que los demás íconos del sistema. Se renderiza
/// desde el mismo `YanbalIso`, así que la forma es idéntica a la del panel.
@MainActor
enum YanbalIsoImage {
  private static var cache: [CGFloat: NSImage] = [:]

  static func template(height: CGFloat) -> NSImage {
    if let img = cache[height] { return img }
    let aspect: CGFloat = 58.0 / 55.0  // proporción del viewBox del SVG
    let renderer = ImageRenderer(
      content: YanbalIso()
        .fill(.black)
        .frame(width: height * aspect, height: height)
    )
    renderer.scale = 3  // nítido en pantallas Retina
    let img = renderer.nsImage ?? NSImage()
    img.isTemplate = true
    cache[height] = img
    return img
  }
}
