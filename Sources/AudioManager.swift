import AVFoundation

class AudioManager {
    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private var players: [String: AVAudioPlayerNode] = [:]
    private var files: [String: AVAudioFile] = [:] // Store files for looping
    
    init() {
        engine.attach(environment)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        do {
            try engine.start()
        } catch {
            print("Audio Engine failed to start: \(error)")
        }
    }
    
    func playSound(for key: String, fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Audio file not found: \(fileName)")
            return
        }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        do {
            let file = try AVAudioFile(forReading: url)
            files[key] = file // Store the file for looping
            engine.connect(player, to: environment, format: file.processingFormat)
            players[key] = player
            
            // Function to schedule looping
            func scheduleLoop() {
                player.scheduleFile(file, at: nil) {
                    DispatchQueue.main.async {
                        if player.isPlaying { // Check if player is still active
                            scheduleLoop() // Recursively schedule again
                        }
                    }
                }
            }
            
            scheduleLoop() // Start the loop
            player.play()
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    func stopSound(for key: String) {
        if let player = players[key] {
            player.stop()
            engine.detach(player)
            players.removeValue(forKey: key)
            files.removeValue(forKey: key) // Clean up file reference
        }
    }
    
    func updateSoundPosition(for key: String, position: SIMD3<Float>, distance: Float) {
        if let player = players[key] {
            player.position = AVAudio3DPoint(x: position.x, y: position.y, z: position.z)
            let maxDistance: Float = 5.0
            let volume = max(0.0, 1.0 - (distance / maxDistance))
            player.volume = volume
        }
    }
}
