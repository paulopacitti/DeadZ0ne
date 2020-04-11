shack = require 'shack'

function love.load()
  gameState = 1
  score = 0
  love.window.setTitle("DeadZ0ne!")
  shack:setDimensions(love.graphics.getWidth()/2, love.graphics.getHeight()/2)

  cursor = love.mouse.newCursor('assets/sprites/cursor4.png', 20, 20)

  fonts = {}
  fonts.pixeled = love.graphics.newFont('assets/fonts/Pixeled.ttf', 20)
  fonts.pixelDead = love.graphics.newFont('assets/fonts/pixelDead.ttf', 80)

  sounds = {}
  sounds.music = love.audio.newSource('assets/sounds/always_f0cused.wav', 'static')
  sounds.music:setLooping(true)
  sounds.music:setVolume(0.7)
  sounds.gameOver = love.audio.newSource('assets/sounds/no-scream.wav', 'static')
  sounds.gameOver:setVolume(0.5)
  sounds.swoosh = love.audio.newSource('assets/sounds/swoosh.wav', 'static')
  sounds.swoosh:setVolume(0.75)
  sounds.zombie1 = love.audio.newSource('assets/sounds/zombie-1.wav', 'static')

  sprites = {}
  sprites.background = love.graphics.newImage('assets/sprites/background2.png')
  sprites.bullet = love.graphics.newImage('assets/sprites/football3.png')
  sprites.player = love.graphics.newImage('assets/sprites/player3.png')
  sprites.transparentCover = love.graphics.newImage('assets/sprites/logo-transparent2.png')
  sprites.zombie = love.graphics.newImage('assets/sprites/zombie3.png')

  player = {}
  player.x = love.graphics.getWidth()/2
  player.y = love.graphics.getHeight()/2
  player.ox = sprites.player:getWidth()/2
  player.oy = sprites.player:getHeight()/2
  player.speed = 180

  zombies = {}
  maxTime = 2
  timer = maxTime

  bullets = {}
end


function love.draw()
  shack:apply()
  love.graphics.draw(sprites.background, 0, 0)
  love.mouse.setCursor(cursor)

  if gameState == 1 then
    player.x = love.graphics.getWidth()/2
    player.y = love.graphics.getHeight()/2
    love.graphics.setFont(fonts.pixeled)
    love.graphics.printf('Click anywhere to start the game!', 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")
    love.graphics.draw(sprites.transparentCover, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 0, nil, nil, 325, 250)
  end

  if gameState == 3 then
    love.graphics.setFont(fonts.pixelDead)
    love.graphics.printf('sc0re: ' .. score, 0,  love.graphics.getHeight() - 100, love.graphics.getWidth(), 'center')
    love.graphics.setFont(fonts.pixelDead)
    love.graphics.printf('Game 0ver!', 0, 50, love.graphics.getWidth(), "center")
    love.graphics.setFont(fonts.pixeled)
    love.graphics.printf('Click again to restart the game!', 0, 120, love.graphics.getWidth(), "center")
  end

  if gameState == 2 then
    sounds.music:play()
    love.graphics.setFont(fonts.pixelDead)
    love.graphics.printf('sc0re: ' .. score, 0,  love.graphics.getHeight() - 100, love.graphics.getWidth(), 'center')
    love.graphics.draw(sprites.player, player.x, player.y, playerOrientationAngle(), nil, nil, player.ox, player.oy)
  end

  for i,z in ipairs(zombies) do
    love.graphics.draw(sprites.zombie, z.x, z.y, zombieOrientationAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
  end

  for i,b in ipairs(bullets) do
    love.graphics.draw(sprites.bullet, b.x, b.y, b.direction, 0.07, 0.07, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
  end
end

function love.update(dt)
  shack:update(dt)

  if gameState == 2 then
    if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
      player.y = player.y + player.speed * dt
    end

    if love.keyboard.isDown("w") and player.y > 0 then
      player.y = player.y - player.speed * dt
    end

    if love.keyboard.isDown("a") and player.x > 0 then
      player.x = player.x - player.speed * dt
    end

    if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
      player.x = player.x + player.speed * dt
    end
  end

  -- zombies moment
  for i,z in ipairs(zombies) do
    z.x = z.x + math.cos(zombieOrientationAngle(z)) * z.speed * dt
    z.y = z.y + math.sin(zombieOrientationAngle(z)) * z.speed * dt

    -- check if the player died
    if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
      for i,z in ipairs(zombies) do
        zombies[i] = nil
      end
      sounds.gameOver:play()
      shack:setShake(20)
      gameState = 3
    end
  end

  -- bullet movement
  for i,b in ipairs(bullets) do
    b.x = b.x + math.cos(b.direction) * b.speed * dt
    b.y = b.y + math.sin(b.direction) * b.speed * dt
  end

  -- remove bullets out of the screen
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
      table.remove(bullets, i)
    end
  end

  -- bullet kill zombie
  for i,z in ipairs(zombies) do
    for j,b in ipairs(bullets) do
      if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
        sounds.zombie1:stop()
        sounds.zombie1:setPitch(1 + 0.5*love.math.random())
        sounds.zombie1:play()
        z.dead = true
        b.killed = true
        score = score + 1
        shack:setShake(20)
      end
    end
  end

  for i = #zombies,1,-1 do
    local z = zombies[i]
    if z.dead == true then
      table.remove(zombies, i)
    end
  end

  for i = #bullets, 1, -1 do
    local b = bullets[i]
    if b.killed == true then
      table.remove(bullets, i)
    end
  end

  if gameState == 2 then
    timer = timer - dt
    if timer <= 0 then
      spawnZombie()
      maxTime = maxTime * 0.95
      timer = maxTime
    end
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "space" then
    spawnZombie()
  end
end

function love.mousepressed( x, y, b, istouch)
  if b == 1 and gameState == 2 then
    sounds.swoosh:stop()
    sounds.swoosh:setPitch(1 - 0.2*love.math.random())
    sounds.swoosh:play()
    spawnBullet()
  end
  if gameState == 1 or gameState == 3 then
    sounds.gameOver:stop()
    gameState = 2
    maxTime = 2
    timer = maxTime
    score = 0
  end
end

function distanceBetween(x1, y1, x2, y2)
  return math.sqrt((y2 - y1)^2 + (x2 - x1)^2)
end

function playerOrientationAngle()
  return math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX()) + math.pi
end

function zombieOrientationAngle(enemy)
  return math.atan2(player.y - enemy.y, player.x - enemy.x)
end

function spawnBullet()
  bullet = {}
  bullet.x = player.x
  bullet.y = player.y
  bullet.speed = 500
  bullet.direction = playerOrientationAngle()
  bullet.killed = false

  table.insert(bullets, bullet)
end

function spawnZombie()
  zombie = {}
  zombie.x = 0
  zombie.y = 0
  zombie.speed = 140
  zombie.dead = false

  local side = math.random(1, 4)
  if side == 1 then
    zombie.x = -30
    zombie.y = math.random(0, love.graphics.getHeight())
  elseif side == 2 then
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = -30
  elseif side == 3 then
    zombie.x = love.graphics.getWidth() + 30
    zombie.y = math.random(0, love.graphics.getHeight())
  else
    zombie.x = math.random(0, love.graphics.getWidth())
    zombie.y = love.graphics.getHeight() + 30
  end

  table.insert(zombies, zombie)
end
