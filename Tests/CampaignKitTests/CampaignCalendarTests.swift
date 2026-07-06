import XCTest

@testable import CampaignKit

/// Verifica el motor contra el calendario oficial (ver CALENDARIO.md),
/// incluidos los bordes de año y la C13 extendida de 2024 (5 semanas).
final class CampaignCalendarTests: XCTestCase {
  private func fecha(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents()
    c.year = y
    c.month = m
    c.day = d
    c.hour = 12
    return CampaignCalendar.calendario.date(from: c)!
  }

  func testCampanaActual2026() throws {
    let snap = try XCTUnwrap(CampaignCalendar.snapshot(para: fecha(2026, 7, 6)))
    XCTAssertEqual(snap.campana.numero, 7)
    XCTAssertEqual(snap.semana, 3)
    XCTAssertEqual(snap.etiquetaBarra, "C7 · S3")
    XCTAssertEqual(snap.diasRestantes, 11)
    // Cierre siempre en viernes.
    XCTAssertEqual(CampaignCalendar.calendario.component(.weekday, from: snap.campana.fin), 6)
    XCTAssertEqual(snap.campana.fin, fecha(2026, 7, 17))
  }

  func testProximas2026() throws {
    let snap = try XCTUnwrap(CampaignCalendar.snapshot(para: fecha(2026, 7, 6), proximas: 3))
    XCTAssertEqual(snap.proximas.map(\.numero), [8, 9, 10])
    XCTAssertEqual(snap.proximas[0].inicio, fecha(2026, 7, 18))
    XCTAssertEqual(snap.proximas[0].fin, fecha(2026, 8, 14))
    XCTAssertEqual(snap.proximas[2].fin, fecha(2026, 10, 9))
  }

  func testInicioDeAno2026() throws {
    let snap = try XCTUnwrap(CampaignCalendar.snapshot(para: fecha(2026, 1, 3)))
    XCTAssertEqual(snap.campana.numero, 1)
    XCTAssertEqual(snap.semana, 1)
  }

  func testC13Extendida2024() throws {
    // C13 2024: 30 nov 2024 → 3 ene 2025 (35 días · 5 semanas).
    let snap = try XCTUnwrap(CampaignCalendar.snapshot(para: fecha(2024, 12, 31)))
    XCTAssertEqual(snap.campana.numero, 13)
    XCTAssertEqual(snap.campana.totalSemanas, 5)
    XCTAssertEqual(snap.semana, 5)
    XCTAssertEqual(snap.campana.inicio, fecha(2024, 11, 30))
    XCTAssertEqual(snap.campana.fin, fecha(2025, 1, 3))
  }

  func testBordeC13aC01() throws {
    // El 2 ene 2027 ya es C01 2027 (la víspera cierra C13 2026).
    let snap = try XCTUnwrap(CampaignCalendar.snapshot(para: fecha(2027, 1, 2)))
    XCTAssertEqual(snap.campana.numero, 1)
    XCTAssertEqual(snap.campana.year, 2027)
    XCTAssertEqual(snap.semana, 1)
  }
}
