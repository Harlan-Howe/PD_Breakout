import "CoreLibs/math"
local gfx = playdate.graphics

local kbottomMargin = 234
local ktopMargin= 22
local kleftMargin= 6
local krightMargin = 394

local kNumRows = 4
local kNumBricksPerCol = 7

local score = 0
local ballInPlay = false

local bigPaddleImage = gfx.image.new("SystemAssets/Paddle")
local smallPaddleImage = gfx.image.new("SystemAssets/Paddle2")

local kbigPaddleSize = 48
local ksmallPaddleSize = 36
local paddleSize = kbigPaddleSize

local speedMultiplier = 1

-- create bricks
local brickTiles, err = gfx.imagetable.new("SystemAssets/Bricks")
if brickTiles == nil then
    print("image not loaded.")
    print(err)
end
for row = 0,kNumBricksPerCol-1
do
   for col= 1,kNumRows
   do
       sp = gfx.sprite.new(brickTiles:getImage(col))
       sp:moveTo(50+16*col+8,16+32*row+16 )
       sp:setCollideRect(0, 0, sp:getSize())
       sp:setGroups({1})
       sp:setTag(col)
       sp:setCollidesWithGroups({3})
       sp:add()
       print(row,col)
   end 
end

-- create paddle
local paddleSprite = gfx.sprite.new(bigPaddleImage)
paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
paddleSprite:setGroups({2})
paddleSprite:setCollidesWithGroups({3})
paddleSprite:add()
paddleSprite:moveTo(375,120)

-- create ball
local ballSprite = gfx.sprite.new(gfx.image.new("SystemAssets/Ball"))
ballSprite:setCollideRect(0,0,ballSprite:getSize())
ballSprite:setGroups({3})
ballSprite:setCollidesWithGroups({1, 2})
-- ballSprite:add()
ballSprite:moveTo(160,30)
local ballVelocity = {125,125}

function moveBall(deltaT)
    if not ballInPlay then
        return
    end
    ballSprite:moveBy(ballVelocity[1]*deltaT*speedMultiplier, ballVelocity[2]*deltaT*speedMultiplier)
    if ballSprite.x > krightMargin then
        -- ballVelocity[1] = -1*math.abs(ballVelocity[1])
        -- ballSprite.x = 2 * krightMargin - ballSprite.x
        ballSprite:remove()
        ballInPlay = false
        print("missed the ball", ballSprite.x)
        return
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
    y = playdate.math.lerp(16+paddleSize/2,240-paddleSize/2, 1-pos/180.0)
    paddleSprite:moveTo(375,y)
end

function playdate.BButtonUp()
    print("B pressed")
    if ballInPlay then
        return
    end
    print("launching ball")
    ballSprite:add()
    ballSprite:moveTo(160, math.random(20, 220))
    ballVelocity[1] = 125
    ballVelocity[2] = math.random(-150,150)
    
    ballInPlay = true
end

function detectBallPaddleCollision()
   local collisionList = paddleSprite:overlappingSprites()
   if #collisionList == 1 then
       if ballVelocity[1] > 0 then
           ballVelocity[1] = -ballVelocity[1]
           ballSprite.x = 2 * (paddleSprite.x - 6) - ballSprite.x
           vertical_difference = ballSprite.y - paddleSprite.y
           ballVelocity[2] += vertical_difference * 2 * speedMultiplier
       end
   end
end

function detectBallBrickCollision()
    local collisionList = ballSprite:overlappingSprites()
    local hitcount = 0
    for i, obj in pairs(collisionList) do
        if obj == paddleSprite then
            print("Paddle - discard")
        else
            local tag = obj:getTag()
            print(tag)
            obj:setCollisionsEnabled(false)
            obj:remove()
            if hitcount == 0 then
                if (ballVelocity[1] < 0 and ballSprite.x > obj.x) or (ballVelocity[1] > 0 and ballSprite.x < obj. x) then
                    ballVelocity[1] = -ballVelocity[1]
                else
                    ballVelocity[2] = -ballVelocity[2]
                end
            end
            hitcount += 1
            if hitcount == 2 then
                break
            end
            
            if tag == 4 then
               paddleSprite:setImage(bigPaddleImage)
               paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
               paddleSize = kbigPaddleSize
            end
            if tag == 3 then
               speedMultiplier = 1
               
            end
            if tag == 2 then
               paddleSprite:setImage(smallPaddleImage)
               paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
               paddleSize = ksmallPaddleSize
            end
            if tag == 1 then
               speedMultiplier = 2
            end
        end
    end
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
    detectBallPaddleCollision()
    detectBallBrickCollision()
    gfx.sprite.update()
    gfx.drawLine(0,16,400,16)
    playdate.drawFPS(0,0)
end
