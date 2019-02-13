function love.load()
  gameState = 1
  score = 0

  fonts = {}
  fonts.pixeled = love.graphics.newFont('assets/fonts/Pixeled.ttf', 20)

  sprites = {}
  sprites.player = love.graphics.newImage('assets/sprites/player.png')
  sprites.bullet = love.graphics.newImage('assets/sprites/bullet.png')
  sprites.zombie = love.graphics.newImage('assets/sprites/zombie.png')
  sprites.background = love.graphics.newImage('assets/sprites/background.png')

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
  love.graphics.draw(sprites.background, 0, 0)
  if gameState == 1 then
    love.graphics.setFont(fonts.pixeled)
    love.graphics.printf('"Click anywhere to begin!"', 0, 50, love.graphics.getWidth(), "center")
  end

  love.graphics.printf('score: ' .. score, 0,  love.graphics.getHeight() - 100, love.graphics.getWidth(), 'center')

  love.graphics.draw(sprites.player, player.x, player.y, playerOrientationAngle(), nil, nil, player.ox, player.oy)

  for i,z in ipairs(zombies) do
    love.graphics.draw(sprites.zombie, z.x, z.y, zombieOrientationAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
  end

  for i,b in ipairs(bullets) do
    love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, 0.5, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
  end
end

function love.update(dt)
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
      gameState = 1
      player.x = love.graphics.getWidth()/2
      player.y = love.graphics.getHeight()/2
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
        z.dead = true
        b.killed = true
        score = score + 1
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
    spawnBullet()
  end
  if gameState == 1 then
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
