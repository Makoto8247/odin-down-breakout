package main

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

SCREEN_HEIGHT :: 600
SCREEN_WIDTH :: 300

PLAYER_SPEED :: 200
PLAYER_HEIGHT :: 10
PLAYER_WIDTH :: 60
PLAYER_POSY :: 450

BALL_SPEED :: 300
BALL_R :: 10

BLOCK_HEIGHT :: 15
BLOCK_WIDTH :: 40
BLOCK_SPEED :: 50
BLOCK_ADD_COUNT :: 60

Edge:: enum {
    TOP,
    RIGHT,
    BOTTOM,
    LEFT
}

normalize_vector :: proc(v: rl.Vector2) -> rl.Vector2 {
    length := math.sqrt_f32(math.pow_f32(v.x, 2) + math.pow_f32(v.y, 2))
    return rl.Vector2{v.x / length, v.y / length} * math.sqrt_f32(2)
}

/*
*Determining the top, bottom, left, or right by calculating the angle formed by the diagonals and comparing that angle
*/
detect_collision_edge :: proc(rec: rl.Rectangle, ballPos: rl.Vector2) -> Edge {
    diagonalAngle := 2 * math.atan(f64(rec.height) / f64(rec.width))

    theta := math.atan2_f64(f64(ballPos.y - (rec.y + rec.height/2)), f64(ballPos.x - (rec.x + rec.width/2)))

    if theta < 0 do theta += math.TAU

    if theta >= 2*math.PI-diagonalAngle || theta < diagonalAngle {
        return .RIGHT
    } else if theta >= diagonalAngle && theta < math.PI-diagonalAngle {
        return .TOP
    } else if theta >= math.PI-diagonalAngle && theta < math.PI+diagonalAngle {
        return .LEFT
    } else {
        return .BOTTOM
    }
}

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Down Breakout")
    rl.SetTargetFPS(60)

    framesCounter := 0

    playerRec := rl.Rectangle{0, PLAYER_POSY, PLAYER_WIDTH, PLAYER_HEIGHT}

    ballPos := rl.Vector2{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}
    ballVec := rl.Vector2{1, 1}

    blocksRec := [dynamic]rl.Rectangle{}
    defer delete(blocksRec)

    deltaTime :f32 = 0

    for !rl.WindowShouldClose() {
        deltaTime = rl.GetFrameTime()

        framesCounter += 1

        if framesCounter < 0 {
            framesCounter = 0
        }

        /*** Player Setting ***/
        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
            playerRec.x += PLAYER_SPEED * deltaTime
        }
        else if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
            playerRec.x -= PLAYER_SPEED * deltaTime
        }

        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) || rl.GetTouchPointCount() > 0 {
            playerRec.x = f32(rl.GetMouseX()) - playerRec.width/2
        }

        if playerRec.x < 0 do playerRec.x = 0
        if playerRec.x > SCREEN_WIDTH - playerRec.width do playerRec.x = SCREEN_WIDTH - playerRec.width

        /*** Ball Setting ***/
        ballPos += ballVec * BALL_SPEED * deltaTime

        if ballPos.x > SCREEN_WIDTH - BALL_R {
            ballPos.x = SCREEN_WIDTH - BALL_R
            ballVec.x *= -1
        }
        else if ballPos.x < BALL_R {
            ballPos.x = BALL_R
            ballVec.x *= -1
        }
        else if ballPos.y > SCREEN_HEIGHT - BALL_R {
            ballPos.y = SCREEN_HEIGHT - BALL_R
            ballVec.y *= -1
        } 
        else if ballPos.y < BALL_R {
            ballPos.y = BALL_R
            ballVec.y *= -1
        }

        if rl.CheckCollisionCircleRec(ballPos, BALL_R, playerRec) && ballVec.y > 0{
            theta := math.atan2_f32(ballPos.y - (playerRec.y+playerRec.height), ballPos.x - (playerRec.x + playerRec.width/2))
            ballVec = {math.cos_f32(theta), math.sign_f32(theta)}
            ballVec = normalize_vector(ballVec)
        }


        /*** Block Setting ***/
        if framesCounter % BLOCK_ADD_COUNT == 0 {
            append(&blocksRec, rl.Rectangle{SCREEN_WIDTH/2, 0, BLOCK_WIDTH, BLOCK_HEIGHT})
        }
        #reverse for &blockRec, index in blocksRec {
            if rl.CheckCollisionCircleRec(ballPos, BALL_R, blockRec) {
                ballPos -= ballVec * BALL_SPEED * deltaTime
                // Block Edge Hit Points
                dx := (blockRec.x + blockRec.width/2) - ballPos.x
                dy := (blockRec.y + blockRec.height/2) - ballPos.y
                absDx := math.abs(dx)
                absDy := math.abs(dy)
                halfWidth := blockRec.width / 2
                halfHeight := blockRec.height / 2

                switch detect_collision_edge(blockRec, ballPos) {
                    case .RIGHT:
                        ballVec.x = math.abs(ballVec.x)
                    case .TOP:
                        ballVec.y = math.abs(ballVec.y)
                    case .LEFT:
                        ballVec.x = -math.abs(ballVec.x)
                    case .BOTTOM:
                        ballVec.y = -math.abs(ballVec.y)
                }
                ordered_remove(&blocksRec, index)
                continue
            }
            blockRec.y += BLOCK_SPEED * deltaTime
            if blockRec.y > SCREEN_HEIGHT {
                ordered_remove(&blocksRec, index)
            }
        }

        /*** Draw ***/
        rl.BeginDrawing()
        rl.ClearBackground({255, 255, 255, 0})


        // Block Draw
        for blockRec in blocksRec {
            rl.DrawRectangleRec(blockRec, rl.GRAY)
        }

        // Player Draw
        rl.DrawRectangleRec(playerRec, rl.BLUE)

        // Ball Draw
        rl.DrawCircleV(ballPos, BALL_R, rl.RED)
        rl.EndDrawing()

    }

    defer rl.CloseWindow()
}
