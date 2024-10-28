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

normalize_vector:: proc(v: rl.Vector2) -> rl.Vector2 {
    length := math.sqrt_f32(math.pow_f32(v.x, 2) + math.pow_f32(v.y, 2))
    return rl.Vector2{v.x / length, v.y / length} * math.sqrt_f32(2)
}

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Down Breakout")
    rl.SetTargetFPS(60)

    playerRec := rl.Rectangle{0, PLAYER_POSY, PLAYER_WIDTH, PLAYER_HEIGHT}

    ballPos := rl.Vector2{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}
    ballVec := rl.Vector2{1, 1}

    blocksRec := [dynamic]rl.Rectangle{{SCREEN_WIDTH/2, SCREEN_HEIGHT/2-50, BLOCK_WIDTH, BLOCK_HEIGHT}}
    defer delete(blocksRec)

    for !rl.WindowShouldClose() {

        // Player Setting
        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
            playerRec.x += PLAYER_SPEED * rl.GetFrameTime()
        }
        else if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
            playerRec.x -= PLAYER_SPEED * rl.GetFrameTime()
        }

        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) || rl.GetTouchPointCount() > 0 {
            playerRec.x = f32(rl.GetMouseX()) - playerRec.width/2
        }

        if playerRec.x < 0 do playerRec.x = 0
        if playerRec.x > SCREEN_WIDTH - playerRec.width do playerRec.x = SCREEN_WIDTH - playerRec.width

        // Ball Setting
        ballPos += ballVec * BALL_SPEED * rl.GetFrameTime()

        if ballPos.x > SCREEN_WIDTH || ballPos.x < 0 {
            ballVec.x *= -1
        }
        if ballPos.y > SCREEN_HEIGHT || ballPos.y < 0 {
            ballVec.y *= -1
        }

        if rl.CheckCollisionCircleRec(ballPos, BALL_R, playerRec) && ballVec.y > 0{
            theta := math.atan2_f32(ballPos.y - playerRec.y, ballPos.x - (playerRec.x + playerRec.width/2))
            ballVec = {math.cos_f32(theta), math.sign_f32(theta)}
            ballVec = normalize_vector(ballVec)
        }


        // Block Setting
        for blockRec, index in blocksRec {
            if rl.CheckCollisionCircleRec(ballPos, BALL_R, blockRec) {
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
