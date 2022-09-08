//
//  ViewController.swift
//  Snake
//
//  Created by Max Kalganov on 9/6/22.
//

import UIKit

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
}


class ViewController: UIViewController {
    
    var fieldBackground: UIImage!
    var fieldSize: Int!
    var cellSize: CGFloat!
    
    var snakeHeadImage: UIImage!
    var snakeBodyImage: UIImage!
    var snakeTailImage: UIImage!
    
    var snake: SnakePart!
    
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
            snakePartImage = nil
        default:
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initField()
        initSnake()
        initFood()
        
        drawGameField()
    }
    
    
    @IBAction func topMoveTapped(_ sender: Any) {
        gameField.image = snakeHeadImage
        print("Top move tapped!")
    }
    
    @IBAction func leftMoveTapped(_ sender: Any) {
        gameField.image = snakeTailImage
        print("Left move tapped!")
    }
    
    @IBAction func rightMoveTapped(_ sender: Any) {
        gameField.image = snakeBodyImage
        print("Right move tapped!")
    }
    
    @IBAction func downMoveTapped(_ sender: Any) {
        gameField.image = fieldBackground
        print("Down move tapped!")
    }
    
}

