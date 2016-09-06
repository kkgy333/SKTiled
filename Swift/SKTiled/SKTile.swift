//
//  SKTile.swift
//  SKTiled
//
//  Created by Michael Fessenden on 3/21/16.
//  Copyright © 2016 Michael Fessenden. All rights reserved.
//

import SpriteKit


/// represents a single tile object.
open class SKTile: SKSpriteNode {
    
    weak open var layer: SKTileLayer!                   // layer parent, assigned on add
    fileprivate var tileOverlap: CGFloat = 1.5          // tile overlap amount
    open var tileData: SKTilesetData                    // tile data
    open var tileSize: CGSize                           // tile size
    open var highlightColor: SKColor = SKColor.white    // tile highlight color
    
    // blending/visibility
    open var opacity: CGFloat {
        get { return self.alpha }
        set { self.alpha = newValue }
    }
    
    open var visible: Bool {
        get { return !self.isHidden }
        set { self.isHidden = !newValue }
    }
    
    /// Boolean flag to enable/disable texture filtering.
    open var smoothing: Bool {
        get { return texture?.filteringMode != .nearest }
        set { texture?.filteringMode = newValue ? SKTextureFilteringMode.linear : SKTextureFilteringMode.nearest }
    }
    
    // MARK: - Init
    /**
     Initialize the tile with a tile size.
     
     - parameter tileSize: `CGSize` tile size in pixels.
     
     - returns: `SKTile` tile sprite.
     */
    public init(tileSize size: CGSize){
        // create empty tileset data
        tileData = SKTilesetData()
        tileSize = size
        super.init(texture: SKTexture(), color: SKColor.clear, size: tileSize)
    }
    
    /**
     Initialize the tile object with `SKTilesetData`.
     
     - parameter data: `SKTilesetData` tile data.
     
     - returns: `SKTile` tile sprite.
     */
    public init?(data: SKTilesetData){
        guard let tileset = data.tileset else { return nil }
        self.tileData = data
        
        self.tileSize = tileset.tileSize
        super.init(texture: data.texture, color: SKColor.clear, size: data.texture.size())
        orientTile()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Animation
    
    /**
     Check if the tile is animated and run an action to animated it.
     */
    public func runAnimation(){
        guard tileData.isAnimated == true else { return }
        var framesData: [(texture: SKTexture, duration: TimeInterval)] = []
        for frame in tileData.frames {
            guard let frameTexture = tileData.tileset.getTileData(frame.gid)?.texture else {
                print("Error: Cannot access texture for id: \(frame.gid)")
                return
            }
            framesData.append((texture: frameTexture, duration: frame.duration))
        }
        
        let animationAction = SKAction.tileAnimation(framesData)
        run(animationAction, withKey: "ANIMATION")
    }
    
    /// Pauses tile animation
    public var pauseAnimation: Bool = false {
        didSet {
            guard oldValue != pauseAnimation else { return }
            guard let action = action(forKey: "ANIMATION") else { return }
            action.speed = (pauseAnimation == true) ? 0 : 1.0
        }
    }
    
    /**
     Set the tile overlap amount.
     
     - parameter overlap: `CGFloat` tile overlap.
     */
    public func setTileOverlap(_ overlap: CGFloat) {
        // clamp the overlap value.
        var overlapValue = overlap <= 1.5 ? overlap : 1.5
        overlapValue = overlapValue > 0 ? overlapValue : 0
        guard overlapValue != tileOverlap else { return }
        
        let width: CGFloat = tileData.texture.size().width
        let overlapWidth = width + (overlap / width)

        let height: CGFloat = tileData.texture.size().height
        let overlapHeight = height + (overlap / height)
        
        xScale *= overlapWidth / width
        yScale *= overlapHeight / height
        
        tileOverlap = overlap
    }
    
    /**
     Orient the tile based on the current flip flags.
     */
    private func orientTile() {
        // reset orientation
        zRotation = 0
        setScale(1)
        
        if (tileData.flipDiag) {
            if (tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
            }
            
            if (tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(-M_PI_2)   // rotate 90deg
                xScale *= -1                   // flip horizontally
            }

            if (!tileData.flipHoriz && tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
            }

            if (!tileData.flipHoriz && !tileData.flipVert) {
                zRotation = CGFloat(M_PI_2)    // rotate -90deg
                xScale *= -1                   // flip horizontally
            }
        } else {
            if (tileData.flipHoriz) {
                xScale *= -1
            }
            
            if (tileData.flipVert) {
                yScale *= -1
            }
        }
    }
}


public extension SKTile {
    
    /**
     Highlight the tile with a given color.
     
     - parameter color: `SKColor` highlight color.
     */
    public func highlightWithColor(_ color: SKColor?=nil, duration: TimeInterval=1.0, antialiasing: Bool=true) {
        
        let highlight: SKColor = (color == nil) ? highlightColor : color!
        
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .orthogonal {
            childNode(withName: "HIGHLIGHT")?.removeFromParent()
            let highlightNode = SKShapeNode(rectOf: tileSize, cornerRadius: 0)
            highlightNode.strokeColor = highlight.withAlphaComponent(0.1)
            highlightNode.fillColor = highlight.withAlphaComponent(0.35)
            highlightNode.name = "HIGHLIGHT"
            
            highlightNode.isAntialiased = antialiasing
            addChild(highlightNode)
            highlightNode.zPosition = zPosition + 10
            
            // fade out highlight
            removeAction(forKey: "HIGHLIGHT_FADE")
            let fadeAction = SKAction.sequence([
                SKAction.wait(forDuration: duration * 1.5),
                SKAction.fadeAlpha(to: 0, duration: duration/4.0)
                ])
            
            highlightNode.runAction(fadeAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                highlightNode.removeFromParent()
            })
        }
        
        if orientation == .isometric {
            removeAction(forKey: "HIGHLIGHT_FADE")
            let fadeOutAction = SKAction.colorize(with: SKColor.clear, colorBlendFactor: 1, duration: duration)
            runAction(fadeOutAction, withKey: "HIGHLIGHT_FADE", optionalCompletion: {
                let fadeInAction = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 1.5),
                    //fadeOutAction.reversedAction()
                    SKAction.colorize(with: SKColor.clear, colorBlendFactor: 0, duration: duration/4.0)
                    ])
                self.run(fadeInAction, withKey: "HIGHLIGHT_FADE")
            })
        }
    }
    
    /**
     Clear highlighting.
     */
    public func clearHighlight() {
        let orientation = tileData.tileset.tilemap.orientation
        
        if orientation == .orthogonal {
            childNode(withName: "HIGHLIGHT")?.removeFromParent()
        }
        if orientation == .isometric {
            removeAction(forKey: "HIGHLIGHT")
        }
    }
    
    /**
     Playground debugging visualization.
     
     - returns: `AnyObject` visualization
     */
    func debugQuickLookObject() -> AnyObject {
        let shape = SKShapeNode(rectOf: self.tileData.tileset.tileSize)
        return shape
    }
}


/// Shape node used for highlighting and placing tiles.
open class DebugTileShape: SKShapeNode {
    
    open var tileSize: CGSize
    open var orientation: TilemapOrientation = .orthogonal
    open var color: SKColor
    open var layer: TiledLayerObject
    
    
    public init(layer: TiledLayerObject, tileColor: SKColor){
        self.layer = layer
        self.tileSize = layer.tileSize
        self.color = tileColor
        super.init()
        self.orientation = layer.orientation
        drawObject()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func drawObject() {
        // draw the path
        var points: [CGPoint] = []
        
        let tileSizeHalved = CGSize(width: tileSize.halfWidth, height: tileSize.halfHeight)
        
        switch orientation {
        case .orthogonal:
            let origin = CGPoint(x: -tileSize.halfWidth, y: tileSize.halfHeight)
            points = rectPointArray(tileSize, origin: origin)
            
        case .isometric, .staggered:
            points = polygonPointArray(4, radius: tileSizeHalved)
            
        case .hexagonal:
            var hexPoints = Array(repeating: CGPoint.zero, count: 6)
            let staggerX = layer.tilemap.staggerX
            let tileWidth = layer.tilemap.tileWidth
            let tileHeight = layer.tilemap.tileHeight
            
            let sideLengthX = layer.tilemap.sideLengthX
            let sideLengthY = layer.tilemap.sideLengthY
            var variableSize: CGFloat = 0
            
            // flat (broken)
            if (staggerX == true) {
                let r = (tileWidth - sideLengthX) / 2
                let h = tileHeight / 2
                variableSize = tileWidth - (r * 2)
                hexPoints[0] = CGPoint(x: position.x - (variableSize / 2), y: position.y + h)
                hexPoints[1] = CGPoint(x: position.x + (variableSize / 2), y: position.y + h)
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y)
                hexPoints[3] = CGPoint(x: position.x + (variableSize / 2), y: position.y - h)
                hexPoints[4] = CGPoint(x: position.x - (variableSize / 2), y: position.y - h)
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y)
            } else {
                let r = tileWidth / 2
                let h = (tileHeight - sideLengthY) / 2
                variableSize = tileHeight - (h * 2)
                hexPoints[0] = CGPoint(x: position.x, y: position.y + (tileHeight / 2))
                hexPoints[1] = CGPoint(x: position.x + (tileWidth / 2), y: position.y + (variableSize / 2))
                hexPoints[2] = CGPoint(x: position.x + (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[3] = CGPoint(x: position.x, y: position.y - (tileHeight / 2))
                hexPoints[4] = CGPoint(x: position.x - (tileWidth / 2), y: position.y - (variableSize / 2))
                hexPoints[5] = CGPoint(x: position.x - (tileWidth / 2), y: position.y + (variableSize / 2))
            }
            
            points = hexPoints.map{$0.invertedY}
        }
        
        // draw the path
        self.path = polygonPath(points)
        self.isAntialiased = false
        self.lineCap = .butt
        self.miterLimit = 0
        self.lineWidth = 0.5
        
        self.strokeColor = self.color.withAlphaComponent(0.4)
        self.fillColor = self.color.withAlphaComponent(0.35)
        
        // anchor
        childNode(withName: "ANCHOR")?.removeFromParent()
        let anchorRadius: CGFloat = tileSize.height / 12 > 1.0 ? tileSize.height / 24 : 1.0
        let anchor = SKShapeNode(circleOfRadius: anchorRadius)
        anchor.name = "ANCHOR"
        addChild(anchor)
        anchor.fillColor = self.color.withAlphaComponent(0.2)
        anchor.strokeColor = SKColor.clear
        anchor.zPosition = zPosition + 10
        anchor.isAntialiased = true
    }
}