import Foundation

class MacroStorageManager {
    static let shared = MacroStorageManager()
    
    private let fileManager = FileManager.default
    private var macrosDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("MacroRecordings", isDirectory: true)
    }
    
    private var macrosFileURL: URL {
        macrosDirectory.appendingPathComponent("macros.json")
    }
    
    private init() {
        createMacrosDirectoryIfNeeded()
    }
    
    private func createMacrosDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: macrosDirectory.path) {
            do {
                try fileManager.createDirectory(at: macrosDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create macros directory: \(error)")
            }
        }
    }
    
    func saveMacros(_ macros: [MacroItem]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(macros)
            try data.write(to: macrosFileURL)
        } catch {
            print("Failed to save macros: \(error)")
        }
    }
    
    func loadMacros() -> [MacroItem] {
        guard fileManager.fileExists(atPath: macrosFileURL.path) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: macrosFileURL)
            return try decoder.decode([MacroItem].self, from: data)
        } catch {
            print("Failed to load macros: \(error)")
            return []
        }
    }
    
    func deleteMacro(_ macro: MacroItem) {
        var macros = loadMacros()
        macros.removeAll { $0.id == macro.id }
        saveMacros(macros)
    }
    
    func updateMacro(_ macro: MacroItem) {
        var macros = loadMacros()
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index] = macro
            saveMacros(macros)
        }
    }
    
    func addMacro(_ macro: MacroItem) {
        var macros = loadMacros()
        macros.insert(macro, at: 0)
        saveMacros(macros)
    }
    
    func deleteMacro(byId id: UUID) {
        var macros = loadMacros()
        macros.removeAll { $0.id == id }
        saveMacros(macros)
    }
}
