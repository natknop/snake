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
    
    func move(previousPartDirection prevPartDir: MovingDirection, fieldSize: CGFloat) -> [CGFloat]{
        let currentPosition = relativePosition
        let prevDir = movingDirection!
        var tailPosition: [CGFloat] = []
        
        relativePosition = genSnakeNewPosition(previousPosition: relativePosition, movingDirection: movingDirection, fieldSize: fieldSize)
        movingDirection = prevPartDir
        if nextSnakePart != nil{
            tailPosition = nextSnakePart!.move(previousPartDirection: prevDir, fieldSize: fieldSize)
        }else{
            tailPosition = currentPosition
        }
        return tailPosition
    }
}


// Utils

func mod(_ left: CGFloat, _ right: CGFloat) -> CGFloat {
    let modValue = left.truncatingRemainder(dividingBy: right)
    return modValue >= 0 ? modValue : modValue + right
}

func genSnakeNewPosition(previousPosition: [CGFloat], movingDirection: MovingDirection?, fieldSize: CGFloat) -> [CGFloat]{
    
    var currentPosition = previousPosition
    switch movingDirection{
    case .RIGHT:
        currentPosition[0] = mod(currentPosition[0] + 1, fieldSize)
    case .DOWN:
        currentPosition[1] = mod(currentPosition[1] + 1, fieldSize)
    case .LEFT:
        currentPosition[0] = mod(currentPosition[0] - 1, fieldSize)
    case .TOP:
        currentPosition[1] = mod(currentPosition[1] - 1, fieldSize)
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

func hasSnakeIntersection(oldSnakePosition: Point, newSnakePosition: Point, snakePositions: Set<Point>) -> Bool{
    return oldSnakePosition == newSnakePosition || snakePositions.contains(newSnakePosition)
}
