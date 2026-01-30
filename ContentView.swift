import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MacroViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                macroListSection
                    .frame(width: geometry.size.width * 0.4)
                
                Divider()
                    .frame(height: geometry.size.height - 40)
                
                recordingSection
                    .frame(width: geometry.size.width * 0.6)
            }
            .padding(20)
        }
        .frame(width: 700, height: 500)
        .alert("权限错误", isPresented: $viewModel.showPermissionAlert) {
            Button("打开系统设置") {
                openSystemSettings()
            }
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.permissionErrorMessage)
        }
        .alert("保存宏", isPresented: $viewModel.showSaveDialog) {
            TextField("宏名称", text: $viewModel.currentRecordingName)
            Button("保存") {
                viewModel.saveCurrentRecording()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请输入宏名称以保存录制内容")
        }
        .alert("重命名", isPresented: $viewModel.showRenameDialog) {
            TextField("宏名称", text: $viewModel.renameText)
            Button("确定") {
                viewModel.renameMacro()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请输入新的宏名称")
        }
    }
    
    private var macroListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.accentColor)
                Text("已保存的宏")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.savedMacros.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.savedMacros.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无保存的宏")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("录制完成后会自动保存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.savedMacros) { macro in
                            MacroListItem(
                                macro: macro,
                                isSelected: viewModel.selectedMacro?.id == macro.id,
                                onSelect: { viewModel.selectMacro(macro) },
                                onRename: { viewModel.showRenameDialog(for: macro) },
                                onDelete: { viewModel.deleteMacro(macro) }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var recordingSection: some View {
        VStack(spacing: 16) {
            recordAndPlaySection
            
            Divider()
            
            currentRecordingInfo
            
            if !viewModel.savedMacros.isEmpty {
                Divider()
                
                macroDetailsSection
            }
            
            Spacer()
            
            statusSection
        }
        .padding(.horizontal)
    }
    
    private var recordAndPlaySection: some View {
        HStack(spacing: 20) {
            recordButton
            playButton
        }
        .padding(.vertical, 10)
    }
    
    private var recordButton: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isRecording ? "stop.fill" : "record.circle.fill")
                    .font(.title3)
                Text(viewModel.isRecording ? "停止录制" : "开始录制")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(width: 140, height: 45)
            .background(viewModel.isRecording ? Color.red : Color.blue)
            .cornerRadius(10)
        }
        .disabled(viewModel.isPlaying)
        .opacity(viewModel.isPlaying ? 0.5 : 1.0)
    }
    
    private var playButton: some View {
        Button(action: {
            if viewModel.isPlaying {
                viewModel.stopPlaying()
            } else {
                viewModel.play()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.circle.fill")
                    .font(.title3)
                Text(viewModel.isPlaying ? "停止播放" : "播放")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(width: 140, height: 45)
            .background(viewModel.isPlaying ? Color.orange : Color.green)
            .cornerRadius(10)
        }
        .disabled(viewModel.isRecording && viewModel.recordedEventsCount == 0 && viewModel.selectedMacro == nil)
        .opacity(viewModel.isRecording && viewModel.recordedEventsCount == 0 && viewModel.selectedMacro == nil ? 0.5 : 1.0)
    }
    
    private var currentRecordingInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.accentColor)
                Text("当前录制")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if viewModel.recordedEventsCount > 0 {
                    Button(action: { viewModel.clearCurrentRecording() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                Text("\(viewModel.recordedEventsCount) 个事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let selected = viewModel.selectedMacro {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已选择: \(selected.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor.opacity(0.5))
        .cornerRadius(10)
    }
    
    private var macroDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.accentColor)
                Text("播放设置")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("播放模式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("播放模式", selection: $viewModel.isInfiniteLoop) {
                        Text("指定次数").tag(false)
                        Text("无限循环").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                
                if !viewModel.isInfiniteLoop {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("循环次数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button(action: {
                                if viewModel.loopCount > 1 {
                                    viewModel.loopCount -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(viewModel.loopCount)")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 40)
                            
                            Button(action: {
                                if viewModel.loopCount < 999 {
                                    viewModel.loopCount += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Text("∞")
                        .font(.title)
                        .foregroundColor(.accentColor)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(backgroundColor.opacity(0.5))
        .cornerRadius(10)
    }
    
    private var statusSection: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.accentColor)
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: NSColor.windowBackgroundColor) : Color.white
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Security_Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct MacroListItem: View {
    let macro: MacroItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(macro.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Label("\(macro.eventCount)", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Label(macro.formattedDuration, systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Menu {
                Button(action: onRename) {
                    Label("重命名", systemImage: "pencil")
                }
                Button(action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? accentColor.opacity(0.1) : backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1)
        )
    }
    
    private var accentColor: Color {
        .blue
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(nsColor: NSColor.controlBackgroundColor) : Color(nsColor: NSColor.textBackgroundColor)
    }
}
