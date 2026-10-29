-- pandoc Lua filter: an image that stands alone in its paragraph (a screenshot,
-- a diagram) is drawn with a drop shadow via shadow-image() from work/style.typ.
-- Images inside running text (including :icon_name: icons) are left unchanged.

local function typst_string(s)
  local escaped = s:gsub('[\\"]', '\\%0')
  return '"' .. escaped .. '"'
end

local function percent_decode(s)
  return (s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end))
end

function Para(el)
  if not FORMAT:match('typst') then return nil end
  if #el.content ~= 1 or el.content[1].t ~= 'Image' then return nil end
  local img = el.content[1]
  local args = typst_string(percent_decode(img.src))
  local alt = pandoc.utils.stringify(img.caption)
  if alt ~= '' then args = args .. ', alt: ' .. typst_string(alt) end
  return pandoc.RawBlock('typst', '#shadow-image(image(' .. args .. '))')
end
