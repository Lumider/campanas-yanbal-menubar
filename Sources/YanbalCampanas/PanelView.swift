import AppKit
import CampaignKit
import SwiftUI

/// Popover de la barra de menú: campaña/semana actual, cierre y próximas campañas.
struct PanelView: View {
  let snapshot: CampaignSnapshot?

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
    HStack {
      Text("Calendario oficial Yanbal")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      Spacer()
      Button("Salir") { NSApplication.shared.terminate(nil) }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(.secondary)
        .keyboardShortcut("q")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  private func textoDias(_ dias: Int) -> String {
    switch dias {
    case 0: return "cierra hoy"
    case 1: return "falta 1 día"
    default: return "faltan \(dias) días"
    }
  }
}
