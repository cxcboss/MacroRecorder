import Foundation
import SwiftUI
import Combine

class MacroViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordedEventsCount = 0
    @Published var statusMessage = "准备就绪"
    @Published var showPermissionAlert = false
    @Published var permissionErrorMessage = ""
    
    @Published var savedMacros: [MacroItem] = []
    @Published var selectedMacro: MacroItem?
    @Published var currentRecordingName: String = ""
    @Published var showSaveDialog = false
    @Published var showRenameDialog = false
    @Published var renameText = ""
    @Published var macroToRename: MacroItem?
    
    @Published var playbackMode: PlaybackMode = .once
    @Published var loopCount: Int = 1
    @Published var isInfiniteLoop = false
    
    private let recorder = MouseRecorder()
    private let player = MousePlayer()
    private let storageManager = MacroStorageManager.shared
    
    init() {
        loadMacros()
        setupBindings()
    }
    
    private func setupBindings() {
        recorder.$recordedEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.recordedEventsCount = events.count
            }
            .store(in: &cancellables)
        
        recorder.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recording in
                self?.isRecording = recording
                if recording {
                    self?.statusMessage = "正在录制..."
                    self?.currentRecordingName = "宏 \(Date().formatted(date: .abbreviated, time: .shortened))"
                }
            }
            .store(in: &cancellables)
        
        recorder.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.permissionErrorMessage = error
                    self?.showPermissionAlert = true
                    self?.statusMessage = "录制失败"
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadMacros() {
        savedMacros = storageManager.loadMacros()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        selectedMacro = nil
        recorder.startRecording()
        recorder.isRecording = true
        statusMessage = "正在录制..."
    }
    
    func stopRecording() {
        recorder.stopRecording()
        statusMessage = "录制完成，共记录 \(recordedEventsCount) 个事件"
        
        if recordedEventsCount > 0 {
            showSaveDialog = true
        }
    }
    
    func saveCurrentRecording() {
        guard !recorder.recordedEvents.isEmpty else { return }
        
        let name = currentRecordingName.isEmpty ? "宏 \(savedMacros.count + 1)" : currentRecordingName
        let macro = MacroItem(name: name, events: recorder.recordedEvents)
        
        storageManager.addMacro(macro)
        savedMacros = storageManager.loadMacros()
        
        currentRecordingName = ""
        showSaveDialog = false
        statusMessage = "已保存: \(name)"
    }
    
    func saveRecordingWithName(_ name: String) {
        guard !recorder.recordedEvents.isEmpty else { return }
        
        let macro = MacroItem(name: name, events: recorder.recordedEvents)
        storageManager.addMacro(macro)
        savedMacros = storageManager.loadMacros()
        
        currentRecordingName = ""
        showSaveDialog = false
        statusMessage = "已保存: \(name)"
    }
    
    func deleteMacro(_ macro: MacroItem) {
        storageManager.deleteMacro(macro)
        if selectedMacro?.id == macro.id {
            selectedMacro = nil
        }
        savedMacros = storageManager.loadMacros()
        statusMessage = "已删除: \(macro.name)"
    }
    
    func showRenameDialog(for macro: MacroItem) {
        macroToRename = macro
        renameText = macro.name
        showRenameDialog = true
    }
    
    func renameMacro() {
        guard let macro = macroToRename, !renameText.isEmpty else { return }
        
        var updatedMacro = macro
        updatedMacro.name = renameText
        storageManager.updateMacro(updatedMacro)
        
        if selectedMacro?.id == macro.id {
            selectedMacro = updatedMacro
        }
        
        savedMacros = storageManager.loadMacros()
        showRenameDialog = false
        macroToRename = nil
        renameText = ""
        statusMessage = "已重命名: \(renameText)"
    }
    
    func selectMacro(_ macro: MacroItem) {
        selectedMacro = macro
        statusMessage = "已选择: \(macro.name)"
    }
    
    func play() {
        let eventsToPlay: [MouseEvent]
        
        if let selected = selectedMacro {
            eventsToPlay = selected.events
        } else if !recorder.recordedEvents.isEmpty {
            eventsToPlay = recorder.recordedEvents
        } else {
            statusMessage = "没有可播放的操作"
            return
        }
        
        let mode: PlaybackMode
        if isInfiniteLoop {
            mode = .loop(infinite: true)
        } else {
            mode = .count(loopCount)
        }
        
        isPlaying = true
        statusMessage = "正在播放..."
        
        player.play(events: eventsToPlay, mode: mode) { [weak self] in
            DispatchQueue.main.async {
                self?.isPlaying = false
                self?.statusMessage = "播放完成"
            }
        }
    }
    
    func stopPlaying() {
        player.stop()
        isPlaying = false
        statusMessage = "播放已停止"
    }
    
    func clearCurrentRecording() {
        recorder.recordedEvents.removeAll()
        recordedEventsCount = 0
        statusMessage = "已清除当前录制"
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Security_Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
