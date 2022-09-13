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


struct Point: Hashable{
    let x: CGFloat
    let y: CGFloat
}

enum SnakePartType{
    case HEAD
    case BODY
    case TAIL
}


enum MovingDirection{
    case TOP
    case LEFT
    case RIGHT
    case DOWN
}


class SnakePart {
    var nextSnakePart: SnakePart?
    var snakePartType: SnakePartType?
    var relativePosition: [CGFloat] = []
    var movingDirection: MovingDirection?
    
    init(snakePartType partType: SnakePartType,
         positionOnTheField pos: [CGFloat],
         movingDirection direction: MovingDirection,
         nextSnakePart nextPart: SnakePart? = nil){
        
        snakePartType = partType
        movingDirection = direction
        nextSnakePart = nextPart
        relativePosition = pos
    }
    
    func genNewPosition() -> [CGFloat]{
        var currentPosition = relativePosition
        switch movingDirection{
        case .RIGHT:
            currentPosition[0] += 1
        case .DOWN:
            currentPosition[1] += 1
        case .LEFT:
            currentPosition[0] -= 1
        case .TOP:
            currentPosition[1] -= 1
        case .none:
            break
        }
        return currentPosition
    }
    
    func move(previousPartDirection prevPartDir: MovingDirection) -> [CGFloat]{
        let currentPosition = relativePosition
        let prevDir = movingDirection!
        var tailPosition: [CGFloat] = []
        
        relativePosition = genNewPosition()
        movingDirection = prevPartDir
        if nextSnakePart != nil{
            tailPosition = nextSnakePart!.move(previousPartDirection: prevDir)
        }else{
            tailPosition = currentPosition
        }
        return tailPosition
    }
}


class ViewController: UIViewController {
    
    var fieldBackground: UIImage!
    var fieldSize: Int!
    var cellSize: CGFloat!
    
    var snakeHeadImage: UIImage!
    var snakeBodyImage: UIImage!
    var snakeTailImage: UIImage!
    var snakePositions: Set<Point>!
    
    var snake: SnakePart!
    
    var isGameRunning: Bool = false
    
    @IBOutlet weak var gameField: UIImageView!
    
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
    
    func initField(){
        let singleSquare: UIImage? = UIImage(named: "snake_field_square")
        
        guard
            singleSquare != nil,
            singleSquare!.size.height == singleSquare!.size.width
        else{
            return
        }
        
        let fieldMinSize: Int = getMinFieldSize()
        cellSize = singleSquare!.size.width
        let numCellRepeated: Int = calcNumCellRepeated(Int(cellSize), fieldMinSize)
        
        assert(numCellRepeated > 2, "Incorrect number of cells calculated")
        
        fieldBackground = getFieldBackground(numCellRepeated, singleSquare!)
        fieldSize = numCellRepeated
    }
    
    func initSnake(){
        snakeHeadImage = UIImage(named: "snake_head_right")
        snakeBodyImage = UIImage(named: "snake_body_right")
        snakeTailImage = UIImage(named: "snake_tail_right")
        guard
            snakeHeadImage != nil,
            snakeBodyImage != nil,
            snakeTailImage != nil
        else{
            return
        }
        
        let snakeTail: SnakePart = SnakePart(
            snakePartType: SnakePartType.TAIL,
            positionOnTheField: [CGFloat(fieldSize/2), CGFloat(fieldSize/2)],
            movingDirection: MovingDirection.RIGHT,
            nextSnakePart: nil
        )
        snake = SnakePart(
            snakePartType: SnakePartType.HEAD,
            positionOnTheField: [CGFloat(fieldSize/2 + 1), CGFloat(fieldSize/2)],
            movingDirection: MovingDirection.RIGHT,
            nextSnakePart: snakeTail
        )
        snakePositions = Set([
            Point(x: snakeTail.relativePosition[0], y: snakeTail.relativePosition[1]),
            Point(x: snake.relativePosition[0], y: snake.relativePosition[1])
        ])
    }
    
    func initFood(){
        // TODO: init food
    }
    
    func getSnakePartImage(_ snakePart: SnakePart) -> UIImage?{
        var snakePartImage: UIImage?
        
        switch snakePart.snakePartType{
        case .TAIL:
            snakePartImage = snakeTailImage
        case .BODY:
            snakePartImage = snakeBodyImage
        case .HEAD:
            snakePartImage = snakeHeadImage
        case .none:
            break
        }
        
        guard snakePartImage != nil else{
            return nil
        }
        
        switch snakePart.movingDirection{
        case .RIGHT:
            break
        case .DOWN:
            snakePartImage = snakePartImage!.rotate(radians: .pi/2)
        case .LEFT:
            snakePartImage = snakePartImage!.rotate(radians: .pi)
        case .TOP:
            snakePartImage = snakePartImage!.rotate(radians: -1 * (.pi/2))
        case .none:
            snakePartImage = nil
        }
        
        
        return snakePartImage
    }
    
    func drawGameField(){
        let size = CGSize(width: fieldBackground.size.width, height: fieldBackground.size.height)
        UIGraphicsBeginImageContext(size)
        let fieldRect = CGRect(
          x: 0,
          y: 0,
          width: fieldBackground.size.width,
          height: fieldBackground.size.height
        )
        fieldBackground.draw(in: fieldRect)

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
        
        gameField.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func updateField(){
        let tailPreviousPosition: [CGFloat] = snake.move(previousPartDirection: snake.movingDirection!)
        let tailPrevPositionPoint: Point = Point(x: tailPreviousPosition[0], y: tailPreviousPosition[1])
        snakePositions.remove(tailPrevPositionPoint)
        
        let headPositionPoint: Point = Point(x: snake.relativePosition[0], y: snake.relativePosition[1])
        if snakePositions.contains(headPositionPoint){
            isGameRunning = false
        }
        else{
            snakePositions.insert(headPositionPoint)
        }
        
        drawGameField()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initField()
        initSnake()
        initFood()
        
        drawGameField()
    }
    
    func runGame(){
        var workItem: DispatchWorkItem? = DispatchWorkItem {
            while self.isGameRunning{
                DispatchQueue.main.async { self.updateField() }
                Thread.sleep(forTimeInterval: 1)
            }
        }
            
        //Start the work item
        if(workItem != nil) {
            DispatchQueue.global().async(execute: workItem!)
        }
    }
    
    func processTapping(currentDir: MovingDirection, oppositeDir: MovingDirection){
        if snake.movingDirection != oppositeDir{
            snake.movingDirection = currentDir
        }
        if isGameRunning != true {
            isGameRunning = true
            runGame()
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

