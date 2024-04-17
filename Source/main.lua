import "CoreLibs/math"
import "CoreLibs/graphics"
import "pulp-audio"


local audio = pulp.audio
local gfx = playdate.graphics

local kbottomMargin = 234
local ktopMargin= 22
local kleftMargin= 6
local krightMargin = 394

local brickList = {}

local kNumCols = 5
local kNumBricksPerCol = 7

local lives = 3
local level = 1
local score = 0
local ballInPlay = false
local playing = true
local bricksRemaining = 0

local bigPaddleImage = gfx.image.new("SystemAssets/Paddle")
local smallPaddleImage = gfx.image.new("SystemAssets/Paddle2")

local kbigPaddleSize = 48
local ksmallPaddleSize = 36
local paddleSize = kbigPaddleSize

local speedMultiplier = 1

-- load sounds
pulp.audio.init("SystemAssets/Audio/pulp-songs.json","SystemAssets/Audio/pulp-sounds.json")

-- create bricks
local brickTiles, err = gfx.imagetable.new("SystemAssets/Bricks")
if brickTiles == nil then
    print("image not loaded.")
    print(err)
end
for row = 0,kNumBricksPerCol-1
do
   for col= 1,kNumCols
   do
       sp = gfx.sprite.new(brickTiles:getImage(col))
       brickList[col+kNumCols*row] = sp
       sp:moveTo(50+16*col+8,16+32*row+16 )
       sp:setCollideRect(0, 0, sp:getSize())
       sp:setGroups({1})
       sp:setTag(col)
       sp:setCollidesWithGroups({3})
       sp:add()
       print(row,col)
   end 
end
bricksRemaining = #brickList

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
    ballSprite:moveBy(ballVelocity[1]*deltaT*speedMultiplier*(0.9+level*0.1), ballVelocity[2]*deltaT*speedMultiplier*(0.9+level*0.1))
    if ballSprite.x > krightMargin then
        -- ballVelocity[1] = -1*math.abs(ballVelocity[1])
        -- ballSprite.x = 2 * krightMargin - ballSprite.x
        ballSprite:remove()
        ballInPlay = false
        audio.playSound("miss")
        lives -= 1
        if lives == 0 then
           playing = false
        end
        return
    end
    if ballSprite.y > kbottomMargin then
        ballVelocity[2] = -1*math.abs(ballVelocity[2])
        ballSprite.y = 2 * kbottomMargin - ballSprite.y
        audio.playSound("wall")
    end
    if ballSprite.x < kleftMargin then
        ballVelocity[1] = math.abs(ballVelocity[1])
        ballSprite.x = 2 * kleftMargin - ballSprite.x
        audio.playSound("wall")
    end
    if ballSprite.y < ktopMargin then
        ballVelocity[2] = math.abs(ballVelocity[2])
        ballSprite.y = 2 * ktopMargin - ballSprite.y
        audio.playSound("wall")
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
    if not playing then
       return
    end
    if ballInPlay then
        return
    end
    print("launching ball")
    speedMultiplier = 1
    paddleSprite:setImage(bigPaddleImage)
    paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
    ballSprite:add()
    ballSprite:moveTo(160, math.random(20, 220))
    ballVelocity[1] = 125
    ballVelocity[2] = math.random(-150,150)

    ballInPlay = true
end

function playdate.AButtonUp()
   print("A pressed")
   if not playing then
     resetGame()
     playing = true 
   end
end

function detectBallPaddleCollision()
   local collisionList = paddleSprite:overlappingSprites()
   if #collisionList == 1 then
       if ballVelocity[1] > 0 then
           ballVelocity[1] = -ballVelocity[1]
           ballSprite.x = 2 * (paddleSprite.x - 6) - ballSprite.x
           vertical_difference = ballSprite.y - paddleSprite.y
           ballVelocity[2] += vertical_difference * 2 * speedMultiplier
           audio.playSound("paddle")
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
            if tag > 1 then
               obj:setCollisionsEnabled(false)
               obj:remove()
               bricksRemaining -= 1
               print("Bricks remaining"..bricksRemaining)
            end
            if tag == 5 then
               paddleSprite:setImage(bigPaddleImage)
               paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
               paddleSize = kbigPaddleSize
               score+=1
            end
            if tag == 4 then
               speedMultiplier = 1
               score+=2
            end
            if tag == 3 then
               paddleSprite:setImage(smallPaddleImage)
               paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
               paddleSize = ksmallPaddleSize
               score+=3
            end
            if tag == 2 then
               speedMultiplier = 2
               score+=4
            end
            if tag == 1 then
               obj:setTag(6)
               obj:setImage(brickTiles:getImage(6))
               score+=5
            end
            if tag == 6 then
               score+=6
            end
            
            if hitcount == 0 then
                if (ballVelocity[1] < 0 and ballSprite.x > obj.x) or (ballVelocity[1] > 0 and ballSprite.x < obj. x) then
                    ballVelocity[1] = -ballVelocity[1]
                else
                    ballVelocity[2] = -ballVelocity[2]
                end
                audio.playSound("brick")
            end
            hitcount += 1
            if hitcount == 2 then
                break
            end
            
            
        end
    end
end

function resetbricks()
   for i,brk in pairs(brickList) do
      brk:setCollisionsEnabled(true)
      brk:add()
      if brk:getTag() == 6 then
         brk:setTag(1)
         brk:setImage(brickTiles:getImage(1))
      end
   end
   bricksRemaining = #brickList
   level += 1
end

function resetGame()
   resetbricks()
   level = 1
   velocityMultiplier = 1
   lives = 3
   score = 0
   ballIsInPlay = false
   paddleSprite:setImage(bigPaddleImage)
   paddleSprite:setCollideRect(0, 0, paddleSprite:getSize())
end

function checkIsLevelCleared()
   if bricksRemaining < 1 and ballSprite.x > 250 then
      resetbricks()
   end
end

function playdate.update()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, 400, 240)
    -- theBrick:draw(100,100)
    audio.update()
    -- playdate.timer.updateTimers()
    local deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()
    moveBall(deltaTime)
    respondToRotor()
    detectBallPaddleCollision()
    detectBallBrickCollision()
    gfx.sprite.update()
    gfx.drawLine(0,16,400,16)
    for x = 1, lives do
       gfx.drawCircleAtPoint(390-15*x, 7, 5)
    end
    if not playing then
       gfx.drawTextAligned("Game over.",300,90, kTextAlignment.center)
       gfx.drawTextAligned("Press A.",300,110, kTextAlignment.center)
    elseif not ballInPlay then
       gfx.drawTextAligned("Press B.",300,100, kTextAlignment.center)
    end
    checkIsLevelCleared()
    -- playdate.drawFPS(0,0)
    gfx.drawTextAligned("level :"..level, 5, 0, kTextAlignment.left)
    gfx.drawTextAligned(score, 200, 0, kTextAlignment.center)
end
