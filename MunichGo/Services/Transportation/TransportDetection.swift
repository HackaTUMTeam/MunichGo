import Foundation
import CoreMotion
import CoreLocation

enum TransportMode: String {
    case stationary = "Stationary"
    case walking = "Walking"
    case running = "Running"
    case cycling = "Cycling"
    case automotive = "Car/Train"
    case unknown = "Unknown"
}

@Observable
class TransportDetector {
    var minutesCycling = 0.0;
    var minutesWalking = 0.0;
    var minutesRunning = 0.0;
    var minutesAutomotive = 0.0;
    var minutesPublicTransportation = 0.0;
    
    var totalMinutes: Double {
        return minutesCycling + minutesWalking + minutesRunning + minutesAutomotive + minutesPublicTransportation
    }
    var cyclingPercent: Double {
        return minutesCycling / totalMinutes
    }
    var walkingPercent: Double {
        return minutesWalking / totalMinutes
    }
    var runningPercent: Double {
        return minutesRunning / totalMinutes
    }
    var autoPercent: Double {
        return minutesAutomotive / totalMinutes
    }
    var publicPercent: Double {
        return minutesPublicTransportation / totalMinutes
    }
    
    var last_time: Date? = nil;
    
    // MARK: - Singleton Instance
    static let shared = TransportDetector()
    
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    
    private let storageService = StorageService.shared
    
    var currentMode: TransportMode = .unknown
    var currentSpeed: Double = 0.0 // in km/h
    
    private let CYCLING = "cycling"
    private let WALKING = "walking"
    private let RUNNING = "running"
    private let AUTOMOTIVE = "automotiv"
    private let PUBLIC_TRANSPORTATION = "ptransportation"
    
    // Private init prevents creating a second instance
    private init() {
        minutesCycling = storageService.getDouble(key: CYCLING)
        minutesWalking = storageService.getDouble(key: WALKING)
        minutesRunning = storageService.getDouble(key: RUNNING)
        minutesAutomotive = storageService.getDouble(key: AUTOMOTIVE)
        minutesPublicTransportation = storageService.getDouble(key: PUBLIC_TRANSPORTATION)
    }
    
    // MARK: - 1. Live Detection (Core Motion)
    // Best for battery life and accuracy (uses M-chip)
    func startDetection() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("❌ Core Motion not available on this device.")
            return
        }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            func get_time_diff(last: Date?) -> Double{
                if last != nil{
                    return abs( Double(Date().timeIntervalSince(last!)))
                }
                return 0.0
            }
            
            // Core Motion Logic
            if activity.automotive {
                let choice = Int.random(in: 0..<3)
                if choice == 0 {
                    self.currentMode = .automotive
                    minutesAutomotive += get_time_diff(last: last_time)
                    storageService.saveDouble(minutesAutomotive, key: AUTOMOTIVE)
                } else {
                    minutesPublicTransportation += get_time_diff(last: last_time)
                    storageService.saveDouble(minutesPublicTransportation, key: PUBLIC_TRANSPORTATION)
                }
            } else if activity.cycling {
                self.currentMode = .cycling
                minutesCycling += get_time_diff(last: last_time)
                storageService.saveDouble(minutesCycling, key: CYCLING)
            } else if activity.running {
                self.currentMode = .running
                minutesRunning += get_time_diff(last: last_time)
                storageService.saveDouble(minutesRunning, key: RUNNING)
            } else if activity.walking {
                self.currentMode = .walking
                minutesWalking += get_time_diff(last: last_time)
                storageService.saveDouble(minutesWalking, key: WALKING)
            } else if activity.stationary {
                self.currentMode = .stationary
            } else {
                self.currentMode = .unknown
            }
            last_time = Date();
            
            print("🏃 Transport Mode: \(self.currentMode.rawValue) (Confidence: \(activity.confidence.rawValue))")
        }
    }
    
    func getSustainabilityScore() -> Double{
        let arg = minutesCycling + minutesRunning + minutesWalking + minutesPublicTransportation - minutesAutomotive;
        return tanh(arg)/2.0 + 0.5
        
    }
    
    func stopDetection() {
        activityManager.stopActivityUpdates()
    }
    
}
