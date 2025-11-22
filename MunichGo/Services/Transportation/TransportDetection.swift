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
            
            // Core Motion Logic
            if activity.automotive {
                self.currentMode = .automotive
            } else if activity.cycling {
                self.currentMode = .cycling
            } else if activity.running {
                self.currentMode = .running
            } else if activity.walking {
                self.currentMode = .walking
            } else if activity.stationary {
                self.currentMode = .stationary
            } else {
                self.currentMode = .unknown
            }
            
            print("🏃 Transport Mode: \(self.currentMode.rawValue) (Confidence: \(activity.confidence.rawValue))")
        }
    }
    
    func stopDetection() {
        activityManager.stopActivityUpdates()
    }
    
    // MARK: - 2. Manual Analysis (GPS Trace)
    // Use this if analyzing a history of points (e.g. an uploaded GPX file)
    // or to double-check "Automotive" (e.g. Train vs Car based on max speed)
    func analyzeTrace(points: [CLLocation]) -> TransportMode {
        guard points.count > 1 else { return .stationary }
        
        var totalDistance: CLLocationDistance = 0
        var totalTime: TimeInterval = 0
        var maxSpeed: Double = 0
        
        for i in 0..<points.count - 1 {
            let p1 = points[i]
            let p2 = points[i+1]
            
            let distance = p1.distance(from: p2)
            let timeDiff = p2.timestamp.timeIntervalSince(p1.timestamp)
            
            if timeDiff > 0 {
                let speedMPS = distance / timeDiff // meters per second
                let speedKPH = speedMPS * 3.6
                
                if speedKPH > maxSpeed {
                    maxSpeed = speedKPH
                }
            }
            
            totalDistance += distance
            totalTime += timeDiff
        }
        
        let avgSpeedKPH = (totalDistance / totalTime) * 3.6
        
        return classifyBasedOnSpeed(avgSpeed: avgSpeedKPH, maxSpeed: maxSpeed)
    }
    
    private func classifyBasedOnSpeed(avgSpeed: Double, maxSpeed: Double) -> TransportMode {
        // Heuristics - these are rough estimates
        switch maxSpeed {
        case 0..<2:       return .stationary
        case 2..<7:       return .walking // Avg walk is 5 km/h
        case 7..<25:      return .running // Usain Bolt peaks at 44, normal run is 10-15
        case 25..<50:     return .cycling // E-bikes cap at 25/45, pros go faster
        case 50...:       return .automotive
        default:          return .unknown
        }
    }
    
    // MARK: - Helper to update speed from CLLocationManager
    func updateSpeed(from location: CLLocation) {
        // location.speed is in m/s. Convert to km/h
        // location.speed is -1 if invalid
        if location.speed >= 0 {
            self.currentSpeed = location.speed * 3.6
        }
    }
}
