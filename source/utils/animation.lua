--[[
  Creates an animation table. This table has the following fields after construction:

  Fields:
    spritesheet - The image that was split into quads. Passed in originally.
          quads - The information stored for the sections of the split image
       duration - How long the animation lasts, in seconds.
    currentTime - The time in the animation, from 0 to duration.
      spriteNum - The current frame in the animation, from 0 to length of animation.quads

  Functions:
           Update(dt) - Updates the current time and animation time for the animation. Should be
                          called in love.update();
    GetCurrentFrame() - Returns the current quad/fame in the animation     
]]
function ConstructAnimation(sprite_image, sprite_width, sprite_height, duration)
  -- Local variables
  local _animation = {}
  
  -- Create animation
  _animation.spriteSheet = sprite_image;
  _animation.quads = {};
  _animation.duration = duration or 1; -- default to 1 if it wasn't specified.
  _animation.currentTime = 0;
  _animation.spriteNum = 0;

  -- Use quads to split up the image and store it in quads
  for y = 0, sprite_image:getHeight() - sprite_height, sprite_height do
      for x = 0, sprite_image:getWidth() - sprite_width, sprite_width do
          table.insert(_animation.quads, love.graphics.newQuad(x, y, sprite_width, sprite_height, sprite_image:getDimensions()));
      end
  end
 
  -- Create an update function for the animation
  _animation.Update = function(dt)
    _animation.currentTime = _animation.currentTime + dt;

    if _animation.currentTime >= _animation.duration then
          _animation.currentTime = _animation.currentTime - _animation.duration
      end
  end

  -- Gettin the current frame as a quad
  _animation.GetCurrentFrame = function()
    spriteNum = math.floor(_animation.currentTime / _animation.duration * #_animation.quads) + 1;
    return _animation.quads[spriteNum];
  end

  -- Return the new animation object
  return _animation;
end

function ConstructAnimationPartial(sprite_image, sprite_width, sprite_height, sprite_start, sprite_end, duration)
   -- Local variables
  local _animation = {}
  
  -- Create animation
  _animation.spriteSheet = sprite_image;
  _animation.quads = {};
  _animation.duration = duration or 1; -- default to 1 if it wasn't specified.
  _animation.currentTime = 0;
  _animation.spriteNum = 0;

  -- Use quads to split up the image and store it in quads
  for y = 0, sprite_image:getHeight() - sprite_height, sprite_height do
      for x = sprite_start, sprite_end - sprite_width, sprite_width do
          table.insert(_animation.quads, love.graphics.newQuad(x + sprite_start, y, sprite_width, sprite_height, sprite_image:getDimensions()));
      end
  end
 
  -- Create an update function for the animation
  _animation.Update = function(dt)
    _animation.currentTime = _animation.currentTime + dt;

    if _animation.currentTime >= _animation.duration then
          _animation.currentTime = _animation.currentTime - _animation.duration
      end
  end

  -- Gettin the current frame as a quad
  _animation.GetCurrentFrame = function()
    spriteNum = math.floor(_animation.currentTime / _animation.duration * #_animation.quads) + 1;
    return _animation.quads[spriteNum];
  end

  -- Return the new animation object
  return _animation;
end