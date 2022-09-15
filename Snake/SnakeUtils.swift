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
    
    func move(previousPartDirection prevPartDir: MovingDirection, fieldSize: CGFloat, growSnake: Bool) -> [CGFloat]?{
        let prevPosition = relativePosition
        let prevDir = movingDirection!
        var tailPosition: [CGFloat]?
        
        relativePosition = genSnakeNewPosition(previousPosition: relativePosition, movingDirection: movingDirection, fieldSize: fieldSize)
        movingDirection = prevPartDir
        
        if growSnake == false{
            if nextSnakePart != nil{
                tailPosition = nextSnakePart!.move(previousPartDirection: prevDir, fieldSize: fieldSize, growSnake: false)
            }else{
                tailPosition = prevPosition
            }
        }
        else{
            addNewSnakePart(prevSnakePart: self, partType: SnakePartType.BODY, position: prevPosition, direction: prevDir)
        }
        return tailPosition
    }
    
    func getSnakePosition() -> Point{
        return Point(x: relativePosition[0], y: relativePosition[1])
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

func hasSnakeIntersection(oldSnakePosition: Point?, newSnakePosition: Point, snakePositions: Set<Point>) -> Bool{
    return snakePositions.contains(newSnakePosition) && (oldSnakePosition == nil || oldSnakePosition != newSnakePosition)
}

func addNewSnakePart(prevSnakePart: SnakePart, partType: SnakePartType, position: [CGFloat], direction: MovingDirection){
    let newBodySnakePart: SnakePart = SnakePart(
        snakePartType: partType,
        positionOnTheField: position,
        movingDirection: direction,
        nextSnakePart: prevSnakePart.nextSnakePart
    )
    prevSnakePart.nextSnakePart = newBodySnakePart
}
