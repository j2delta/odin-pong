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
    ai_reaction_delay: f32, 
    ai_target_y: f32,
    ai_reaction_counter: f32,
    player_score: f32,
    cpu_score: f32,
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

calc_ball_direction :: proc(ball: rl.Rectangle, paddle: rl.Rectangle) -> (rl.Vector2, bool) {
    if rl.CheckCollisionRecs(ball, paddle){
        paddle_center:= rl.Vector2{paddle.x + paddle.width/2, paddle.y + paddle.height/2}
        ball_center:= rl.Vector2{ball.x + ball.width/2, ball.y + ball.height/2}
        ball_direction:= linalg.normalize0(ball_center - paddle_center)

        return ball_direction, true
    }
    
    return {}, false
    // if next_ball.y <= 0 || next_ball.y >= window_size.y - ball.height{
    //     ball_direction.y *= -1
}

main :: proc() {
    game_state:= Game_State{
        window_size = {1280, 720},
        paddle = {width = 30, height = 80},
        paddle_speed = 10,
        ai_paddle = {width = 30, height = 80},
        ai_paddle_speed = 10,
        ai_reaction_delay = 0.1,
        ball = {width = 30, height = 30},
        ball_speed = 10,
        cpu_score = 0,
        player_score = 0,
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
         
        //AI paddle movement
        ai_reaction_counter += rl.GetFrameTime()

        if ai_reaction_counter >= ai_reaction_delay{
            ai_reaction_counter = 0

            if ball_direction.x < 0{
                diff_y := ball.y + ball.height/2 - ai_paddle.y + ai_paddle.height/2

                ai_target_y = diff_y + rand.float32_range(-10, 10)
            }
            else{
                ai_target_y = window_size.y/2 - ai_paddle.y + ai_paddle.height/2
            }
        }
        ai_paddle.y += linalg.clamp(ai_target_y, -ai_paddle_speed, ai_paddle_speed) * 0.65
        ai_paddle.y = linalg.clamp(ai_paddle.y, 0, window_size.y - ai_paddle.height)
        
        next_ball:= rl.Rectangle{ball.x + ball_speed * ball_direction.x, ball.y, ball.width, ball.height}
        if next_ball.x >= (window_size.x - ball.width) {
            cpu_score += 1
            reset(&game_state)
        }
        else if next_ball.x <= 0{
            player_score += 1
            reset(&game_state)
        }

        ball_direction = calc_ball_direction(next_ball, paddle) or_else ball_direction
        ball_direction = calc_ball_direction(next_ball, ai_paddle) or_else ball_direction

        if next_ball.y <= 0 || next_ball.y >= window_size.y - ball.height{
            ball_direction.y *= -1
        }

        ball.x += ball_speed * ball_direction.x
        ball.y += ball_speed * ball_direction.y

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.DrawRectangleRec(paddle, rl.WHITE)
        rl.DrawRectangleRec(ai_paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        rl.DrawText(fmt.ctprintf("{}", cpu_score), 12, 12, 32, rl.WHITE)
        rl.DrawText(fmt.ctprintf("{}", player_score), i32(window_size.x) - 30, 12, 32, rl.WHITE)
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}