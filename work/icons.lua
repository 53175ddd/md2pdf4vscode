-- pandoc Lua filter: replace :icon_name: with the image source/_icons/icon_name.<ext>,
-- sized to the text height like an emoji (similar to Discord's custom emoji).
--   :icon_a::icon_b:   -> icons placed with no gap
--   :icon_a: :icon_b:  -> icons separated by a normal space
-- The first existing extension in EXTENSIONS wins. Unknown names are left as
-- text with a warning. Typst reads the image via a root-relative path
-- ("/_icons/..."), since md2pdf.ps1 runs typst with --root source/.

local EXTENSIONS = { 'svg', 'png', 'jpg', 'jpeg', 'gif', 'webp' }
local NAME_PATTERN = ':(icon_[%w_%-]+):'

local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local icon_dir = pandoc.path.join({ script_dir, '..', 'source', '_icons' })

local found = {}  -- name -> file name, or false if missing

local function file_exists(path)
  local f = io.open(path, 'rb')
  if f then f:close() return true end
  return false
end

local function icon_file(name)
  if found[name] == nil then
    found[name] = false
    for _, ext in ipairs(EXTENSIONS) do
      local file = name .. '.' .. ext
      if file_exists(pandoc.path.join({ icon_dir, file })) then
        found[name] = file
        break
      end
    end
    if not found[name] then
      io.stderr:write('[icons.lua] warning: no icon for :' .. name .. ': in source/_icons (left as text)\n')
    end
  end
  return found[name]
end

local function icon_inline(file, name)
  -- baseline shifts the box down so the icon sits on the text like a glyph;
  -- the trailing ';' ends the Typst expression so following text (e.g. '.')
  -- is not read as part of it.
  return pandoc.RawInline('typst',
    '#box(baseline: 0.15em, image("/_icons/' .. file .. '", height: 1em, alt: "' .. name .. '"));')
end

function Str(el)
  if not FORMAT:match('typst') or not el.text:find(':icon_', 1, true) then return nil end
  local out = {}
  local pos = 1
  local changed = false
  while true do
    local s, e, name = el.text:find(NAME_PATTERN, pos)
    if s == nil then break end
    local file = icon_file(name)
    if file then
      if s > pos then table.insert(out, pandoc.Str(el.text:sub(pos, s - 1))) end
      table.insert(out, icon_inline(file, name))
      changed = true
      pos = e + 1
    else
      -- keep the text up to the name; the closing ':' may open the next icon
      table.insert(out, pandoc.Str(el.text:sub(pos, e - 1)))
      pos = e
    end
  end
  if not changed then return nil end
  if pos <= #el.text then table.insert(out, pandoc.Str(el.text:sub(pos))) end
  return out
end
