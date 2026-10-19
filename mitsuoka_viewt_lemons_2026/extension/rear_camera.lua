-- Draws the rear camera ([RENDERING_CAMERA_0] and [TEXTURE_PREPROCESSING_0] in ext_config.ini) on the REAR_VIEW_DISPLAY screen.

local WIDTH, HEIGHT = 512, 308                -- same as RESOLUTION in ext_config.ini
local MIRROR_IMAGE = true                     -- backup cameras show a mirror image, so left on the screen is the car's left;
                                              -- set to false if the picture is the wrong way round

function script.update(dt)
  ac.setRenderingCameraActive('RENDERING_CAMERA_0', true)
  display.rect{ pos = vec2(0, 0), size = vec2(WIDTH, HEIGHT), color = rgbm.colors.black }
  display.image{
    image = 'dynamic::rear_camera_view',
    pos = vec2(0, 0),
    size = vec2(WIDTH, HEIGHT),
    uvStart = MIRROR_IMAGE and vec2(1, 0) or vec2(0, 0),
    uvEnd = MIRROR_IMAGE and vec2(0, 1) or vec2(1, 1)
  }
end
