//
//  GameViewController.swift
//  ZiggyZag
//
//  Created by Luke Klepfer on 10/5/16.
//  Copyright © 2016 Luke. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import GameKit

struct bodyNames{
    static let Person = 0x1 << 1
    static let Coin = 0x1 << 2
}

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, GKGameCenterControllerDelegate {

    let scene = SCNScene()
    let cameraNode = SCNNode()
    let firstBox = SCNNode()
    var person = SCNNode()
    var goingLeft = Bool()
    var tempBox = SCNNode()
    var boxNum = Int()
    var prevBoxNum = Int()
    var firstOne = Bool()
    var score = Int()
    var highscore = Int()
    var dead = Bool()
    
    var scoreLbl = UILabel()
    var highsScoreLbl = UILabel()
    
    var gameButton = UIButton()
    
    
    override func viewDidLoad() {
        
        authPlayer()
        
        self.createScene()
        scene.physicsWorld.contactDelegate = self
        
        gameButton = UIButton(type: UIButtonType.custom)
        gameButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        gameButton.center = CGPoint(x: self.view.frame.width - 40, y: 60)
        gameButton.imageView!.image = UIImage(named: "gamecenter")
        self.view.addSubview(gameButton)
        gameButton.addTarget(self, action: Selector(("viewLeaderBoard")), for: .touchUpInside)
        
        scoreLbl = UILabel(frame: CGRect(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5, width: self.view.frame.width, height: 100))
        scoreLbl.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 - self.view.frame.height / 2.5)
        scoreLbl.textAlignment = .center
        scoreLbl.text = "Score: \(score)"
        scoreLbl.textColor = UIColor.darkGray
        self.view.addSubview(scoreLbl)
        
        highsScoreLbl = UILabel(frame: CGRect(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5, width: self.view.frame.width, height: 100))
        highsScoreLbl.textAlignment = .center
        highsScoreLbl.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2 + self.view.frame.height / 2.5)
        highsScoreLbl.text = "Highscore: \(highscore)"
        highsScoreLbl.textColor = UIColor.darkGray
        self.view.addSubview(highsScoreLbl)
        
    }
    
    func updateLabels(){
        
        scoreLbl.text = "Score: \(score)"
        highsScoreLbl.text = "Highscore: \(highscore)"
        
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == bodyNames.Person && nodeB.physicsBody?.categoryBitMask == bodyNames.Coin{
            
            addScore()
            nodeB.removeFromParentNode()
        }
        
        if nodeA.physicsBody?.categoryBitMask == bodyNames.Coin && nodeB.physicsBody?.categoryBitMask == bodyNames.Person {
            
            addScore()
            nodeA.removeFromParentNode()
        }
        
    }
    
    func addScore(){
        
        score+=1
        //print("Score: \(score)")
        
        if score > highscore {
            highscore = score
            let scoreDefault = UserDefaults.standard
            scoreDefault.set(highscore, forKey: "highscore")
            //print(highscore)
        }
        self.performSelector(onMainThread: #selector(GameViewController.updateLabels), with: nil, waitUntilDone: false)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if dead == false
        {
            let deleteBox = self.scene.rootNode.childNode(withName: "\(prevBoxNum)", recursively: true)
        
            let currentBox = self.scene.rootNode.childNode(withName: "\(prevBoxNum + 1)", recursively: true)
        
            if (deleteBox?.position.x)! > person.position.x + 1 || (deleteBox?.position.z)! > person.position.z + 1{
                //if this is true our person is no longer touching this box and it may be deleted. (+1 for looks)
            
                prevBoxNum += 1
                fadeOut(node: deleteBox!)
                deleteBox?.removeFromParentNode()
                createBox()
            
            }
        
            if person.position.x > (currentBox?.position.x)! - 0.5 && person.position.x < (currentBox?.position.x)! + 0.5 || person.position.z > (currentBox?.position.z)! - 0.5 && person.position.z < (currentBox?.position.z)! + 0.5{
                //We are on our platform
                
            }else{
                murder()
               dead = true
                
            }
        }
    }
    
    func murder(){
        
        person.runAction(SCNAction.move(to: SCNVector3Make(person.position.x, person.position.y - 10, person.position.z), duration: 1.0))
        
        let wait = SCNAction.wait(duration: 0.5)
        let sequence = SCNAction.sequence([wait, SCNAction.run({
            node in
            
            self.scene.rootNode.enumerateChildNodes({
                node, stop in
                node.removeFromParentNode()
                
                })
            
        }), SCNAction.run({
            node in
            
            self.createScene()
            
        
        })])
        
        person.runAction(sequence)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if dead == false{
    
            if goingLeft == false{
                person.removeAllActions()
                person.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(-100, 0, 0), duration: 20)))
                goingLeft = true
            }else{
                person.removeAllActions()
                person.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3Make(0, 0, -100), duration: 20)))
                goingLeft = false
            
            }
        }
        
    }
    
    func creatCoin(box: SCNNode){
        scene.physicsWorld.gravity = SCNVector3Make(0, 0, 0)
        let spin = SCNAction.rotate(by: (3.14 * 2), around: SCNVector3Make(0, 0.5, 0), duration: 0.7)
        let randNum = arc4random() % 8
        if randNum == 3{
            //create coin
            let coinScene = SCNScene(named: "Coin.dae")
            let coin = coinScene?.rootNode.childNode(withName: "Coin", recursively: true)
            coin?.position = SCNVector3Make(box.position.x, box.position.y + 1, box.position.z)
            coin?.scale = SCNVector3Make(0.2, 0.2, 0.2)
            
            coin?.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: SCNPhysicsShape(node: coin!, options: nil))
            coin?.physicsBody?.categoryBitMask = bodyNames.Coin
            coin?.physicsBody?.contactTestBitMask = bodyNames.Person
            coin?.physicsBody?.collisionBitMask = bodyNames.Person
            coin?.physicsBody?.isAffectedByGravity = false
            
            scene.rootNode.addChildNode(coin!)
            coin?.runAction(SCNAction.repeatForever(spin))
            fadeIn(node: coin!)
        }
        
    }
    
    func createBox(){
        
        tempBox = SCNNode(geometry: firstBox.geometry)
        fadeIn(node: tempBox)
        let prevBox = scene.rootNode.childNode(withName: "\(boxNum)", recursively: true)
        boxNum += 1
        tempBox.name = "\(boxNum)"
        
        let randNum = arc4random() % 2
        
        switch randNum{
            
        case 0:
            //left
            tempBox.position = SCNVector3Make((prevBox?.position.x)! - firstBox.scale.x, (prevBox?.position.y)!, (prevBox?.position.z)!)
            if firstOne == true {
                firstOne = false
                goingLeft = false
            }
            break
            
        case 1:
            //right
            tempBox.position = SCNVector3Make((prevBox?.position.x)!, (prevBox?.position.y)!, (prevBox?.position.z)!  - firstBox.scale.z)
            if firstOne == true {
                firstOne = false
                goingLeft = true
            }
            break
            
        default:
            
            break
        }
        
        self.scene.rootNode.addChildNode(tempBox)
        creatCoin(box: tempBox)
        
    }
    
    func createScene(){
        
        let scoreDefault = UserDefaults.standard
        if scoreDefault.integer(forKey: "highscore") != 0 {
            
            highscore = scoreDefault.integer(forKey: "highscore")
            //print(highscore)
        }else{
            
            highscore = 0
            
        }
        
        dead = false
        let sceneView = self.view as! SCNView
        sceneView.scene = scene
        sceneView.delegate = self
        //scene.physicsWorld.gravity = SCNVector3Make(0, 0, 0)
        
        firstOne = true
        
        self.view.backgroundColor = UIColor.white
        
        //create person
        let personGeo = SCNSphere(radius: 0.2)
        person = SCNNode(geometry: personGeo)
        let personMaterial = SCNMaterial()
        personMaterial.diffuse.contents = UIColor.red
        personGeo.materials = [personMaterial]
        person.position = SCNVector3Make(0, 1.1, 0)
        
        person.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: person, options: nil))
        person.physicsBody?.categoryBitMask = bodyNames.Person
        person.physicsBody?.collisionBitMask = bodyNames.Coin
        person.physicsBody?.contactTestBitMask = bodyNames.Coin
        person.physicsBody?.isAffectedByGravity = false
        
        scene.rootNode.addChildNode(person)
        
        //create camera
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(20, 20, 20)
        cameraNode.eulerAngles = SCNVector3Make(-45, 45, 0)
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 3
        let constraint = SCNLookAtConstraint(target: person)
        constraint.isGimbalLockEnabled = true
        self.cameraNode.constraints = [constraint]
        scene.rootNode.addChildNode(cameraNode)
        person.addChildNode(cameraNode)
        
        //create box
        prevBoxNum = 0
        boxNum = 0
        let firstBoxGeo = SCNBox(width: 1, height: 1.5, length: 1, chamferRadius: 0)
        firstBox.geometry = firstBoxGeo
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.8, blue: 0.5, alpha: 1.0)
        firstBoxGeo.materials = [boxMaterial]
        firstBox.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(firstBox)
        firstBox.name = "\(boxNum)"
        
        
        for i in 0...6 {
            createBox()
            //print(i)
        }
        
        //create lights
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .directional
        light.eulerAngles = SCNVector3Make(-45, 45, 0)
        scene.rootNode.addChildNode(light)
        //2
        let light2 = SCNNode()
        light2.light = SCNLight()
        light2.light?.type = .directional
        light2.eulerAngles = SCNVector3Make(45, 45, 0)
        scene.rootNode.addChildNode(light2)
        
        
    }
    
    func fadeIn(node: SCNNode){
        node.opacity = 0
        node.runAction(SCNAction.fadeIn(duration: 0.5))
    }
    func fadeOut(node: SCNNode){
        let move = SCNAction.move(to: SCNVector3Make(node.position.x, node.position.y - 2, node.position.z
        ), duration: 0.5)
        
        node.runAction(move)
        node.runAction(SCNAction.fadeOut(duration: 0.5))
    }
    
    func authPlayer(){
        
        let localPlayer = GKLocalPlayer()
        
        localPlayer.authenticateHandler = {
            (viewController, error) in
            
            if viewController != nil {
                self.present(viewController!, animated: true, completion: nil)
            }else{
                print("Logged in")
                
            }
        }
    }
    
    func saveHighscoe(score: Int){
        
        if GKLocalPlayer.localPlayer().isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: "LKZiggyZagLeader")
            scoreReporter.value = Int64(score)
            
            let scoreArray : [GKScore] = [scoreReporter]
            
            GKScore.report(scoreArray, withCompletionHandler: nil)
        }
        
    }
    
    func showLeaderBoard(){
        saveHighscoe(score: highscore)
        let gc = GKGameCenterViewController()
        gc.gameCenterDelegate = self
        self.present(gc, animated: true, completion: nil)
        
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController){
       gameCenterViewController.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    
    
    
    
    
    
    
    
}
