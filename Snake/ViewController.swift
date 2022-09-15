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
    
    var snakeHeadImage: UIImage!
    var snakeBodyImage: UIImage!
    var snakeTailImage: UIImage!
    var snakePositions: Set<Point>!
    
    var snake: SnakePart!
    
    var isGameRunning: Bool = false
    var isTapped: Bool = false
    let sleepInterval = 0.7
    
    @IBOutlet weak var gameOverStack: UIStackView!
    @IBOutlet weak var gameField: UIImageView!
    
    func initImages(){
        snakeHeadImage = UIImage(named: "snake_head_right")
        snakeBodyImage = UIImage(named: "snake_body_right")
        snakeTailImage = UIImage(named: "snake_tail_right")
        assert(snakeHeadImage != nil && snakeBodyImage != nil && snakeTailImage != nil, "Snake parts images not found")
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
    
    func initField(){
        let singleSquare: UIImage? = UIImage(named: "snake_field_square")
        assert(singleSquare != nil && singleSquare!.size.height == singleSquare!.size.width, "Singke cell image not found")
        
        let fieldMinSize: Int = getMinFieldSize()
        cellSize = singleSquare!.size.width
        let numCellRepeated: Int = calcNumCellRepeated(Int(cellSize), fieldMinSize)
        
        assert(numCellRepeated > 2, "Incorrect number of cells calculated")
        
        fieldBackground = getFieldBackground(numCellRepeated, singleSquare!)
        fieldSize = CGFloat(numCellRepeated)
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
    
    func restartGame(){
        isTapped = false
        isGameRunning = false
        
        initSnake()
        initFood()
        drawGameField()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        gameOverStack.isHidden = true
        
        initImages()
        initField()
        
        restartGame()
    }
    
    func updateSnakePositions(_ oldSnakePosition: Point, _ newSnakePosition: Point){
        snakePositions.remove(oldSnakePosition)
        snakePositions.insert(newSnakePosition)
    }
    
    func stopGame(){
        gameOverStack.isHidden = false
        restartGame()
    }
    
    func moveSnake() -> (Point, Point){
        let tailPreviousPosition: [CGFloat] = snake.move(previousPartDirection: snake.movingDirection!, fieldSize: fieldSize)
        let oldSnakePosition = getSnakeOldPosition(tailPreviousPosition)
        let newSnakePosition = getSnakeNewPosition(snake: snake)
        
        return (oldSnakePosition, newSnakePosition)
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
                        self.drawGameField()
                        self.isTapped = false
                    }
                    // TODO: init food if needed
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

