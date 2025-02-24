import SpriteKit
import AVFoundation

class GameScene: SKScene {
    private var headNode: SKSpriteNode!
    private var orbs: [SKSpriteNode] = []
    private let audioManager = AudioManager()
    private var touchedOrb: SKSpriteNode?
    private var touchStartTime: TimeInterval?
    private var initialOrbPosition: CGPoint?
    private var selectedAudio: String = "orbAmbient.mp3"
    private let availableSounds = [
        "orbAmbient.mp3", "water-stream.mp3", "water-fall.mp3", "rain.mp3", "thunder.mp3", "ocean-waves.mp3", "birds.mp3", "crickets.mp3", "campfire.mp3", "leaves.mp3",  "wind.mp3", "footstep.mp3", "Ghost.mp3", "Mysterious-Whisper.mp3"
    ] /// will add option to upload own audio files to the user, in future.
    
    // Map audio files and display names
    private let soundDisplayNames: [String: String] = [
        "birds.mp3": "🦉     Birds",
        "campfire.mp3": "🔥     Campfire",
        "crickets.mp3": "🦗     Crickets",
        "footstep.mp3": "👣     Footsteps",
        "Ghost.mp3": "👻     Ghostly Echo",
        "leaves.mp3": "🍃     Rustling Leaves",
        "Mysterious-Whisper.mp3": "🗣️     Mysterious Whispers",
        "ocean-waves.mp3": "🌊     Ocean Waves",
        "orbAmbient.mp3": "🟣     Echo Spheres",
        "rain.mp3": "☔️     Rainfall",
        "thunder.mp3": "🌩️     Thunder",
        "water-fall.mp3": "Waterfall",      // No emoji, uses image
        "water-stream.mp3": "River", // No emoji, uses image
        "wind.mp3": "💨     Wind"
    ]
    
    // Map audio files and orb colors
    private let soundColors: [String: SKColor] = [
        "birds.mp3": SKColor(red: 128/255, green: 128/255, blue: 0, alpha: 1.0),
        "campfire.mp3": .orange,
        "crickets.mp3": .systemBrown,
        "footstep.mp3": .brown,
        "Ghost.mp3": .white,
        "leaves.mp3": .green,
        "Mysterious-Whisper.mp3": .red,
        "ocean-waves.mp3": .cyan,
        "orbAmbient.mp3": .magenta,
        "rain.mp3": .blue,
        "thunder.mp3": .darkGray,
        "water-fall.mp3": SKColor(red: 0, green: 180/255, blue: 128/255, alpha: 1.0),
        "water-stream.mp3": .systemBlue,
        "wind.mp3": .systemYellow
    ]
    
    private let soundImages: [String: (name: String, size: CGSize)] = [
        "water-fall.mp3": (name: "waterfall_icon", size: CGSize(width: 30, height: 30)),
        "water-stream.mp3": (name: "stream_icon", size: CGSize(width: 28, height: 28))
    ]
    
    private var audioMenu: SKNode?
    private var previousPositions: [SKSpriteNode: CGPoint] = [:]
    private var trailSegments: [SKSpriteNode: [SKShapeNode]] = [:]
    private var isDemoActive: Bool = true
    private var demoOrb: SKSpriteNode? 
    private var tutorialNode: SKNode? 
    
    override func didMove(to view: SKView) {
        size = CGSize(width: 1024, height: 768) 
        
        let gradientTexture = SKTexture(size: size, gradientFrom: SKColor(white: 0.16, alpha: 1.0), to: .black)
        let gradient = SKSpriteNode(texture: gradientTexture, size: size)
        gradient.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gradient)
        
        headNode = SKSpriteNode(imageNamed: "head")
        headNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        headNode.size = CGSize(width: 150, height: 150)
        addChild(headNode)
        
        let addButton = SKSpriteNode(imageNamed: "plus_circle_fill")
        addButton.size = CGSize(width: 55, height: 55)
        addButton.position = CGPoint(x: size.width - 50, y: 50)
        addButton.name = "addButton"
        addChild(addButton)
        
        let pillWidth: CGFloat = 400
        let pillHeight: CGFloat = 50
        let pillBox = SKShapeNode(rectOf: CGSize(width: pillWidth, height: pillHeight), cornerRadius: pillHeight / 2)
        pillBox.fillColor = SKColor(white: 0.2, alpha: 0.9)
        pillBox.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        pillBox.lineWidth = 1
        pillBox.position = CGPoint(x: size.width / 2, y: pillHeight / 2 + 26)
        pillBox.zPosition = 10
        addChild(pillBox)
        
        let airpodsIcon = SKSpriteNode(imageNamed: "airpods")
        airpodsIcon.size = CGSize(width: 40, height: 40)
        airpodsIcon.position = CGPoint(x: -pillWidth / 2 + 26, y: 0)
        pillBox.addChild(airpodsIcon)
        
        let messageLabel = SKLabelNode(text: "Experience spatial 3D audio with AirPods")
        messageLabel.fontSize = 18
        messageLabel.fontColor = .white
        messageLabel.fontName = "SFProText-Regular"
        messageLabel.horizontalAlignmentMode = .left
        messageLabel.position = CGPoint(x: -pillWidth / 2 + 55, y: -7)
        pillBox.addChild(messageLabel)
        
        startDemo()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        print("Touch detected at \(location)") // Debug logging
        
        for node in nodes {
            if node.name == "continueButton" {
                dismissTutorial()
                return
            }
        }
        
        guard !isDemoActive else { return }
        
        for node in nodes {
            print("Node name: \(String(describing: node.name)), position: \(node.position), zPosition: \(node.zPosition)") // Debug logging
            if node.name == "addButton" {
                if audioMenu == nil {
                    presentAudioSelectionMenu()
                }
                return
            } else if node.name == "closeButton" {
                removeMenu()
                return
            } else if let soundNode = node as? SKLabelNode, availableSounds.contains(soundNode.name ?? "") {
                selectedAudio = soundNode.name!
                addOrb(with: selectedAudio)
                removeMenu()
                
                if let cell = soundNode.parent as? SKShapeNode {
                    let highlight = SKAction.sequence([
                        SKAction.colorize(with: SKColor(white: 0.4, alpha: 0.5), colorBlendFactor: 1.0, duration: 0.1),
                        SKAction.wait(forDuration: 0.1),
                        SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.1)
                    ])
                    cell.run(highlight)
                }
                return
            } else if let orb = node as? SKSpriteNode, orbs.contains(orb) {
                touchedOrb = orb
                touchStartTime = event?.timestamp
                initialOrbPosition = orb.position
                previousPositions[orb] = orb.position
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let orb = touchedOrb, !isDemoActive else { return }
        let location = touch.location(in: self)
        
        if let lastPosition = previousPositions[orb],
           hypot(location.x - lastPosition.x, location.y - lastPosition.y) > 2.0 {
            orb.position = location
            updateAudioForOrb(orb)
            updateTrail(for: orb, at: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startTime = touchStartTime,
              let orb = touchedOrb, let initialPos = initialOrbPosition, !isDemoActive else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        if nodesAtLocation.contains(orb) {
            let touchDuration = event!.timestamp - startTime
            let finalPos = orb.position
            let distanceMoved = hypot(finalPos.x - initialPos.x, finalPos.y - initialPos.y)
            
            if touchDuration > 0.5 && distanceMoved < 10.0 {
                removeOrb(orb)
            }
        }
        touchedOrb = nil
        touchStartTime = nil
        initialOrbPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        for (orb, segments) in trailSegments {
            trailSegments[orb] = segments.filter { $0.parent != nil }
        }
        
        for orb in orbs {
            updateAudioForOrb(orb)
        }
    }
    
    private func addOrb(with audioFile: String) {
        guard !isDemoActive else { return }
        
        let orbPosition: CGPoint
        if audioFile == "Ghost.mp3" {
            orbPosition = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        } else {
            orbPosition = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        }
        
        let orb = SKSpriteNode(imageNamed: "orb")
        orb.position = orbPosition
        orb.size = CGSize(width: 60, height: 60) 
        orb.name = "orb\(orbs.count)"
        orb.zPosition = 20
        
        orb.color = soundColors[audioFile] ?? .white
        orb.colorBlendFactor = 0.7
        
        let halo = SKSpriteNode(imageNamed: "orb")
        halo.size = CGSize(width: 96, height: 96) 
        halo.alpha = 0.3
        halo.color = orb.color
        halo.colorBlendFactor = 0.5
        halo.zPosition = -1
        orb.addChild(halo)
        
        orb.alpha = 0.0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        let appear = SKAction.group([fadeIn, scaleUp])
        orb.run(appear)
        
        let growCore = SKAction.scale(to: 1.2, duration: 0.8)
        let shrinkCore = SKAction.scale(to: 1.0, duration: 0.8)
        let pulseCore = SKAction.sequence([growCore, shrinkCore])
        let pulseCoreForever = SKAction.repeatForever(pulseCore)
        orb.run(pulseCoreForever)
        
        let growHalo = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.8),
            SKAction.fadeAlpha(to: 0.2, duration: 0.8)
        ])
        let shrinkHalo = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.8),
            SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        ])
        let pulseHalo = SKAction.sequence([growHalo, shrinkHalo])
        let pulseHaloForever = SKAction.repeatForever(pulseHalo)
        halo.run(pulseHaloForever)
        
        addChild(orb)
        orbs.append(orb)
        
        trailSegments[orb] = []
        audioManager.playSound(for: orb.name!, fileName: audioFile)
        updateAudioForOrb(orb)
    }
    
    private func removeOrb(_ orb: SKSpriteNode) {
        guard !isDemoActive else { return }
        
        let explosion = createExplosion(at: orb.position, color: orb.color)
        addChild(explosion)
        
        let removeExplosion = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ])
        explosion.run(removeExplosion)
        
        audioManager.stopSound(for: orb.name!)
        orb.removeFromParent()
        orbs.removeAll { $0 == orb }
        
        trailSegments[orb]?.forEach { $0.removeFromParent() }
        trailSegments.removeValue(forKey: orb)
        previousPositions.removeValue(forKey: orb)
    }
    
    private func updateAudioForOrb(_ orb: SKSpriteNode) {
        let headPosition = headNode.position
        let orbPosition = orb.position
        let dx = Float(orbPosition.x - headPosition.x) / 100.0
        let dy = Float(orbPosition.y - headPosition.y) / 100.0
        let distance = sqrt(dx * dx + dy * dy)
        audioManager.updateSoundPosition(for: orb.name!, position: SIMD3(dx, dy, 0), distance: distance)
        
        let angle = atan2(orbPosition.y - headPosition.y, orbPosition.x - headPosition.x)
        headNode.zRotation = CGFloat(angle) * 0.1
    }
    
    private func updateTrail(for orb: SKSpriteNode, at position: CGPoint) {
        guard !isDemoActive else { return }
        
        guard let lastPosition = previousPositions[orb] else {
            previousPositions[orb] = position
            return
        }
        
        let path = UIBezierPath()
        path.move(to: lastPosition)
        path.addLine(to: position)
        
        let segment = SKShapeNode(path: path.cgPath)
        segment.strokeColor = orb.color
        segment.lineWidth = 12.0
        segment.alpha = 0.4
        segment.zPosition = 15
        
        let fadeDuration = 0.2
        segment.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: fadeDuration),
                SKAction.customAction(withDuration: fadeDuration) { node, elapsed in
                    if let shape = node as? SKShapeNode {
                        let progress = elapsed / CGFloat(fadeDuration)
                        shape.lineWidth = 12.0 * (1 - progress)
                    }
                }
            ]),
            SKAction.removeFromParent()
        ]))
        
        addChild(segment)
        
        if trailSegments[orb] == nil {
            trailSegments[orb] = []
        }
        trailSegments[orb]?.append(segment)
        
        if let segments = trailSegments[orb], segments.count > 15 {
            segments.first?.removeFromParent()
            trailSegments[orb]?.removeFirst()
        }
        
        previousPositions[orb] = position
    }
    
    private func createExplosion(at position: CGPoint, color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 20
        
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleColor = color 
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBirthRate = 800 
        emitter.numParticlesToEmit = 30 
        emitter.particleLifetime = 0.4
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 30
        emitter.particleScale = 0.2 
        emitter.particleScaleRange = 0.2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.3
        emitter.particleAlphaSpeed = -1.5
        emitter.emissionAngle = CGFloat.pi / 2
        emitter.emissionAngleRange = CGFloat.pi * 2
        emitter.particlePositionRange = CGVector(dx: 15, dy: 15)
        
        emitter.particleRotation = 0
        emitter.particleRotationRange = CGFloat.pi * 2
        emitter.particleRotationSpeed = CGFloat.pi
        
        
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    private func presentAudioSelectionMenu() {
        guard !isDemoActive else { return }
        
        let menuWidth: CGFloat = 275
        let menuHeight: CGFloat = size.height * 0.93
        
        let menuBackground = SKShapeNode(rectOf: CGSize(width: menuWidth, height: menuHeight), cornerRadius: 10)
        menuBackground.fillColor = SKColor(white: 0.2, alpha: 0.95)
        menuBackground.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        menuBackground.lineWidth = 1
        menuBackground.position = CGPoint(x: menuWidth / 2 + 20, y: size.height / 2)
        menuBackground.name = "menu"
        menuBackground.zPosition = 10
        addChild(menuBackground)
        audioMenu = menuBackground
        
        let header = SKShapeNode(rectOf: CGSize(width: menuWidth, height: 80))
        header.fillColor = .clear
        header.strokeColor = .clear
        header.position = CGPoint(x: 0, y: menuHeight / 2 - 40 - 10)
        menuBackground.addChild(header)
        
        let headerLabel = SKLabelNode(text: "Select Audio")
        headerLabel.fontSize = 25
        headerLabel.fontColor = .white
        headerLabel.fontName = "SFProText-Bold"
        headerLabel.position = CGPoint(x: -menuWidth / 2 + 20, y: 0)
        headerLabel.horizontalAlignmentMode = .left
        header.addChild(headerLabel)
        
        let closeButton = SKSpriteNode(imageNamed: "xmark_circle_fill")
        closeButton.size = CGSize(width: 24, height: 24)
        closeButton.position = CGPoint(x: menuWidth / 2 - 30, y: 10)
        closeButton.name = "closeButton"
        header.addChild(closeButton)
        
        for (index, sound) in availableSounds.enumerated() {
            let cellHeight: CGFloat = 44
            let cell = SKShapeNode(rectOf: CGSize(width: menuWidth - 20, height: cellHeight))
            cell.fillColor = .clear
            cell.strokeColor = .clear
            cell.position = CGPoint(x: 0, y: menuHeight / 2 - 80 - 2 - cellHeight / 2 - CGFloat(index) * cellHeight)
            cell.name = "cell_\(sound)"
            menuBackground.addChild(cell)
            
            let displayName = soundDisplayNames[sound] ?? sound.replacingOccurrences(of: ".mp3", with: "")
            
            if let (imageName, imageSize) = soundImages[sound] {
                let soundImage = SKSpriteNode(imageNamed: imageName)
                soundImage.size = imageSize
                soundImage.position = CGPoint(x: -menuWidth / 2 + 33, y: 0)
                cell.addChild(soundImage)
                
                let soundNode = SKLabelNode(text: displayName)
                soundNode.fontSize = 18
                soundNode.fontColor = .white
                soundNode.fontName = "SFProText-Regular"
                soundNode.position = CGPoint(x: -menuWidth / 2 + (sound == "water-fall.mp3" ? 63 : 65), y: -5)
                soundNode.horizontalAlignmentMode = .left
                soundNode.name = sound
                cell.addChild(soundNode)
            } else {
                let soundNode = SKLabelNode(text: displayName)
                soundNode.fontSize = 18
                soundNode.fontColor = .white
                soundNode.fontName = "SFProText-Regular"
                soundNode.position = CGPoint(x: -menuWidth / 2 + 20, y: -5)
                soundNode.horizontalAlignmentMode = .left
                soundNode.name = sound
                cell.addChild(soundNode)
            }
            
            if index < availableSounds.count - 1 {
                let separator = SKShapeNode(rectOf: CGSize(width: menuWidth - 40, height: 0))
                separator.fillColor = SKColor(white: 0.5, alpha: 0.3)
                separator.position = CGPoint(x: 0, y: -cellHeight / 2)
                cell.addChild(separator)
            }
        }
        
        menuBackground.alpha = 0
        menuBackground.run(SKAction.fadeIn(withDuration: 0.3))
    }
    
    private func removeMenu() {
        guard !isDemoActive else { return } // Prevent menu removal during demo
        
        if let menu = audioMenu {
            menu.run(SKAction.fadeOut(withDuration: 0.3)) {
                menu.removeFromParent()
            }
            audioMenu = nil
        }
    }
    
    private func startDemo() {
        let footstepOrb = addDemoOrb(audioFile: "footstep.mp3")
        demoOrb = footstepOrb
        
        let circleRadius: CGFloat = 150
        let center = headNode.position
        let duration: TimeInterval = 10.0
        
        let circularPath = UIBezierPath(arcCenter: center, radius: circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        let followPath = SKAction.follow(circularPath.cgPath, asOffset: false, orientToPath: false, duration: duration)
        
        let updateAudioAction = SKAction.run { [weak self] in
            self?.updateAudioForOrb(footstepOrb)
        }
        let updateAudioSequence = SKAction.sequence([updateAudioAction, SKAction.wait(forDuration: 1.0 / 60.0)])
        let repeatUpdateAudio = SKAction.repeat(updateAudioSequence, count: Int(duration * 60))
        
        
        footstepOrb.run(SKAction.group([followPath, repeatUpdateAudio])) {
            self.removeDemoOrb()
            self.showTutorial()
        }
    }
    
    private func addDemoOrb(audioFile: String) -> SKSpriteNode {
        let orbPosition = CGPoint(x: size.width / 2, y: size.height / 2 + 100) // Start point for orb
        
        let orb = SKSpriteNode(imageNamed: "orb")
        orb.position = orbPosition
        orb.size = CGSize(width: 60, height: 60)
        orb.name = "demoOrb"
        orb.zPosition = 20
        
        orb.color = soundColors[audioFile] ?? .white
        orb.colorBlendFactor = 0.7
        
        let halo = SKSpriteNode(imageNamed: "orb")
        halo.size = CGSize(width: 96, height: 96)
        halo.alpha = 0.3
        halo.color = orb.color
        halo.colorBlendFactor = 0.5
        halo.zPosition = -1
        orb.addChild(halo)
        
        orb.alpha = 0.0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        let appear = SKAction.group([fadeIn, scaleUp])
        orb.run(appear)
        
        let growCore = SKAction.scale(to: 1.2, duration: 0.8)
        let shrinkCore = SKAction.scale(to: 1.0, duration: 0.8)
        let pulseCore = SKAction.sequence([growCore, shrinkCore])
        let pulseCoreForever = SKAction.repeatForever(pulseCore)
        orb.run(pulseCoreForever)
        
        let growHalo = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.8),
            SKAction.fadeAlpha(to: 0.2, duration: 0.8)
        ])
        let shrinkHalo = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.8),
            SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        ])
        let pulseHalo = SKAction.sequence([growHalo, shrinkHalo])
        let pulseHaloForever = SKAction.repeatForever(pulseHalo)
        halo.run(pulseHaloForever)
        
        addChild(orb)
        orbs.append(orb)
        
        audioManager.playSound(for: orb.name!, fileName: audioFile)
        updateAudioForOrb(orb)
        
        return orb
    }
    
    private func removeDemoOrb() {
        if let orb = demoOrb {
            audioManager.stopSound(for: orb.name!)
            orb.removeFromParent()
            orbs.removeAll { $0 == orb }
            
            trailSegments[orb]?.forEach { $0.removeFromParent() }
            trailSegments.removeValue(forKey: orb)
            previousPositions.removeValue(forKey: orb)
            demoOrb = nil
        }
    }
    
    private func showTutorial() {
        let tutorialWidth: CGFloat = 450
        let tutorialHeight: CGFloat = 440
        
        let tutorialBackground = SKShapeNode(rectOf: CGSize(width: tutorialWidth, height: tutorialHeight), cornerRadius: 10)
        tutorialBackground.fillColor = SKColor(white: 0.2, alpha: 0.95)
        tutorialBackground.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        tutorialBackground.lineWidth = 1
        tutorialBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tutorialBackground.zPosition = 100
        addChild(tutorialBackground)
        
        let lines = [
            "Welcome to EchoSphere!",
            "",
            "Tap the ➕ button to add sound orbs",
            "Drag orbs to shape your perfect soundscape",
            "Tap and hold to remove an orb",
            "Craft your own immersive soundscape",
            "🎶 Feel the magic of spatial audio come to life! 🎶",
            "",
            "Rotate to landscape for the best experience!"
        ]
        
        var yPosition: CGFloat = tutorialHeight / 2 - 70
        
        for (index, line) in lines.enumerated() {
            let label: SKLabelNode
            if line == "Welcome to EchoSphere!" {
                label = SKLabelNode(text: line)
                label.fontSize = 26
                label.fontColor = .white
                label.fontName = "SFProText-Bold"
                label.horizontalAlignmentMode = .center
            } else {
                label = SKLabelNode(text: line)
                label.fontSize = 18
                label.fontColor = .white
                label.fontName = "SFProText-Regular"
                label.horizontalAlignmentMode = .center
            }
            
            label.position = CGPoint(x: 0, y: yPosition - CGFloat(index * 30))
            label.zPosition = 101
            tutorialBackground.addChild(label)
        }
        
        // Continue button
        let continueButton = SKSpriteNode(imageNamed: "continue_button")
        continueButton.size = CGSize(width: 239, height: 90)
        continueButton.position = CGPoint(x: 0, y: -tutorialHeight / 2 + 55)
        continueButton.name = "continueButton"
        continueButton.zPosition = 101
        tutorialBackground.addChild(continueButton)
        
        tutorialNode = tutorialBackground
    }
    
    private func dismissTutorial() {
        if let tutorial = tutorialNode {
            tutorial.run(SKAction.fadeOut(withDuration: 0.3)) {
                tutorial.removeFromParent()
            }
            tutorialNode = nil
            isDemoActive = false // Enable user interaction
            print("Tutorial dismissed, isDemoActive set to false") // Debug logging
            startRadiatingCircles()
        }
    }
    
    private func startRadiatingCircles() {
        print("Starting radiating circles, isDemoActive: \(isDemoActive)") // Debug logging
        let spawnCircle = SKAction.run { [weak self] in
            self?.createRadiatingCircle()
        }
        let wait = SKAction.wait(forDuration: 5.0)
        let sequence = SKAction.sequence([spawnCircle, wait])
        let repeatForever = SKAction.repeatForever(sequence)
        run(repeatForever, withKey: "radiatingCircles")
    }
    
    private func createRadiatingCircle() {
        print("Creating radiating circle at \(headNode.position)") // Debug logging
        let circle = SKShapeNode(circleOfRadius: 50)
        circle.position = headNode.position
        circle.strokeColor = .white
        circle.fillColor = .clear
        circle.lineWidth = 0.1
        circle.zPosition = 5
        addChild(circle)
        
        let grow = SKAction.scale(to: 20.0, duration: 10.0)
        let fade = SKAction.fadeOut(withDuration: 5.0)
        let animation = SKAction.group([grow, fade])
        let remove = SKAction.removeFromParent()
        circle.run(SKAction.sequence([animation, remove]))
    }
}

extension SKTexture {
    convenience init(size: CGSize, gradientFrom: SKColor, to: SKColor) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors = [gradientFrom.cgColor, to.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        }
        self.init(image: image)
    }
}
