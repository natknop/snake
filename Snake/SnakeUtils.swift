//
//  SnakeUtils.swift
//  Snake
//
//  Created by Max Kalganov on 9/14/22.
//

import Foundation
import UIKit


// Structs, classes, enums

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
    
    func move(previousPartDirection prevPartDir: MovingDirection) -> [CGFloat]{
        let currentPosition = relativePosition
        let prevDir = movingDirection!
        var tailPosition: [CGFloat] = []
        
        relativePosition = genSnakeNewPosition(previousPosition: relativePosition, movingDirection: movingDirection)
        movingDirection = prevPartDir
        if nextSnakePart != nil{
            tailPosition = nextSnakePart!.move(previousPartDirection: prevDir)
        }else{
            tailPosition = currentPosition
        }
        return tailPosition
    }
}


// Utils

func mod(_ left: Int, _ right: Int) -> Int {
   let mod = left % right
   return mod >= 0 ? mod : mod + right
}

func genSnakeNewPosition(previousPosition: [CGFloat], movingDirection: MovingDirection?, fieldSize: CGFloat) -> [CGFloat]{
    
    // TODO: process field Size param
    var currentPosition = previousPosition
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

func getSnakeOldPosition(_ tailPreviousPosition: [CGFloat]) -> Point{
    return Point(x: tailPreviousPosition[0], y: tailPreviousPosition[1])
}

func getSnakeNewPosition(snake: SnakePart) -> Point{
    return Point(x: snake.relativePosition[0], y: snake.relativePosition[1])
}
