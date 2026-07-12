import AppKit
import CampaignKit
import SwiftUI

/// Popover de la barra de menú: campaña/semana actual, cierre, fechas importantes
/// (avisos remotos de fechas.json) y próximas campañas.
struct PanelView: View {
  let snapshot: CampaignSnapshot?
  var avisos: [Aviso] = []

  /// Naranja de marca Yanbal (#DC582A).
  private let brand = Color(red: 0xDC / 255, green: 0x58 / 255, blue: 0x2A / 255)

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let snap = snapshot {
        contenido(snap)
      } else {
        // Fecha fuera del rango cubierto por la tabla de anclas.
        VStack(alignment: .leading, spacing: 6) {
          Text("Sin datos de calendario")
            .font(.headline)
          Text("La fecha de hoy queda fuera del calendario cargado. Actualiza las anclas del año en CampaignCalendar.swift.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
      }

      Divider()
      pie
    }
    .frame(width: 300)
  }

  @ViewBuilder
  private func contenido(_ snap: CampaignSnapshot) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      // Campaña + semana actual, con el iso de Yanbal como marca.
      // Monocromo (color del texto), igual que el estilo de la barra de macOS.
      HStack(alignment: .top, spacing: 10) {
        YanbalIso()
          .fill(.primary)
          .frame(width: 34, height: 34)
        VStack(alignment: .leading, spacing: 4) {
          Text("Campaña \(snap.campana.etiqueta) · Semana \(snap.semana) de \(snap.campana.totalSemanas)")
            .font(.headline)
          Text(CampaignCalendar.rango(snap.campana))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      // Línea de urgencia: cierre siempre en viernes.
      HStack(spacing: 6) {
        Circle().fill(brand).frame(width: 7, height: 7)
        Text("Cierra el \(CampaignCalendar.cierre(snap.campana.fin)) · \(textoDias(snap.diasRestantes))")
          .font(.callout)
          .fontWeight(.medium)
      }

      // Fechas importantes (avisos publicados en fechas.json vía GitHub).
      if !avisos.isEmpty {
        Divider()
        VStack(alignment: .leading, spacing: 9) {
          Text("Fechas importantes")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          ForEach(avisos.prefix(4)) { aviso in
            filaAviso(aviso)
          }
        }
      }

      if !snap.proximas.isEmpty {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
          Text("Próximas campañas")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          ForEach(snap.proximas) { c in
            HStack {
              Text(c.etiqueta)
                .font(.callout)
                .fontWeight(.semibold)
                .frame(width: 34, alignment: .leading)
              Text(CampaignCalendar.rango(c))
                .font(.callout)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .padding(16)
  }

  private var pie: some View {
    HStack(spacing: 12) {
      Text("Calendario oficial Yanbal")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      Spacer()
      // Dispara una notificación de ejemplo (3 s): sirve para ver el diseño
      // del aviso y validar que el permiso de notificaciones está concedido.
      Button("Probar aviso") { Notificador.probar() }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
      Button("Salir") { NSApplication.shared.terminate(nil) }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
        .keyboardShortcut("q")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  /// Fila de un aviso: chip con la fecha (naranja si ya entró en su ventana de
  /// aviso), título con "en X días" y detalle opcional.
  @ViewBuilder
  private func filaAviso(_ aviso: Aviso) -> some View {
    let dias = aviso.diasRestantes ?? 0
    let pronto = dias <= aviso.ventana
    HStack(alignment: .top, spacing: 9) {
      Text(aviso.dia.map(CampaignCalendar.fechaCorta) ?? aviso.fecha)
        .font(.caption2)
        .fontWeight(.bold)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(minWidth: 52)
        .background(pronto ? brand : Color.primary.opacity(0.08))
        .foregroundStyle(pronto ? Color.white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
      VStack(alignment: .leading, spacing: 1) {
        // foregroundColor (no foregroundStyle) sobre Text concatenado: la
        // variante con estilo requiere macOS 14 y la app apunta a macOS 13.
        (Text(aviso.titulo).fontWeight(.semibold)
          + Text(" · \(textoEnDias(dias))").foregroundColor(.secondary))
          .font(.callout)
        if let detalle = aviso.detalle, !detalle.isEmpty {
          Text(detalle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func textoEnDias(_ dias: Int) -> String {
    switch dias {
    case 0: return "hoy"
    case 1: return "mañana"
    default: return "en \(dias) días"
    }
  }

  private func textoDias(_ dias: Int) -> String {
    switch dias {
    case 0: return "cierra hoy"
    case 1: return "falta 1 día"
    default: return "faltan \(dias) días"
    }
  }
}
