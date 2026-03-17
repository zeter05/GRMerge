import Combine
import SwiftUI
/// Risultato del confronto per ogni nodo
/// Come un enum Java con valori
enum CompareStatus {
    case identical    // uguale in entrambe le cartelle
    case modified     // esiste in entrambe, ma diverso
    case onlyInLeft   // solo nella cartella A
    case onlyInRight  // solo nella cartella B

    var color: Color {
        switch self {
        case .identical:  return .primary
        case .modified:   return .orange
        case .onlyInLeft: return .blue
        case .onlyInRight: return .red
        }
    }

    var icon: String {
        switch self {
        case .identical:  return "equal"
        case .modified:   return "pencil.circle"
        case .onlyInLeft: return "arrow.left.circle"
        case .onlyInRight: return "arrow.right.circle"
        }
    }
}
