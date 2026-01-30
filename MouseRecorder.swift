import Foundation
import CoreGraphics
import QuartzCore

struct MouseEvent: Codable, Equatable {
    let type: EventType
    let position: CGPoint
    let timestamp: TimeInterval
    let buttonNumber: Int
    
    enum EventType: String, Codable, Equatable {
        case mouseDown
        case mouseUp
        case mouseDragged
        case mouseMoved
        case scrollWheel
    }
}

class MouseRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedEvents: [MouseEvent] = []
    @Published var errorMessage: String?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var recordingStartTime: TimeInterval = 0
    private let lock = NSLock()
    
    func startRecording() {
        lock.lock()
        defer { lock.unlock() }
        
        recordedEvents.removeAll()
        recordingStartTime = CACurrentMediaTime()
        errorMessage = nil
        isRecording = true
        
        guard let eventTap = createEventTap() else {
            errorMessage = "无法创建事件监听。请确保已在系统设置中授予辅助功能权限。"
            isRecording = false
            print("Failed to create event tap - permission denied or not available")
            return
        }
        
        self.eventTap = eventTap
        print("Event tap created successfully, recording started")
    }
    
    func stopRecording() {
        lock.lock()
        defer { lock.unlock() }
        
        if let eventTap = eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            print("Recording stopped, captured \(recordedEvents.count) events")
        }
        isRecording = false
    }
    
    private func createEventTap() -> CFMachPort? {
        let eventMask: CGEventMask = CGEventMask(1 << CGEventType.leftMouseDown.rawValue) |
                                      CGEventMask(1 << CGEventType.leftMouseUp.rawValue) |
                                      CGEventMask(1 << CGEventType.rightMouseDown.rawValue) |
                                      CGEventMask(1 << CGEventType.rightMouseUp.rawValue) |
                                      CGEventMask(1 << CGEventType.otherMouseDown.rawValue) |
                                      CGEventMask(1 << CGEventType.otherMouseUp.rawValue) |
                                      CGEventMask(1 << CGEventType.mouseMoved.rawValue) |
                                      CGEventMask(1 << CGEventType.leftMouseDragged.rawValue) |
                                      CGEventMask(1 << CGEventType.rightMouseDragged.rawValue) |
                                      CGEventMask(1 << CGEventType.otherMouseDragged.rawValue) |
                                      CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }
            
            let recorder = Unmanaged<MouseRecorder>.fromOpaque(refcon).takeUnretainedValue()
            return recorder.handleEventTap(proxy: proxy, type: type, event: event)
        }
        
        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: userInfo
        ) else {
            return nil
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        return tap
    }
    
    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        lock.lock()
        let shouldRecord = isRecording
        lock.unlock()
        
        guard shouldRecord else {
            return Unmanaged.passRetained(event)
        }
        
        let eventType: MouseEvent.EventType
        switch type {
        case .leftMouseDown:
            eventType = .mouseDown
        case .leftMouseUp:
            eventType = .mouseUp
        case .rightMouseDown:
            eventType = .mouseDown
        case .rightMouseUp:
            eventType = .mouseUp
        case .otherMouseDown:
            eventType = .mouseDown
        case .otherMouseUp:
            eventType = .mouseUp
        case .mouseMoved:
            eventType = .mouseMoved
        case .leftMouseDragged:
            eventType = .mouseDragged
        case .rightMouseDragged:
            eventType = .mouseDragged
        case .otherMouseDragged:
            eventType = .mouseDragged
        case .scrollWheel:
            eventType = .scrollWheel
        default:
            return Unmanaged.passRetained(event)
        }
        
        let position = event.location
        let timestamp = CACurrentMediaTime() - recordingStartTime
        let buttonNumber = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        
        let mouseEvent = MouseEvent(type: eventType,
                                    position: position,
                                    timestamp: timestamp,
                                    buttonNumber: buttonNumber)
        
        lock.lock()
        recordedEvents.append(mouseEvent)
        lock.unlock()
        
        return Unmanaged.passRetained(event)
    }
}
