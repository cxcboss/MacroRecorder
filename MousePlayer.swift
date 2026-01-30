import Foundation
import CoreGraphics

enum PlaybackMode {
    case once
    case loop(infinite: Bool)
    case count(Int)
}

class MousePlayer {
    private var isPlaying = false
    private var currentEventIndex = 0
    private var events: [MouseEvent] = []
    private var playbackTask: DispatchWorkItem?
    private var remainingPlays: Int = 0
    private var currentPlaybackMode: PlaybackMode = .once
    private var completionCallback: (() -> Void)?
    
    func play(events: [MouseEvent], mode: PlaybackMode, completion: @escaping () -> Void) {
        guard !events.isEmpty else {
            completion()
            return
        }
        
        self.events = events
        currentEventIndex = 0
        isPlaying = true
        currentPlaybackMode = mode
        completionCallback = completion
        
        switch mode {
        case .once:
            remainingPlays = 1
        case .loop(let infinite):
            remainingPlays = infinite ? Int.max : 1
        case .count(let count):
            remainingPlays = count
        }
        
        let task = DispatchWorkItem { [weak self] in
            self?.playNextEvent()
        }
        self.playbackTask = task
        
        DispatchQueue.main.async(execute: task)
    }
    
    func stop() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
        remainingPlays = 0
    }
    
    private func playNextEvent() {
        guard isPlaying, currentEventIndex < events.count else {
            finishPlayback()
            return
        }
        
        let event = events[currentEventIndex]
        let delay: TimeInterval
        
        if currentEventIndex < events.count - 1 {
            delay = events[currentEventIndex + 1].timestamp - event.timestamp
        } else {
            delay = 0
        }
        
        simulateMouseEvent(event: event)
        currentEventIndex += 1
        
        if isPlaying {
            let task = DispatchWorkItem { [weak self] in
                self?.playNextEvent()
            }
            self.playbackTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + max(delay, 0.001), execute: task)
        } else {
            finishPlayback()
        }
    }
    
    private func finishPlayback() {
        remainingPlays -= 1
        
        if remainingPlays > 0 && isPlaying {
            currentEventIndex = 0
            let task = DispatchWorkItem { [weak self] in
                self?.playNextEvent()
            }
            self.playbackTask = task
            DispatchQueue.main.async(execute: task)
        } else {
            isPlaying = false
            DispatchQueue.main.async { [weak self] in
                self?.completionCallback?()
            }
        }
    }
    
    private func simulateMouseEvent(event: MouseEvent) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        switch event.type {
        case .mouseDown:
            let eventType = mouseEventType(for: event, isDown: true)
            let button = mouseButton(for: event)
            guard let downEvent = CGEvent(mouseEventSource: source, mouseType: eventType, mouseCursorPosition: event.position, mouseButton: button) else {
                return
            }
            downEvent.post(tap: .cghidEventTap)
            
        case .mouseUp:
            let eventType = mouseEventType(for: event, isDown: false)
            let button = mouseButton(for: event)
            guard let upEvent = CGEvent(mouseEventSource: source, mouseType: eventType, mouseCursorPosition: event.position, mouseButton: button) else {
                return
            }
            upEvent.post(tap: .cghidEventTap)
            
        case .mouseMoved:
            let eventType = CGEventType.mouseMoved
            guard let moveEvent = CGEvent(mouseEventSource: source, mouseType: eventType, mouseCursorPosition: event.position, mouseButton: .left) else {
                return
            }
            moveEvent.post(tap: .cghidEventTap)
            
        case .mouseDragged:
            let eventType = mouseEventType(for: event, isDown: true)
            guard let dragEvent = CGEvent(mouseEventSource: source, mouseType: eventType, mouseCursorPosition: event.position, mouseButton: mouseButton(for: event)) else {
                return
            }
            dragEvent.post(tap: .cghidEventTap)
            
        case .scrollWheel:
            guard let scrollEvent = CGEvent(scrollWheelEvent2Source: source, units: .line, wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0) else {
                return
            }
            scrollEvent.post(tap: .cghidEventTap)
        }
    }
    
    private func mouseButton(for event: MouseEvent) -> CGMouseButton {
        switch event.buttonNumber {
        case 0:
            return .left
        case 1:
            return .right
        default:
            return .center
        }
    }
    
    private func mouseEventType(for event: MouseEvent, isDown: Bool) -> CGEventType {
        switch event.buttonNumber {
        case 0:
            return isDown ? .leftMouseDown : .leftMouseUp
        case 1:
            return isDown ? .rightMouseDown : .rightMouseUp
        default:
            return isDown ? .otherMouseDown : .otherMouseUp
        }
    }
}
