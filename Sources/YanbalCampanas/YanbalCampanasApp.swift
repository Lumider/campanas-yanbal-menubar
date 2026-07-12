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
  @StateObject private var avisos = AvisosModel()

  var body: some Scene {
    // La barra muestra el iso de Yanbal + la etiqueta compacta ("C7 · S3");
    // si la fecha cae fuera del calendario conocido, se muestra un guion.
    MenuBarExtra {
      PanelView(snapshot: modelo.snapshot, avisos: avisos.avisos)
    } label: {
      BarraLabel(texto: modelo.snapshot?.etiquetaBarra ?? "C— · S—")
    }
    .menuBarExtraStyle(.window)
  }
}

/// Contenido de la barra de menú: iso de Yanbal + "C7 · S3".
///
/// La Y se dibuja como imagen de plantilla (ver YanbalIsoImage), así macOS la pinta
/// monocroma según el tema. Usa el SVG oficial, que ya trae su separación horneada
/// a la derecha; por eso el HStack va sin spacing. Caja a 14 px de alto.
private struct BarraLabel: View {
  let texto: String

  var body: some View {
    HStack(spacing: 0) {
      Image(nsImage: YanbalIsoImage.template(height: 14))
      Text(texto)
    }
  }
}
