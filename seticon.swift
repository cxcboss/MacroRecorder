#!/usr/bin/env swift

import Foundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: seticon <icns-file> <app-bundle>")
    exit(1)
}

let icnsPath = args[1]
let appPath = args[2]

guard let icnsImage = NSImage(contentsOfFile: icnsPath) else {
    print("Error: Cannot load icns file: \(icnsPath)")
    exit(1)
}

let appURL = URL(fileURLWithPath: appPath)
guard let workspace = NSWorkspace.shared as NSWorkspace? else {
    print("Error: Cannot get NSWorkspace")
    exit(1)
}

do {
    try workspace.setIcon(icnsImage, forFile: appPath)
    print("✅ Successfully set icon for \(appPath)")
} catch {
    print("Error setting icon: \(error)")
    exit(1)
}
