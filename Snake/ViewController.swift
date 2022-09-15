//
//  ViewController.swift
//  Snake
//
//  Created by Max Kalganov on 9/6/22.
//

import UIKit

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

class ViewController: UIViewController {
    
    var fieldBackground: UIImage!
    var fieldSize: CGFloat!
    var cellSize: CGFloat!
    var allCells: Set<Point>!
    
    var snakeHeadImage: UIImage!
    var snakeBodyImage: UIImage!
    var snakeTailImage: UIImage!
    var snakeBodyTurningImage: UIImage!
    var snakePartTypeToImage: [SnakePartType: UIImage]!
    var snakeMovingDirToRadians: [MovingDirection: Float]!
    var snakePositions: Set<Point>!
    var growSnake: Bool = false
    var snakeBaseTurningRotationAngle: [MovingDirection: Double]!
    var snakeAdditionToTurningRotationAngle: [MovingDirection: Double]!
    
    var snake: SnakePart!
    
    var food: Set<Point>!
    var snakeFoodImage: UIImage!
    let foodTickInterval: Int = 4
    var currentFoodTick: Int = 0 
    
    var isGameRunning: Bool = false
    var isTapped: Bool = false
    let sleepInterval = 0.5
    
    @IBOutlet weak var gameOverStack: UIStackView!
    @IBOutlet weak var gameField: UIImageView!
    
    func initImages(){
        snakeHeadImage = UIImage(named: "snake_head_right")
        snakeBodyImage = UIImage(named: "snake_body_right")
        snakeTailImage = UIImage(named: "snake_tail_right")
        snakeBodyTurningImage = UIImage(named: "snake_body_turning")
        snakeFoodImage = UIImage(named: "snake_food")
        
        assert(snakeHeadImage != nil
               && snakeBodyImage != nil
               && snakeTailImage != nil
               && snakeBodyTurningImage != nil
               && snakeFoodImage != nil, "Snake images not found")
    }
    
    func getMinFieldSize() -> Int{
        let minSize: Int = Int(min(
            gameField.frame.size.width,
            gameField.frame.size.height
        ))
        return minSize
    }
    
    func calcNumCellRepeated(_ cellSize: Int, _ imageSize: Int) -> Int{
        return imageSize / cellSize
    }
    
    func getFieldBackground(_ numCellRepeated: Int, _ cell: UIImage) -> UIImage? {
        
        // Make the height tall enough to stack the images on top of each other.
        let size = CGSize(width: cellSize * CGFloat(numCellRepeated), height: cellSize * CGFloat(numCellRepeated))
        UIGraphicsBeginImageContext(size)
        
        for i in 0...(numCellRepeated-1) {
            for j in 0...(numCellRepeated-1) {
                let cellRect = CGRect(
                  x: CGFloat(i) * cellSize,
                  y: CGFloat(j) * cellSize,
                  width: cellSize,
                  height: cellSize
                )
                cell.draw(in: cellRect)
            }

        }

        let fieldBackground = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return fieldBackground
        
    }
    
    func initAllFieldPoints(_ numCellRepeated: Int){
        allCells = Set([])
        for i in 0..<numCellRepeated{
            for j in 0..<numCellRepeated{
                allCells.insert(Point(x: CGFloat(i), y: CGFloat(j)))
            }
        }
    }
    
    func initField(){
        let singleSquare: UIImage? = UIImage(named: "snake_field_square")
        assert(singleSquare != nil && singleSquare!.size.height == singleSquare!.size.width, "Single cell image not found")
        
        let fieldMinSize: Int = getMinFieldSize()
        cellSize = singleSquare!.size.width
        let numCellRepeated: Int = calcNumCellRepeated(Int(cellSize), fieldMinSize)
        
        assert(numCellRepeated > 2, "Incorrect number of cells calculated")
        
        fieldBackground = getFieldBackground(numCellRepeated, singleSquare!)
        fieldSize = CGFloat(numCellRepeated)
        
        initAllFieldPoints(numCellRepeated)
    }
    
    func initSnake(){
        let snakeTail: SnakePart = SnakePart(
            snakePartType: SnakePartType.TAIL,
            positionOnTheField: [(fieldSize/2).rounded(.down), (fieldSize/2).rounded(.down)],
            movingDirection: MovingDirection.RIGHT,
            nextSnakePart: nil
        )
        snake = SnakePart(
            snakePartType: SnakePartType.HEAD,
            positionOnTheField: [(fieldSize/2).rounded(.down) + 1, (fieldSize/2).rounded(.down)],
            movingDirection: MovingDirection.RIGHT,
            nextSnakePart: snakeTail
        )
        snakePositions = Set([
            Point(x: snakeTail.relativePosition[0], y: snakeTail.relativePosition[1]),
            Point(x: snake.relativePosition[0], y: snake.relativePosition[1])
        ])
    }
    
    func genFood() -> Point?{
        let notTakenCells: Set<Point> = allCells.subtracting(snakePositions.union(food))
        return notTakenCells.randomElement()
    }
    
    
    func initFood(){
        food = Set([])
    }
    
    func getSnakePartImage(_ snakePart: SnakePart) -> UIImage?{
        var snakePartImage: UIImage?
        
        if snakePart.nextSnakePart != nil
            && snakePart.movingDirection != snakePart.nextSnakePart!.movingDirection
            && snakePart.snakePartType == .BODY{
            
            snakePartImage = snakeBodyTurningImage
            
            let baseRotationAngle: Double = snakeBaseTurningRotationAngle[snakePart.nextSnakePart!.movingDirection!]!
            let additionToRotationAngle: Double = snakeAdditionToTurningRotationAngle[snakePart.movingDirection!]!
            let baseSign: Double = ((1.5 - baseRotationAngle) < 0 ? -1 : 1)
            let baseRotAnglRadians: Float = Float((baseRotationAngle + 1/2) * .pi/2)
            let additRotAnglRadians: Float = Float(.pi/4 * additionToRotationAngle * baseSign)
            let radiansToRotate = baseRotAnglRadians + additRotAnglRadians
            snakePartImage = snakePartImage!.rotate(radians: radiansToRotate)
            
        }else{
            snakePartImage = snakePartTypeToImage[snakePart.snakePartType!]
            guard snakePartImage != nil else{
                return nil
            }            
            snakePartImage = snakePartImage!.rotate(radians: snakeMovingDirToRadians[snakePart.movingDirection!]!)
        }
        
        return snakePartImage
    }
    
    func drawGameField(){
        let size = CGSize(width: fieldBackground.size.width, height: fieldBackground.size.height)
        UIGraphicsBeginImageContext(size)
        
        // Drawing background
        let fieldRect = CGRect(
          x: 0,
          y: 0,
          width: fieldBackground.size.width,
          height: fieldBackground.size.height
        )
        fieldBackground.draw(in: fieldRect)

        // Drawing snake
        var currentSnakePart = snake
        while currentSnakePart != nil{
            let cellRect = CGRect(
                x: currentSnakePart!.relativePosition[0] * cellSize,
                y: currentSnakePart!.relativePosition[1] * cellSize,
                width: cellSize,
                height: cellSize
            )
            
            let currentSnakePartImage: UIImage? = getSnakePartImage(currentSnakePart!)
            assert(currentSnakePartImage != nil, "image for snake part not found")
            currentSnakePartImage!.draw(in: cellRect)
            currentSnakePart = currentSnakePart?.nextSnakePart
        }
        
        // Drawing food
        for foodPart in food{
            let foodRect = CGRect(
                x: foodPart.x * cellSize,
                y: foodPart.y * cellSize,
                width: cellSize,
                height: cellSize
            )
            snakeFoodImage!.draw(in: foodRect)
        }
        
        // Gathering everything into one image
        gameField.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func restartGame(){
        isTapped = false
        isGameRunning = false
        growSnake = false
        
        initSnake()
        initFood()
        drawGameField()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameOverStack.isHidden = true
        
        initImages()
        snakePartTypeToImage = [
           .TAIL: snakeTailImage!,
           .BODY: snakeBodyImage!,
           .HEAD: snakeHeadImage!
        ]
        snakeMovingDirToRadians = [
            .RIGHT: 0,
            .DOWN: .pi/2,
            .LEFT: .pi,
            .TOP: -1 * (.pi/2)
        ]
        
        // Constants for rotation angle calculation (of snakeBodyTurningImage)
        snakeBaseTurningRotationAngle = [
            MovingDirection.TOP: 0,
            MovingDirection.DOWN: 2,
            MovingDirection.LEFT: 3,
            MovingDirection.RIGHT: 1
        ]
        snakeAdditionToTurningRotationAngle = [
            MovingDirection.TOP: 1,
            MovingDirection.DOWN: -1,
            MovingDirection.LEFT: 1,
            MovingDirection.RIGHT: -1
        ]
        
        initField()
        
        restartGame()
    }
    
    func updateSnakePositions(_ oldSnakePosition: Point?, _ newSnakePosition: Point){
        if oldSnakePosition != nil{
            snakePositions.remove(oldSnakePosition!)
        }
        snakePositions.insert(newSnakePosition)
    }
    
    func stopGame(){
        gameOverStack.isHidden = false
        restartGame()
    }
    
    func moveSnake() -> (Point?, Point){
        let tailPreviousPosition: [CGFloat]? = snake.move(previousPartDirection: snake.movingDirection!,
                                                          fieldSize: fieldSize,
                                                          growSnake: growSnake)
        let newSnakePosition = snake.getSnakePosition()
        var oldSnakePosition: Point?
        if growSnake{
            growSnake = false
        }
        else{
            oldSnakePosition = getSnakeOldPosition(tailPreviousPosition!)
        }
        
        return (oldSnakePosition, newSnakePosition)
    }
    
    func processFood(){
        if currentFoodTick <= 0{
            let newFood: Point? = genFood()
            if newFood != nil{
                food.insert(newFood!)
            }
            currentFoodTick = foodTickInterval
        }else{
            currentFoodTick -= 1
        }
    }
    
    func hasSnakeFoodIntersection() -> Bool{
        return food.contains(snake.getSnakePosition())
    }
    
    func runGame(){
        var workItem: DispatchWorkItem? = DispatchWorkItem {
            while self.isGameRunning{
                DispatchQueue.main.async {
                    let (oldSnakePosition, newSnakePosition) = self.moveSnake()
                    if hasSnakeIntersection(oldSnakePosition: oldSnakePosition,
                                            newSnakePosition: newSnakePosition,
                                            snakePositions: self.snakePositions){
                        self.stopGame()
                    }else{
                        self.updateSnakePositions(oldSnakePosition, newSnakePosition)
                        if self.hasSnakeFoodIntersection(){
                            self.food.remove(self.snake.getSnakePosition())
                            self.growSnake = true
                        }
                        
                        self.processFood()
                        
                        self.drawGameField()
                        self.isTapped = false
                    }
                }
                Thread.sleep(forTimeInterval: self.sleepInterval)
            }
        }
            
        //Start the work item
        if(workItem != nil) {
            DispatchQueue.global().async(execute: workItem!)
        }
    }
    
    func processTapping(currentDir: MovingDirection, oppositeDir: MovingDirection){
        if isTapped == false{
            isTapped = true
            if gameOverStack.isHidden == false{
                gameOverStack.isHidden = true
            }
            
            if snake.movingDirection != oppositeDir{
                snake.movingDirection = currentDir
            }
            
            if isGameRunning != true {
                isGameRunning = true
                runGame()
            }
        }
    }
    
    @IBAction func topMoveTapped(_ sender: Any) {
        processTapping(currentDir: .TOP, oppositeDir: .DOWN)
    }
    
    @IBAction func leftMoveTapped(_ sender: Any) {
        processTapping(currentDir: .LEFT, oppositeDir: .RIGHT)
    }
    
    @IBAction func rightMoveTapped(_ sender: Any) {
        processTapping(currentDir: .RIGHT, oppositeDir: .LEFT)
    }
    
    @IBAction func downMoveTapped(_ sender: Any) {
        processTapping(currentDir: .DOWN, oppositeDir: .TOP)
    }
    
}

