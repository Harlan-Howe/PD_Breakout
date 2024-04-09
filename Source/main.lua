import "CoreLibs/math"
local gfx = playdate.graphics

local kbottomMargin = 234
local ktopMargin= 22
local kleftMargin= 6
local krightMargin = 394

-- create bricks
local brickTiles, err = gfx.imagetable.new("SystemAssets/Bricks")
if brickTiles == nil then
    print("image not loaded.")
    print(err)
end
for row = 0,6
do
   for col= 1,4
   do
       sp = gfx.sprite.new(brickTiles:getImage(col))
       sp:moveTo(50+16*col+8,16+32*row+16 )
       sp:setGroups({1})
       sp:setCollidesWithGroups({3})
       sp:add()
       print(row,col)
   end 
end

-- create paddle
local paddleSprite = gfx.sprite.new(gfx.image.new("SystemAssets/Paddle"))
paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
paddleSprite:setGroups({2})
paddleSprite:setCollidesWithGroups({3})
paddleSprite:add()
paddleSprite:moveTo(375,120)

-- create ball
local ballSprite = gfx.sprite.new(gfx.image.new("SystemAssets/Ball"))
ballSprite:setCollideRect(0,0,ballSprite:getSize())
ballSprite:setGroups({3})
ballSprite:setCollidesWithGroups({1,2})
ballSprite:add()
ballSprite:moveTo(160,30)
local ballVelocity = {50,50}

function moveBall(deltaT)
    ballSprite:moveBy(ballVelocity[1]*deltaT, ballVelocity[2]*deltaT)
    if ballSprite.x > krightMargin then
        ballVelocity[1] = -1*math.abs(ballVelocity[1])
        ballSprite.x = 2 * krightMargin - ballSprite.x
    end
    if ballSprite.y > kbottomMargin then
        ballVelocity[2] = -1*math.abs(ballVelocity[2])
        ballSprite.y = 2 * kbottomMargin - ballSprite.y
    end
    if ballSprite.x < kleftMargin then
        ballVelocity[1] = math.abs(ballVelocity[1])
        ballSprite.x = 2 * kleftMargin - ballSprite.x
    end
    if ballSprite.y < ktopMargin then
        ballVelocity[2] = math.abs(ballVelocity[2])
        ballSprite.y = 2 * ktopMargin - ballSprite.y
    end
end

function respondToRotor()
    pos = playdate.getCrankPosition()
    pos = math.abs(pos-180)
    y = playdate.math.lerp(16+24,240-24, 1-pos/180.0)
    paddleSprite:moveTo(375,y)
end

function playdate.update()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
    -- theBrick:draw(100,100)
    
    -- playdate.timer.updateTimers()
    local deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()
    moveBall(deltaTime)
    respondToRotor()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
end
