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
    var minutes_cycling = 0.0;
    var minutes_walking = 0.0;
    var minutes_running = 0.0;
    var minutes_automotive = 0.0;
    
    var last_time: Date? = nil;
    
    
    // MARK: - Singleton Instance
    static let shared = TransportDetector()
    
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    
    var currentMode: TransportMode = .unknown
    var currentSpeed: Double = 0.0 // in km/h
    
    // Private init prevents creating a second instance
    private init() {}
    
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
                self.currentMode = .automotive
                minutes_automotive += get_time_diff(last: last_time)
            } else if activity.cycling {
                self.currentMode = .cycling
                minutes_cycling += get_time_diff(last: last_time)
            } else if activity.running {
                self.currentMode = .running
                minutes_running += get_time_diff(last: last_time)
            } else if activity.walking {
                self.currentMode = .walking
                minutes_walking += get_time_diff(last: last_time)
            } else if activity.stationary {
                self.currentMode = .stationary
            } else {
                self.currentMode = .unknown
            }
            last_time = Date();
            
            
            print("🏃 Transport Mode: \(self.currentMode.rawValue) (Confidence: \(activity.confidence.rawValue))")
        }
    }  
    
    func get_sustainability_score() -> Double{
        var arg = minutes_cycling + minutes_running + minutes_walking - minutes_automotive;
        return tanh(arg)/2.0 + 0.5
        
    }
    
    func stopDetection() {
        activityManager.stopActivityUpdates()
    }
    
}
