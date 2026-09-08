import SwiftUI

/// Spacing and radii from the `Miku · Métrica` collection. Everything sits on an
/// 8-grid; radii grow with the surface so the curve reads equally soft at any size.
enum Espacio {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum Radio {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 26
    static let completo: CGFloat = 999

    /// Radii actually in use, named by the surface they belong to (DISENO.md §6).
    static let ventana: CGFloat = 12
    static let losa: CGFloat = 20
    static let panel: CGFloat = 14
    static let fila: CGFloat = 11
    static let boton: CGFloat = 9
    static let capsula: CGFloat = 28
    static let pastilla: CGFloat = 22
    /// Rail slots that hold a 20 pt icon.
    static let ranura: CGFloat = 12
}
