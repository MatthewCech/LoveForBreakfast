require("utils/animation");


-- Configure the game here
function love.load()
  -- Globals
  Config = require("config");
  Camera = require("utils/camera");
  Background = require("utils/cameraBackground");
  G = 9.81;

  -- Default settings
  love.graphics.setDefaultFilter("nearest");
  love.window.setMode(Config.width * Config.scale, Config.height * Config.scale);

  -- Initialize
  Scene:Init();
end

function love.draw()
  love.graphics.push();
  love.graphics.setDefaultFilter("nearest");
  love.graphics.scale(Config.scale, Config.scale);

  Background:set();
  Scene:DrawBackground(love.graphics);
  Background.unset();

  Camera:set();
  Scene:Draw(love.graphics);
  Camera:unset();

  love.graphics.pop();
end

function love.update(dt)
  Scene:Update(dt);
end

function love.keypressed(key, scancode, isrepeat)
  Scene:KeyPressed(key, scancode, isrepeat);
end


Scene =
{
  player = 
  {
    position = { x = nil, y = nil },
    animation = {},
    scale = { x = nil, y = nil },
    width = 32,
    height = 32,
    speed = 0,
    forceUp = nil;
    forceUpReset = nil;
    rotation = 0;
    currentAnimation = "";
    onGround = true;
  },

  world = nil,
  objects = nil,
  backgroundImages = nil,
}

function Scene:Init()
  self.player.scale.x = 1;
  self.player.scale.y = 1;
  self.player.speed = 200;
  self.player.forceUpReset = G * 12000;
  self.player.forceUp = self.player.forceUpReset;
  self.rotation = 0;
  self.player.position.x = 0;
  self.player.position.y = 0;
  self.player.animation = {};
  self.player.animation["left"]       = ConstructAnimation(love.graphics.newImage("assets/playerLeft.png"), 32, 32, 0.7);
  self.player.animation["idle"]       = ConstructAnimation(love.graphics.newImage("assets/playerIdle.png"), 32, 32, 2.0);
  self.player.animation["right"]      = ConstructAnimation(love.graphics.newImage("assets/playerRight.png"), 32, 32, 0.5);
  self.player.animation["punchright"] = ConstructAnimation(love.graphics.newImage("assets/playerPunchRight.png"), 32, 32, 1.0);
  self.player.animation["punchleft"]  = ConstructAnimation(love.graphics.newImage("assets/playerPunchLeft.png"), 32, 32, 1.0);
  self.player.animation["jumpright"]  = ConstructAnimation(love.graphics.newImage("assets/playerJumpLeft.png"), 32, 32, 1.0);
  self.player.animation["jumpleft"]   = ConstructAnimation(love.graphics.newImage("assets/playerJumpRight.png"), 32, 32, 1.0);
  self.player.animation["slideleft"]  = ConstructAnimation(love.graphics.newImage("assets/playerSlideLeft.png"), 32, 32, 1.0);
  self.player.animation["slideright"] = ConstructAnimation(love.graphics.newImage("assets/playerSlideRight.png"), 32, 32, 1.0);
  self.player.currentAnimation = "idle";

  -- Background
  love.graphics.setBackgroundColor(27/255, 104/255, 129/255);
  self.backgroundImages = {};
  self.player.onGround = true;
  table.insert(self.backgroundImages, love.graphics.newImage("assets/trees.png"));

  ---------------------------------------------------------------------------------------------------------

  love.physics.setMeter(16); --the height of a meter our worlds will be 16px
  self.world = love.physics.newWorld(0, G*128, true);
  self.world:setCallbacks(BeginContact, EndContact, PreSolve, PostSolve);
  self.objects = {};

  -- Create ground
  self.objects.ground = {};
  self.objects.ground.body = love.physics.newBody(self.world, Config.width / 2, Config.height - 100);
  self.objects.ground.shape = love.physics.newRectangleShape(Config.width, 200);
  self.objects.ground.fixture = love.physics.newFixture(self.objects.ground.body, self.objects.ground.shape);
  self.objects.ground.fixture:setFriction(.8);
  self.objects.ground.fixture:setUserData("ground");

  --let's create a player
  self.objects.player = {}
  self.objects.player.body = love.physics.newBody(self.world, self.player.position.x + self.player.width / 2, self.player.position.y + self.player.height / 2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  self.objects.player.shape = love.physics.newRectangleShape(self.player.width, self.player.height); --the player's shape has a radius of 20
  self.objects.player.fixture = love.physics.newFixture(self.objects.player.body, self.objects.player.shape, 1) -- Attach fixture to body and give it a density of 1.
  self.objects.player.fixture:setRestitution(0) --let the player bounce
  self.objects.player.fixture:setFriction(.8);
  self.objects.player.fixture:setUserData("player");
end

function Scene:DrawBackground(Graphics)
  Graphics.setColor(53/255, 121/255, 144/255);

  for _, i in pairs(self.backgroundImages) do
    Graphics.draw(i, 0, 0);
  end

  Graphics.setColor(1, 1, 1);
end

function Scene:Draw(Graphics)
  --love.graphics.setColor(27/255, 104/255, 129/255); -- set the drawing color to green for the ground
  --love.graphics.setColor(53/255, 121/255, 144/255); -- set the drawing color to green for the ground
  Graphics.setColor(82/255, 147/255, 168/255); -- set the drawing color to green for the ground
  Graphics.polygon("fill", self.objects.ground.body:getWorldPoints(self.objects.ground.shape:getPoints())); 
  Graphics.setColor(1, 1, 1);
  Graphics.draw(
    self.player.animation[self.player.currentAnimation].spriteSheet,
    self.player.animation[self.player.currentAnimation].GetCurrentFrame(), 
    self.player.position.x, self.player.position.y, 
    math.rad(self.player.rotation), 
    self.player.scale.x, self.player.scale.y);
end


function Scene:Update(dt)
  if self.player.onGround == true then
    self.player.forceUp = self.player.forceUpReset;
  end

  self:UpdatePlayerInput(dt);
  self.world:update(dt);
  self.player.position.x = self.objects.player.body:getX();
  self.player.position.y = self.objects.player.body:getY();
  self.player.animation[self.player.currentAnimation].Update(dt);

  -- Camera stuff
  Camera:move(0, -0.08);
  Background:move(0, -0.02);
end

function Scene:KeyPressed(key, scancode, isrepeat)
  local x, y = self.objects.player.body:getLinearVelocity();
  local _punchForce = G * 18000;  

  if key == "w" then
    if x > 0 then
      self.player.currentAnimation = "jumpright";
    else
      self.player.currentAnimation = "jumpleft";
    end

    if self.player.onGround == true then
      self.objects.player.body:applyForce(x, G * -25000);
      self.player.onGround = false;
    end
  end
  if key == "s" or key == "down" then
    self.objects.player.body:setLinearVelocity(0, 500);
  end
  if key == "right" then
    self.player.currentAnimation = "punchright";
    self.objects.player.body:applyForce(_punchForce, 0);
  end 
  if key == "left" then
    self.player.currentAnimation = "punchleft";
    self.objects.player.body:applyForce(-_punchForce, 0);
  end 
  if key == "up" then
    self.objects.player.body:applyForce(0 , -self.player.forceUp);
    self.player.forceUp = self.player.forceUp / 2;
    self.player.onGround = false;
  end
end

function Scene:UpdatePlayerInput(dt)
  local x, y = self.objects.player.body:getLinearVelocity();

  if not love.keyboard.isDown("right") and not love.keyboard.isDown("left") then
    if love.keyboard.isDown("d") then
      self.player.currentAnimation = "right";
      self.objects.player.body:setLinearVelocity(self.player.speed, y);
    elseif love.keyboard.isDown("a") then
      self.player.currentAnimation = "left";
      self.objects.player.body:setLinearVelocity(-self.player.speed, y);
    else 
      self.player.currentAnimation = "idle";
    end
  end
end

function BeginContact(a, b, coll)
  local _x, _y = coll:getNormal();
  local _aName = a:getUserData();
  local _bName = b:getUserData();
  if _aName == "player" and _bName == "ground" or _aName == "ground" and _bName == "player" then
    Scene.player.onGround = true;
  end
  --print("\n"..a:getUserData().." colliding with "..b:getUserData().." with a vector normal of: "..x..", "..y);
end
 
function EndContact(a, b, coll)
  persisting = 0;
  --print(text.."\n"..a:getUserData().." uncolliding with "..b:getUserData());
end
 
function PreSolve(a, b, coll)
  --[[
    if persisting == 0 then    -- only say when they first start touching
        text = text.."\n"..a:getUserData().." touching "..b:getUserData()
    elseif persisting < 20 then    -- then just start counting
        text = text.." "..persisting
    end
    persisting = persisting + 1    -- keep track of how many updates they've been touching for
    ]]--
end
 
function PostSolve(a, b, coll, normalimpulse, tangentimpulse)
end