import "CoreLibs/math"
local gfx = playdate.graphics



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
       sp:add()
       print(row,col)
   end 
end

paddleSprite = gfx.sprite.new(gfx.image.new("SystemAssets/Paddle"))
paddleSprite:add()
paddleSprite:moveTo(375,120)


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
    respondToRotor()
    gfx.sprite.update()
    playdate.drawFPS(0,0)
end
