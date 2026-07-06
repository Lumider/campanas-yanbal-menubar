import Foundation

/// Motor de cálculo del calendario campañal Yanbal.
///
/// Regla de negocio (ver `CALENDARIO.md`):
/// - 13 campañas por año (C01–C13), contiguas y sin huecos.
/// - Cada campaña dura 4 semanas (28 días), de sábado a viernes.
/// - 13×28 = 364 días → un día menos que el año, por eso el arranque se corre y
///   cada ciertos años una C13 extendida de 5 semanas (35 días) reajusta el calendario.
///
/// La fuente de verdad es una TABLA DE ANCLAS: la fecha de inicio (sábado) de C01
/// por año, copiada del calendario oficial. Es el dato mínimo y fiable. NO se asume
/// "primer sábado de enero" porque 2024 lo viola (C01 = 30 dic 2023). Todo lo demás
/// se deriva con aritmética de fechas.

/// Una campaña concreta con su rango de fechas.
public struct Campaign: Identifiable, Equatable {
  public let year: Int
  /// 1…13
  public let numero: Int
  /// Sábado de inicio (a mediodía local, para evitar bordes de DST).
  public let inicio: Date
  /// Viernes de cierre (a mediodía local).
  public let fin: Date

  public var id: String { "\(year)-C\(numero)" }

  /// "C7"
  public var etiqueta: String { "C\(numero)" }

  /// Número de semanas de la campaña (4 normal, 5 si es la C13 extendida).
  public var totalSemanas: Int {
    let dias = CampaignCalendar.diasEntre(inicio, fin) + 1
    return Int((Double(dias) / 7.0).rounded())
  }
}

/// Estado listo para la UI: campaña/semana actual, cierre, y próximas campañas.
public struct CampaignSnapshot {
  public let campana: Campaign
  /// Semana dentro de la campaña (1…5).
  public let semana: Int
  /// Días que faltan para el cierre (0 = cierra hoy).
  public let diasRestantes: Int
  /// Las próximas campañas, en orden.
  public let proximas: [Campaign]

  /// "C7 · S3" — etiqueta compacta para la barra de menú.
  public var etiquetaBarra: String { "\(campana.etiqueta) · S\(semana)" }
}

public enum CampaignCalendar {
  /// Anclas: año → inicio (sábado) de C01. Copiadas de CALENDARIO.md.
  /// Al conocerse un año nuevo del calendario oficial, se añade aquí su C01 y la C13
  /// del año anterior se recalcula sola (28 vs 35 días) entre anclas consecutivas.
  private static let anclasC01: [Int: DateComponents] = [
    2024: DateComponents(year: 2023, month: 12, day: 30),
    2025: DateComponents(year: 2025, month: 1, day: 4),
    2026: DateComponents(year: 2026, month: 1, day: 3),
    2027: DateComponents(year: 2027, month: 1, day: 2),
  ]

  /// Calendario gregoriano fijo; el resto de la app usa la zona local del equipo.
  public static let calendario: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone.current
    return cal
  }()

  // MARK: - Utilidades de fecha

  /// Construye una fecha a mediodía local (evita saltos por DST al sumar días).
  private static func fecha(_ comps: DateComponents) -> Date {
    var c = comps
    c.hour = 12
    c.minute = 0
    c.second = 0
    return calendario.date(from: c)!
  }

  private static func sumandoDias(_ dias: Int, a fecha: Date) -> Date {
    calendario.date(byAdding: .day, value: dias, to: fecha)!
  }

  /// Días de calendario entre dos fechas (b − a), ignorando la hora.
  static func diasEntre(_ a: Date, _ b: Date) -> Int {
    let d1 = calendario.startOfDay(for: a)
    let d2 = calendario.startOfDay(for: b)
    return calendario.dateComponents([.day], from: d1, to: d2).day ?? 0
  }

  // MARK: - Construcción de campañas

  /// Las 13 campañas del año indicado, o nil si no hay ancla para ese año.
  static func campanas(delAno year: Int) -> [Campaign]? {
    guard let anclaComps = anclasC01[year] else { return nil }
    let c01Inicio = fecha(anclaComps)

    var resultado: [Campaign] = []

    // C01–C12: bloques fijos de 28 días.
    for n in 1...12 {
      let inicio = sumandoDias((n - 1) * 28, a: c01Inicio)
      let fin = sumandoDias(27, a: inicio)
      resultado.append(Campaign(year: year, numero: n, inicio: inicio, fin: fin))
    }

    // C13: empieza al día siguiente del cierre de C12 y termina la víspera del
    // C01 del año siguiente (así los 28 o 35 días salen solos). Sin ancla del
    // año siguiente, se asume 28 días (4 semanas) como valor por defecto.
    let c12Fin = resultado[11].fin
    let c13Inicio = sumandoDias(1, a: c12Fin)
    let c13Fin: Date
    if let siguienteComps = anclasC01[year + 1] {
      c13Fin = sumandoDias(-1, a: fecha(siguienteComps))
    } else {
      c13Fin = sumandoDias(27, a: c13Inicio)
    }
    resultado.append(Campaign(year: year, numero: 13, inicio: c13Inicio, fin: c13Fin))

    return resultado
  }

  /// Todas las campañas de los años [year-1, year, year+1] presentes en la tabla,
  /// ordenadas por fecha de inicio. Sirve para localizar la actual y sus próximas.
  private static func campanasAlrededor(de year: Int) -> [Campaign] {
    var todas: [Campaign] = []
    for y in (year - 1)...(year + 1) {
      if let cs = campanas(delAno: y) { todas.append(contentsOf: cs) }
    }
    return todas.sorted { $0.inicio < $1.inicio }
  }

  // MARK: - Snapshot para la UI

  /// Estado del calendario para una fecha dada (por defecto, hoy). nil si la fecha
  /// cae fuera del rango cubierto por la tabla de anclas.
  public static func snapshot(para fechaConsulta: Date = Date(), proximas cuantas: Int = 3)
    -> CampaignSnapshot?
  {
    let year = calendario.component(.year, from: fechaConsulta)
    let todas = campanasAlrededor(de: year)
    let dia = calendario.startOfDay(for: fechaConsulta)

    guard
      let indiceActual = todas.firstIndex(where: {
        let ini = calendario.startOfDay(for: $0.inicio)
        let fin = calendario.startOfDay(for: $0.fin)
        return dia >= ini && dia <= fin
      })
    else { return nil }

    let actual = todas[indiceActual]

    // semana = ⌈(hoy − inicio + 1) / 7⌉  (ver CALENDARIO.md).
    let diasTranscurridos = diasEntre(actual.inicio, fechaConsulta) + 1
    let semana = Int((Double(diasTranscurridos) / 7.0).rounded(.up))

    let diasRestantes = max(0, diasEntre(fechaConsulta, actual.fin))

    let proximas = Array(todas[(indiceActual + 1)...].prefix(cuantas))

    return CampaignSnapshot(
      campana: actual,
      semana: semana,
      diasRestantes: diasRestantes,
      proximas: proximas
    )
  }

  // MARK: - Formato en español

  private static let formatoRango: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "es")
    f.setLocalizedDateFormatFromTemplate("d MMM")
    return f
  }()

  private static let formatoCierre: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "es")
    f.setLocalizedDateFormatFromTemplate("EEEE d MMM")
    return f
  }()

  /// "20 jun"
  public static func fechaCorta(_ fecha: Date) -> String { formatoRango.string(from: fecha) }

  /// "20 jun – 17 jul"
  public static func rango(_ c: Campaign) -> String {
    "\(fechaCorta(c.inicio)) – \(fechaCorta(c.fin))"
  }

  /// "viernes 17 jul"
  public static func cierre(_ fecha: Date) -> String { formatoCierre.string(from: fecha) }
}
