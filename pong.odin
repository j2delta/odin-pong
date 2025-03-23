package main

import "core:fmt"
import rl "vendor:raylib"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

Game_State::struct{
    window_size: rl.Vector2,
    paddle: rl.Rectangle,
    paddle_speed: f32,
    ai_paddle: rl.Rectangle,
    ai_paddle_speed: f32,
    ball: rl.Rectangle,
    ball_direction: rl.Vector2,
    ball_speed: f32
}

reset :: proc(using gs: ^Game_State){
    angle:= rand.float32_range(-45, 46)
    if rand.int_max(100) % 2 == 0 do angle += 180
    r:= math.to_radians(angle)

    ball_direction.x = math.cos(r)
    ball_direction.y = math.sin(r)

    ball.x = window_size.x/2 - ball.width/2
    ball.y = window_size.y/2 - ball.height/2

    paddle.x = window_size.x - paddle.width
    paddle.y = window_size.y/2 - paddle.height/2

    ai_paddle.x = 0
    ai_paddle.y = window_size.y/2 - paddle.height/2
}

main :: proc() {
    game_state:= Game_State{
        window_size = {1280, 720},
        paddle = {width = 30, height = 80},
        paddle_speed = 10,
        ai_paddle = {width = 30, height = 80},
        ai_paddle_speed = 10,
        ball = {width = 30, height = 30},
        ball_speed = 10,
    }
    reset(&game_state) 
    using game_state

    rl.InitWindow(i32(window_size.x), i32(window_size.y), "Pong")
    rl.SetTargetFPS(60) 

    for !rl.WindowShouldClose(){
        if rl.IsKeyDown(.W){
            paddle.y -= paddle_speed
        }
        if rl.IsKeyDown(.S){
            paddle.y += paddle_speed 
        }
        paddle.y = linalg.clamp(paddle.y, 0, window_size.y - paddle.height)

        ai_paddle.y = ball.y

        ai_paddle.y = linalg.clamp(ai_paddle.y, 0, window_size.y - ai_paddle.height)

        
        next_ball:= rl.Rectangle{ball.x + ball_speed * ball_direction.x, ball.y, ball.width, ball.height}
        if next_ball.x >= (window_size.x - ball.width) || next_ball.x <= 0{
            reset(&game_state)
        }
        else if rl.CheckCollisionRecs(next_ball, paddle){
            paddle_center:= rl.Vector2{paddle.x + paddle.width/2, paddle.y + paddle.height/2}
            ball_center:= rl.Vector2{ball.x + ball.width/2, ball.y + ball.height/2}
            ball_direction = linalg.normalize0(ball_center - paddle_center)
        }
        else if rl.CheckCollisionRecs(next_ball, ai_paddle){
            ai_paddle_center:= rl.Vector2{ai_paddle.x + ai_paddle.width/2, ai_paddle.y + ai_paddle.height/2}
            ball_center:= rl.Vector2{ball.x + ball.width/2, ball.y + ball.height/2}
            ball_direction = linalg.normalize0(ball_center - ai_paddle_center)
        }
        else if next_ball.y <= 0 || next_ball.y >= window_size.y - ball.height{
            ball_direction.y *= -1
        }

        ball.x += ball_speed * ball_direction.x
        ball.y += ball_speed * ball_direction.y

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawRectangleRec(paddle, rl.WHITE)
        rl.DrawRectangleRec(ai_paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        rl.EndDrawing()
    }
}