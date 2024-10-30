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

normalize_vector :: proc(v: rl.Vector2) -> rl.Vector2 {
    length := math.sqrt_f32(math.pow_f32(v.x, 2) + math.pow_f32(v.y, 2))
    return rl.Vector2{v.x / length, v.y / length} * math.sqrt_f32(2)
}

/*
*Determining the top, bottom, left, or right by calculating the angle formed by the diagonals and comparing that angle
*  : right
* 1 : top
*  : left
*  : bottom
*/
detect_collision_edge :: proc(rec: rl.Rectangle, ballPos: rl.Vector2) -> i32 {
    // Calculate the length of the diagonal
    diagonal := math.sqrt_f32(math.pow_f32(rec.width, 2) + math.pow_f32(rec.height, 2))

    // Calculate the angle using the cosine rule
    cosAngle := math.acos_f32((math.pow_f32(rec.width, 2) + math.pow_f32(diagonal, 2) - math.pow_f32(rec.height, 2)) / (2 * rec.width * diagonal))

    // Calculate the angle using the sine rule
    sinAngle := math.sqrt_f32(4 * math.pow_f32(rec.width * diagonal, 2) - math.pow_f32(math.pow_f32(rec.width, 2) + math.pow_f32(diagonal, 2) - math.pow_f32(rec.height, 2), 2)) / (2 * rec.width * diagonal)

    // Calculate the final angle
    finalAngle := math.acos_f32(math.pow_f32(sinAngle, 2) - math.pow_f32(cosAngle, 2))

    halfRightAngle := (math.PI - finalAngle) / 2

    theta := math.atan2_f32(ballPos.y - (rec.y + rec.height/2), ballPos.x - (rec.x + rec.width/2))
    theta -= math.PI
    if theta < 0  do theta += math.TAU

    toR :f32 = 180 / math.PI
    fmt.printfln("ball.x: %d, ball.y: %d", i32(ballPos.x), i32(ballPos.y))
    fmt.printfln("rec.x: %d, rec.y: %d", i32(rec.x), i32(rec.y))
    fmt.println("ball: ", theta * toR)
    fmt.println("1: ", (math.TAU - halfRightAngle) * toR)
    fmt.println("2: ", (halfRightAngle) * toR)
    fmt.println("3: ", (halfRightAngle + finalAngle) * toR)
    fmt.println("4: ", (finalAngle + 3*halfRightAngle) * toR)
    /*** TODO ***
    * それぞれの角度の条件式を見直す (topは確定)
    */
    // left
    if theta >= math.TAU - halfRightAngle || theta < halfRightAngle do return 3
    // top
    else if theta >= halfRightAngle && theta < halfRightAngle + finalAngle do return 1
    // right
    else if theta >= halfRightAngle + finalAngle && theta < math.TAU - (halfRightAngle + finalAngle) do return 0
    // bottom
    return 1
}

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Down Breakout")
    rl.SetTargetFPS(60)

    playerRec := rl.Rectangle{0, PLAYER_POSY, PLAYER_WIDTH, PLAYER_HEIGHT}

    ballPos := rl.Vector2{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}
    ballVec := rl.Vector2{1, 1}

    blocksRec := [dynamic]rl.Rectangle{{SCREEN_WIDTH/2, SCREEN_HEIGHT/2-50, BLOCK_WIDTH, BLOCK_HEIGHT}}
    defer delete(blocksRec)

    deltaTime :f32 = 0

    for !rl.WindowShouldClose() {
        deltaTime = rl.GetFrameTime()

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

        if ballPos.x > SCREEN_WIDTH - BALL_R/2 {
            ballPos.x = SCREEN_WIDTH - BALL_R/2
            ballVec.x *= -1
        }
        else if ballPos.x < 0 {
            ballPos.x = BALL_R/2
            ballVec.x *= -1
        }
        else if ballPos.y > SCREEN_HEIGHT - BALL_R/2 {
            ballPos.y = SCREEN_HEIGHT - BALL_R/2
            ballVec.y *= -1
        } 
        else if ballPos.y < 0 {
            ballPos.y = BALL_R/2
            ballVec.y *= -1
        }

        if rl.CheckCollisionCircleRec(ballPos, BALL_R, playerRec) && ballVec.y > 0{
            theta := math.atan2_f32(ballPos.y - (playerRec.y+playerRec.height), ballPos.x - (playerRec.x + playerRec.width/2))
            ballVec = {math.cos_f32(theta), math.sign_f32(theta)}
            ballVec = normalize_vector(ballVec)
        }


        /*** Block Setting ***/
        for blockRec, index in blocksRec {
            if rl.CheckCollisionCircleRec(ballPos, BALL_R, blockRec) {
                ballPos -= ballVec * BALL_SPEED * deltaTime
                //ordered_remove(&blocksRec, index)
                // Block Edge Hit Points
                dx := (blockRec.x + blockRec.width/2) - ballPos.x
                dy := (blockRec.y + blockRec.height/2) - ballPos.y
                absDx := math.abs(dx)
                absDy := math.abs(dy)
                halfWidth := blockRec.width / 2
                halfHeight := blockRec.height / 2

                switch detect_collision_edge(blockRec, ballPos) {
                    // left
                    case 0:
                        fmt.println("left")
                        ballVec.x = -abs(ballVec.x)
                    // top
                    case 1:
                        fmt.println("top")
                        ballVec.y = -abs(ballVec.y)
                    // top
                    case 2:
                        fmt.println("top")
                        ballVec.y = -abs(ballVec.y)
                    // right
                    case 3:
                        fmt.println("right")
                        ballVec.x = abs(ballVec.x)
                }
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
