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
    // El título de la barra es la etiqueta compacta ("C7 · S3"); si la fecha cae
    // fuera del calendario conocido, se muestra un guion.
    MenuBarExtra(modelo.snapshot?.etiquetaBarra ?? "C— · S—") {
      PanelView(snapshot: modelo.snapshot)
    }
    .menuBarExtraStyle(.window)
  }
}
