//
//  GameScene.swift
//  FlappyBird
//
//  Created by naito.hiromu on 2023/05/31.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!    // 追加
    var starNode:SKNode!
    var bird:SKSpriteNode!    // 追加
    
    // 衝突判定カテゴリー ↓追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let starCategory: UInt32 = 1 << 4

    //SE用
    var player:AVAudioPlayer?
    
    
    // スコア用
    var score = 0  // ←追加
    var scoreLabelNode:SKLabelNode!    // ←追加
    var bestScoreLabelNode:SKLabelNode!    // ←追加
    let userDefaults:UserDefaults = UserDefaults.standard    // 追加

    var itemscore = 0  // ←追加
    var itemscoreLabelNode:SKLabelNode!    // ←追加
    var bestItemScoreLabelNode:SKLabelNode!    // ←追加
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)    // ←追加
        physicsWorld.contactDelegate = self // ←追加
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()   // 追加
        scrollNode.addChild(wallNode)   // 追加
        
        // 星用のノード
        starNode = SKNode()   // 追加
        scrollNode.addChild(starNode)   // 追加
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()   // 追加
        setupBird()   // 追加
        setupStar()
        
        // スコア表示ラベルの設定
        setupScoreLabel()   // 追加
    }
    
    func setupScoreLabel() {
        // スコア表示を作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        //アイテムスコア表示を作成
        itemscore = 0
        itemscoreLabelNode = SKLabelNode()
        itemscoreLabelNode.fontColor = UIColor.black
        itemscoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemscoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemscoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemscoreLabelNode.text = "ItemScore:\(itemscore)"
        self.addChild(itemscoreLabelNode)
        
        // ベストスコア表示を作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        // ベストアイテムスコア表示を作成
        let itembestScore = userDefaults.integer(forKey: "ITEMBEST")
        bestItemScoreLabelNode = SKLabelNode()
        bestItemScoreLabelNode.fontColor = UIColor.black
        bestItemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        bestItemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestItemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestItemScoreLabelNode.text = "Best Item Score:\(itembestScore)"
        self.addChild(bestItemScoreLabelNode)
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())   // ←追加

            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory    // ←追加
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false   // ←追加
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // 空の中央位置を基準にして下側の壁の中央位置を取得
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
            under.physicsBody?.isDynamic = false    // ←追加
            
            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // 上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
            upper.physicsBody?.isDynamic = false    // ←追加
            
            // --- ここから ---
            // スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)

            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false

            // 壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            // --- ここまで追加 ---
            
            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        wallNode.run(repeatForeverAnimation)
    }
    // 以下追加
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

        // 物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)    // ←追加
        
        // カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory    // ←追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←追加
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | starCategory   // ←追加

        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false    // ←追加
        
        // アニメーションを設定
        bird.run(flap)

        // スプライトを追加する
        addChild(bird)
    }
    
    func setupStar() {
        let starTexture = SKTexture(imageNamed:"star")
        starTexture.filteringMode = .nearest
        
        let starSprite = SKSpriteNode(texture:starTexture)
        
        starSprite.position = CGPoint(
            x: starTexture.size().width / 2,
            y: starTexture.size().height / 2
        )
        
        starSprite.setScale(0.1)
        
        // 隙間位置の上下の振れ幅を60ptとする
        //let random_y_range: CGFloat = 100
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + starTexture.size().width
        
        // 画面外まで移動するアクションを作成
        let moveStar = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removeStar = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let starAnimation = SKAction.sequence([moveStar, removeStar])
        
        // 鳥の画像サイズを取得
        //let birdSize = SKTexture(imageNamed: "bird_a").size()
        // シーンにスプライトを追加する
        //addChild(starSprite)
        
        // 星を生成するアクションを作成
        let createStarAnimation = SKAction.run({
            // 壁をまとめるノードを作成
            let star = SKNode()
            star.position = CGPoint(x: self.frame.size.width + starTexture.size().width / 2, y: 0)
            star.zPosition = -40 // 雲より手前、地面より奥
            star.setScale(0.1)
            
            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: 1500...8000)
            //let under_wall_y = under_wall_center_y + random_y
            //print(random_y)
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: starTexture)
            under.position = CGPoint(x: 0, y: random_y)
            
            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: starTexture.size())
            under.physicsBody?.categoryBitMask = self.starCategory    // ←追加
            under.physicsBody?.isDynamic = false    // ←追加
            
            // 壁をまとめるノードに下側の壁を追加
            star.addChild(under)
            
            // --- ここから ---
            // スコアカウント用の透明な壁を作成
            /*
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)

            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            */
            // 壁をまとめるノードに透明な壁を追加
            //star.addChild(scoreNode)
            // --- ここまで追加 ---
            
            // 壁をまとめるノードにアニメーションを設定
            star.run(starAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.starNode.addChild(star)
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 4)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createStarAnimation, waitAnimation]))
        
        // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        starNode.run(repeatForeverAnimation)
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコアカウント用の透明な壁と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"    // ←追加
            
            // ベストスコア更新か確認する --- ここから ---
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"    // ←追加
                userDefaults.set(bestScore, forKey: "BEST")
            } // --- ここまで追加---
        }else if(contact.bodyA.categoryBitMask & starCategory) == starCategory || (contact.bodyB.categoryBitMask & starCategory) == starCategory{

            // スコアカウント用の透明な壁と衝突した
            print("ItemScoreUp")
            itemscore += 1
            itemscoreLabelNode.text = "Item Score:\(itemscore)"    // ←追加
            
            if let soundURL = Bundle.main.url(forResource: "free_sound8", withExtension: "mp3"){
                do{
                    player = try AVAudioPlayer(contentsOf: soundURL)
                    player?.play()
                }catch{
                    print("error")
                }
            }
            
            // ベストスコア更新か確認する --- ここから ---
            var itembestScore = userDefaults.integer(forKey: "ITEMBEST")
            if itemscore > itembestScore {
                itembestScore = itemscore
                bestItemScoreLabelNode.text = "Best Item Score:\(itembestScore)"    // ←追加
                userDefaults.set(itembestScore, forKey: "ITEMBEST")
            } // --- ここまで追加---
            starNode.removeAllChildren()
        }else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            scrollNode.speed = 0

            // 衝突後は地面と反発するのみとする(リスタートするまで壁と反発させない)
            bird.physicsBody?.collisionBitMask = groundCategory

            // 鳥が衝突した時の高さを元に、鳥が地面に落ちるまでの秒数(概算)+1を計算
            let duration = bird.position.y / 400.0 + 1.0
            // 指定秒数分、鳥をくるくる回転させる(回転速度は1秒に1周)
            let roll = SKAction.rotate(byAngle: 2.0 * Double.pi * duration, duration: duration)
            bird.run(roll, completion:{
                // 回転が終わったら鳥の動きを止める
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        // スコアを0にする
        score = 0
        scoreLabelNode.text = "Score:\(score)"    // ←追加
        
        itemscore = 0
        itemscoreLabelNode.text = "Item Score:\(itemscore)"

        // 鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        // 全ての壁を取り除く
        wallNode.removeAllChildren()

        starNode.removeAllChildren()
        
        // 鳥の羽ばたきを戻す
        bird.speed = 1

        // スクロールを再開させる
        scrollNode.speed = 1
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 { // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { // --- ここから ---
            restart()
        } // --- ここまで追加 ---
    }
}
