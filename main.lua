--import libraries
push = require "push"
Class = require "class"

require "Ball"
require "Paddle"

--constants
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200
BALL_BOUNCE_FACTOR = 1.03

--sounds
audio = {
    ["paddle"] = love.audio.newSource("audio/paddle.wav", "static"),
    ["wall"] = love.audio.newSource("audio/wall.wav", "static"),
    ["score"] = love.audio.newSource("audio/score.wav", "static"),
    ["win"] = love.audio.newSource("audio/win.wav", "static")
}

--screen setup
screenSettings = {
    fullscreen = false,
    resizable = true,
    vsync = true
}

--load game
function love.load()
    --retro filters
    love.graphics.setDefaultFilter("nearest", "nearest")

    --set title
    love.window.setTitle("Pong")

    --load default fonts
    smallFont = love.graphics.newFont("font.ttf", 8)
    scoreFont = love.graphics.newFont("font.ttf", 32)

    --seed math random
    math.randomseed(os.time())

    --init window with virtual params
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, screenSettings)

    --init variables
    --scores
    p1Score = 0
    p2Score = 0

    --player start pos
    p1 = Paddle(10, 30, 5, 20)
    p2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    --ball start pos
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    --ball start velocity
    --ballDX = math.random(2) == 1 and 100 or -100
    --ballDY = math.random(-50, 50)

    gameState = "start"
    titleMessage =
        "PONG\nPlayer 1 controls: W, S\nPlayer 2 controls: Up, Down\nPress Enter to Start,\nF for fullscreen, and Esc to quit"
end

--resize function
function love.resize(w, h)
    push:resize(w, h)
end

--update game screen
function love.update(dt)
    --player1 controls
    if love.keyboard.isDown("w") then
        p1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown("s") then
        p1.dy = PADDLE_SPEED
    else
        p1.dy = 0
    end

    --player2 controls
    if love.keyboard.isDown("up") then
        p2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown("down") then
        p2.dy = PADDLE_SPEED
    else
        p2.dy = 0
    end

    --different states
    if gameState == "play" then
        --paddle collision
        if ball:collides(p1) then
            ball.dx = -ball.dx * BALL_BOUNCE_FACTOR
            ball.x = p1.x + 5
            audio.paddle:play()
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball:collides(p2) then
            ball.dx = -ball.dx * BALL_BOUNCE_FACTOR
            ball.x = p2.x - 4
            audio.paddle:play()
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        --screen edge collision
        if ball.y <= 0 then
            audio["wall"]:play()
            ball.y = 0
            ball.dy = -ball.dy
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            audio["wall"]:play()
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
        end

        --scoring
        if ball.x < 0 then
            audio.score:play()
            servingPlayer = 1
            p2Score = p2Score + 1
            ball:reset()
            if p2Score == 10 then
                audio.win:play()
                gameState = "win"
                winPlayer = 2
                titleMessage = "Player " .. tostring(winPlayer) .. " wins!\n Press enter to play again!"
            else
                gameState = "serve"
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            audio.score:play()
            servingPlayer = 2
            p1Score = p1Score + 1
            ball:reset()
            if p1Score == 10 then
                audio.win:play()
                gameState = "win"
                winPlayer = 1
                titleMessage = "Player " .. tostring(winPlayer) .. " wins!\n Press enter to play again!"
            else
                gameState = "serve"
            end
        end
        ball:update(dt)
    elseif gameState == "serve" then
        titleMessage = "Player " .. tostring(servingPlayer) .. " serves"

        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    end

    p1:update(dt)
    p2:update(dt)
end

--draw elements onto game screen
function love.draw()
    --render at virtual res
    push:apply("start")

    --actual thing to draw
    love.graphics.setFont(smallFont)
    love.graphics.printf(titleMessage, 0, 10, VIRTUAL_WIDTH, "center")

    --p1 (left) paddle
    p1:render()

    --p2 (right) paddle
    p2:render()

    --ball
    ball:render()

    --draw scores
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(p1Score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(p2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)

    --show fps
    displayFPS()

    --end rendering in virtual res
    push:apply("end")
end

--exit game if escape pressed
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f" then
        if screenSettings.fullscreen == true then
            screenSettings.fullscreen = false
            push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, screenSettings)
        else
            screenSettings.fullscreen = true
            push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, screenSettings)
        end
    elseif key == "enter" or key == "return" then
        if gameState == "start" then
            gameState = "serve"
            servingPlayer = math.random(2)
            titleMessage = "Player " .. tostring(servingPlayer) .. "'s serve"
        elseif gameState == "serve" then
            gameState = "play"
            titleMessage = "Play!"
        elseif gameState == "win" then
            gameState = "serve"
            if winPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
            p1Score = 0
            p2Score = 0
            titleMessage = "Player " .. tostring(servingPlayer) .. "'s serve"
        end
    end
end

--render current fps
function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
end
