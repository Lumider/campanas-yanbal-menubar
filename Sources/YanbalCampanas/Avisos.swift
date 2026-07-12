import CampaignKit
import Foundation
import UserNotifications

/// Sistema de "fechas importantes" (avisos remotos).
///
/// La fuente es `fechas.json` en la rama main del repo de GitHub: publicar o
/// corregir un aviso = editar ese archivo en el navegador. Todas las apps
/// instaladas lo consultan periódicamente, así los avisos llegan a todo el
/// mundo sin reinstalar nada. Si no hay red se usa la última copia cacheada.

/// Un aviso del fechas.json.
struct Aviso: Codable, Identifiable, Equatable {
  /// "2026-07-25" (año-mes-día).
  let fecha: String
  let titulo: String
  let detalle: String?
  /// Días de anticipación para notificar y resaltar (3 si no se indica).
  let avisarDiasAntes: Int?

  var id: String { fecha + titulo }
  var ventana: Int { avisarDiasAntes ?? 3 }

  /// Fecha parseada a mediodía local (coherente con CampaignCalendar).
  var dia: Date? {
    let partes = fecha.split(separator: "-").compactMap { Int($0) }
    guard partes.count == 3 else { return nil }
    var c = DateComponents()
    c.year = partes[0]
    c.month = partes[1]
    c.day = partes[2]
    c.hour = 12
    return CampaignCalendar.calendario.date(from: c)
  }

  /// Días que faltan (0 = hoy); nil si la fecha es inválida.
  var diasRestantes: Int? {
    guard let d = dia else { return nil }
    return CampaignCalendar.diasEntre(Date(), d)
  }
}

private struct AvisosDoc: Codable {
  let avisos: [Aviso]
}

/// Descarga, cachea y publica los avisos vigentes.
@MainActor
final class AvisosModel: ObservableObject {
  /// Avisos futuros (incluye hoy), ordenados por cercanía.
  @Published private(set) var avisos: [Aviso] = []

  /// Archivo editable en GitHub. El repo debe ser público para que raw funcione.
  private static let remoto = URL(
    string: "https://raw.githubusercontent.com/Lumider/campanas-yanbal-menubar/main/fechas.json")!
  private static let cacheKey = "fechas-json-cache"

  private var timer: Timer?

  init() {
    // Arranca con la última copia buena (funciona sin red) y luego refresca.
    if let data = UserDefaults.standard.data(forKey: Self.cacheKey) {
      aplicar(data)
    }
    Task { await refrescar() }

    // Re-consulta cada 6 horas: suficiente para avisos que se publican con días
    // de anticipación, y barato en red.
    let t = Timer(timeInterval: 6 * 3600, repeats: true) { [weak self] _ in
      Task { @MainActor in await self?.refrescar() }
    }
    RunLoop.main.add(t, forMode: .common)
    timer = t
  }

  func refrescar() async {
    guard let (data, _) = try? await URLSession.shared.data(from: Self.remoto) else { return }
    // Solo se acepta (y cachea) si el JSON es válido: un error de edición en
    // GitHub no debe romper lo que la gente ya ve.
    guard (try? JSONDecoder().decode(AvisosDoc.self, from: data)) != nil else { return }
    UserDefaults.standard.set(data, forKey: Self.cacheKey)
    aplicar(data)
  }

  private func aplicar(_ data: Data) {
    guard let doc = try? JSONDecoder().decode(AvisosDoc.self, from: data) else { return }
    avisos = doc.avisos
      .filter { ($0.diasRestantes ?? -1) >= 0 }
      .sorted { ($0.dia ?? .distantFuture) < ($1.dia ?? .distantFuture) }
    Notificador.reprogramar(avisos: avisos)
  }
}

/// Programa las notificaciones locales de macOS: cada aviso notifica al entrar
/// en su ventana (`avisarDiasAntes`) y el mismo día; además se avisa el cierre
/// de la campaña actual (3 días antes y el viernes de cierre).
enum Notificador {
  /// Dispara una notificación de ejemplo a los 3 segundos, para ver cómo se
  /// verán los avisos (y de paso validar el permiso de notificaciones).
  static func probar() {
    guard Bundle.main.bundleIdentifier != nil else { return }
    let centro = UNUserNotificationCenter.current()
    centro.requestAuthorization(options: [.alert, .sound]) { autorizado, _ in
      guard autorizado else { return }
      let contenido = UNMutableNotificationContent()
      contenido.title = "Cierre de facturación C7 — en 2 días"
      contenido.body = "Así se verán los avisos del calendario 📣"
      contenido.sound = .default
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
      centro.add(
        UNNotificationRequest(
          identifier: "prueba-\(UUID().uuidString)", content: contenido, trigger: trigger))
    }
  }

  static func reprogramar(avisos: [Aviso]) {
    // Bajo `swift run` no hay bundle y UNUserNotificationCenter abortaría.
    guard Bundle.main.bundleIdentifier != nil else { return }
    let centro = UNUserNotificationCenter.current()
    centro.requestAuthorization(options: [.alert, .sound]) { autorizado, _ in
      guard autorizado else { return }
      centro.removeAllPendingNotificationRequests()

      for aviso in avisos {
        guard let dia = aviso.dia else { continue }
        if let anticipada = CampaignCalendar.calendario.date(
          byAdding: .day, value: -aviso.ventana, to: dia)
        {
          programar(
            id: aviso.id + "-antes", fecha: anticipada,
            titulo: "\(aviso.titulo) — en \(aviso.ventana) días",
            cuerpo: aviso.detalle ?? "", centro: centro)
        }
        programar(
          id: aviso.id + "-hoy", fecha: dia,
          titulo: "\(aviso.titulo) — hoy",
          cuerpo: aviso.detalle ?? "", centro: centro)
      }

      // Cierre de la campaña actual (siempre viernes).
      if let snap = CampaignCalendar.snapshot() {
        let fin = snap.campana.fin
        if let antes = CampaignCalendar.calendario.date(byAdding: .day, value: -3, to: fin) {
          programar(
            id: snap.campana.id + "-cierre-antes", fecha: antes,
            titulo: "\(snap.campana.etiqueta) cierra este viernes",
            cuerpo: "Cierre de campaña: \(CampaignCalendar.cierre(fin))", centro: centro)
        }
        programar(
          id: snap.campana.id + "-cierre-hoy", fecha: fin,
          titulo: "\(snap.campana.etiqueta) cierra hoy",
          cuerpo: "Último día de la campaña", centro: centro)
      }
    }
  }

  /// Programa una notificación a las 9:00 del día indicado (si aún es futuro).
  private static func programar(
    id: String, fecha: Date, titulo: String, cuerpo: String, centro: UNUserNotificationCenter
  ) {
    var comps = CampaignCalendar.calendario.dateComponents([.year, .month, .day], from: fecha)
    comps.hour = 9
    guard let disparo = CampaignCalendar.calendario.date(from: comps), disparo > Date() else {
      return
    }

    let contenido = UNMutableNotificationContent()
    contenido.title = titulo
    contenido.body = cuerpo
    contenido.sound = .default

    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    centro.add(UNNotificationRequest(identifier: id, content: contenido, trigger: trigger))
  }
}
