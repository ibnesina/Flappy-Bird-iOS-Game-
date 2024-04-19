import SpriteKit

struct PhysicsCategory {
    static let Ghost: UInt32 = 0x1 << 1
    static let Ground: UInt32 = 0x1 << 2
    static let Wall: UInt32 = 0x1 << 3
    static let Score: UInt32 = 0x1 << 4
}

class GameManager {
    // Singleton instance
    static let shared = GameManager()
    
    // Game state variables
    var score: Int = 0
    var isGameOver: Bool = false
    
    // Private initializer to prevent external instantiation
    private init() {}
    
    // Reset game state
    func reset() {
        score = 0
        isGameOver = false
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Singleton instance of GameManager
    let gameManager = GameManager.shared
    
    var Ground = SKSpriteNode()
    var Ghost = SKSpriteNode()
    var wallPair = SKNode()
    var moveAndRemove = SKAction()
    var gameStarted = false
    var scoreLbl = SKLabelNode()
    var died = false
    var restartBTN = SKSpriteNode()
    
    var lastWallSpawnTime: TimeInterval = 0
    let wallSpawnInterval: TimeInterval = 3.0
    
    class func newGameScene() -> GameScene {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        return scene
    }
    
    override func didMove(to view: SKView) {
        createScene()
    }
    
    func createScene() {
        self.physicsWorld.contactDelegate = self
        
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "Background")
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * self.frame.width, y: 0)
            background.name = "background"
            background.size = (self.view?.bounds.size)!
            self.addChild(background)
        }
        
        scoreLbl = SKLabelNode(text: "\(gameManager.score)")
        scoreLbl.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 100)
        scoreLbl.fontName = "Arial"
        scoreLbl.fontSize = 50
        scoreLbl.zPosition = 10
        self.addChild(scoreLbl)
        
        Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.setScale(0.5)
        Ground.position = CGPoint(x: self.frame.midX, y: 0 + Ground.frame.height / 2)
        Ground.physicsBody = SKPhysicsBody(rectangleOf: Ground.size)
        Ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        Ground.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.contactTestBitMask  = PhysicsCategory.Ghost
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.isDynamic = false
        Ground.zPosition = 3
        self.addChild(Ground)
        
        Ghost = SKSpriteNode(imageNamed: "Ghost")
        Ghost.size = CGSize(width: 60, height: 70)
        Ghost.position = CGPoint(x: self.frame.midX - Ghost.frame.width, y: self.frame.midY)
        Ghost.physicsBody = SKPhysicsBody(circleOfRadius: Ghost.frame.height / 2)
        Ghost.physicsBody?.categoryBitMask = PhysicsCategory.Ghost
        Ghost.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        Ghost.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall | PhysicsCategory.Score
        Ghost.physicsBody?.affectedByGravity = false
        Ghost.physicsBody?.isDynamic = true
        Ghost.zPosition = 2
        self.addChild(Ghost)
        
        startGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameStarted && !died && currentTime - lastWallSpawnTime >= wallSpawnInterval {
            spawnWalls()
            lastWallSpawnTime = currentTime
        }
    }
    
    func startGame() {
        gameStarted = true
        lastWallSpawnTime = 0
        Ghost.physicsBody?.affectedByGravity = true
        Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
    }
    
    func spawnWalls() {
        guard !died else {
            // If the player has died, stop spawning walls
            return
        }
        
        // Check if there's already a wall pair on the screen
        if let existingWallPair = self.childNode(withName: "wallPair") {
            // If there's an existing wall pair, wait until it moves off-screen before spawning another one
            let waitAction = SKAction.wait(forDuration: TimeInterval(1.0))
            let removeAction = SKAction.removeFromParent()
            let sequence = SKAction.sequence([waitAction, removeAction])
            existingWallPair.run(sequence) {
                // After the existing wall pair has moved off-screen, spawn a new one
                self.spawnWalls()
            }
            return
        }
        
        let scoreNode = SKSpriteNode(imageNamed: "Coin")
        scoreNode.size = CGSize(width: 50, height: 50)
        scoreNode.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        scoreNode.color = SKColor.blue
        
        wallPair = SKNode()
        wallPair.name = "wallPair"
        
        let topWall = SKSpriteNode(imageNamed: "Wall")
        let btmWall = SKSpriteNode(imageNamed: "Wall")
        
        topWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 + 350)
        btmWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 - 350)
        
        topWall.setScale(0.5)
        btmWall.setScale(0.5)
        
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.affectedByGravity = false
        
        btmWall.physicsBody = SKPhysicsBody(rectangleOf: btmWall.size)
        btmWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        btmWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        btmWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        btmWall.physicsBody?.isDynamic = false
        btmWall.physicsBody?.affectedByGravity = false
        
        wallPair.addChild(topWall)
        wallPair.addChild(btmWall)
        
        wallPair.zPosition = 1
        
        let randomPosition = CGFloat.random(in: -200...200)
        wallPair.position.y = wallPair.position.y +  randomPosition
        wallPair.addChild(scoreNode)
        
        let distance = CGFloat(self.frame.width + wallPair.frame.width)
        let movePipes = SKAction.moveBy(x: -distance - 50, y: 0, duration: TimeInterval(0.008 * distance))
        let removePipes = SKAction.removeFromParent()
        moveAndRemove = SKAction.sequence([movePipes, removePipes])
        
        wallPair.run(moveAndRemove)
        self.addChild(wallPair)
        
        // Run the moveAndRemove action sequence
        wallPair.run(moveAndRemove) {
            // Once the wallPair has moved off-screen, remove it from the scene
            self.wallPair.removeFromParent()
        }
        
        let spawnDelay = TimeInterval(1.0)
        
        let delayAction = SKAction.wait(forDuration: spawnDelay)
        
        let spawnAction = SKAction.run {
            self.spawnWalls()
        }
        
        let spawnSequence = SKAction.sequence([delayAction, spawnAction])
        
        self.run(spawnSequence)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Score {
            gameManager.score += 1
            scoreLbl.text = "\(gameManager.score)"
            secondBody.node?.removeFromParent()
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Ghost || firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Ground || firstBody.categoryBitMask == PhysicsCategory.Ground && secondBody.categoryBitMask == PhysicsCategory.Ghost {
            if !died {
                died = true
                createButton()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted {
            startGame()
        } else {
            guard !died else {
                if let touch = touches.first {
                    let location = touch.location(in: self)
                    if restartBTN.contains(location) {
                        restartScene()
                    }
                }
                return
            }
            Ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
        }
    }
    
    func createButton() {
        restartBTN = SKSpriteNode(imageNamed: "RestartBtn")
        restartBTN.size = CGSize(width: 200, height: 100)
        restartBTN.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        restartBTN.zPosition = 6
        restartBTN.setScale(0)
        self.addChild(restartBTN)
        restartBTN.run(SKAction.scale(to: 1.0, duration: 0.3))
    }
    
    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        gameStarted = false
        died = false
        gameManager.reset()
        createScene()
    }
}
