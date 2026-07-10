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

  var body: some Scene {
    // La barra muestra el iso de Yanbal + la etiqueta compacta ("C7 · S3");
    // si la fecha cae fuera del calendario conocido, se muestra un guion.
    MenuBarExtra {
      PanelView(snapshot: modelo.snapshot)
    } label: {
      BarraLabel(texto: modelo.snapshot?.etiquetaBarra ?? "C— · S—")
    }
    .menuBarExtraStyle(.window)
  }
}

/// Contenido de la barra de menú: iso de Yanbal + "C7 · S3".
///
/// Parámetros acordados: iso a ~13 px, 4 px de separación con el texto, antes del
/// texto. Nota de macOS: en la barra el ícono suele renderizarse monocromo (toma
/// el color del texto), no en naranja; el naranja de marca se conserva en el panel.
private struct BarraLabel: View {
  let texto: String

  var body: some View {
    HStack(spacing: 4) {
      YanbalIso()
        .frame(width: 13, height: 12)
      Text(texto)
    }
  }
}
