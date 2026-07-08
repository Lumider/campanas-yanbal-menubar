import AppKit
import CampaignKit
import SwiftUI

/// Modelo observable: recalcula el snapshot del calendario y lo publica a la UI.
/// Refresca cada hora y también cuando el equipo despierta o cambia la fecha del
/// sistema, para que la etiqueta de la barra nunca quede desactualizada.
@MainActor
final class CalendarModel: ObservableObject {
  @Published private(set) var snapshot: CampaignSnapshot?

  private var timer: Timer?

  init() {
    refrescar()

    // Tick horario: barato y suficiente para detectar el cambio de día/semana.
    let t = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.refrescar() }
    }
    RunLoop.main.add(t, forMode: .common)
    timer = t

    let nc = NotificationCenter.default
    nc.addObserver(
      self, selector: #selector(refrescarObjC),
      name: .NSCalendarDayChanged, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(refrescarObjC),
      name: NSWorkspace.didWakeNotification, object: nil)
  }

  // Las notificaciones pueden llegar fuera del hilo principal; saltamos al main
  // actor antes de tocar @Published para evitar avisos de publicación en segundo plano.
  @objc nonisolated private func refrescarObjC() {
    Task { @MainActor in self.refrescar() }
  }

  func refrescar() { snapshot = CampaignCalendar.snapshot() }
}

@main
struct YanbalCampanasApp: App {
  @StateObject private var modelo = CalendarModel()

  // Isotipo de Yanbal para la barra de menú. Se carga una sola vez desde los
  // recursos del paquete y se dimensiona a la altura típica de la barra (18 pt).
  // Es opcional: si el recurso falta, la barra sigue mostrando solo el texto.
  private static let iconoBarra: NSImage? = {
    let nombres = ["MenuBarLogo"]
    let extensiones = ["pdf", "png"]
    for nombre in nombres {
      for ext in extensiones {
        if let url = Bundle.module.url(forResource: nombre, withExtension: ext),
           let img = NSImage(contentsOf: url) {
          let alto: CGFloat = 18
          let ratio = img.size.width / max(img.size.height, 1)
          img.size = NSSize(width: alto * ratio, height: alto)
          // Monocromo que se adapta a barra clara/oscura (estándar de macOS).
          // Para mostrar el logo a color: comentar la línea siguiente.
          img.isTemplate = true
          return img
        }
      }
    }
    return nil
  }()

  var body: some Scene {
    // La etiqueta combina el isotipo de Yanbal con el texto compacto ("C7 · S3").
    // Si la fecha cae fuera del calendario conocido, el texto muestra un guion.
    MenuBarExtra {
      PanelView(snapshot: modelo.snapshot)
    } label: {
      if let icono = Self.iconoBarra {
        Image(nsImage: icono)
          .renderingMode(.template)
      }
      Text(modelo.snapshot?.etiquetaBarra ?? "C— · S—")
    }
    .menuBarExtraStyle(.window)
  }
}
