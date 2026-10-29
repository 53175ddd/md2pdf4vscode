-- pandoc Lua filter: number section headings automatically.
--
-- Enabled only when the document contains a comment like
--   <!-- origin: 1 -->
-- (anywhere, on its own line). The number is the one given to the first "##"
-- heading; following "##" headings count up from it. Sub-headings count from 1
-- within their parent and are joined with "-":
--   ## 1. Intro / ### 1-1. Background / #### 1-1-1. Detail / ## 2. Notes
-- "#" (the title) and "#####" or deeper are never numbered.
-- Documents without the comment are left exactly as written.

local TOP = 2      -- "##"
local BOTTOM = 4   -- "####"
local ORIGIN_PATTERN = '^%s*<!%-%-%s*origin%s*:%s*(%d+)%s*%-%->%s*$'

local function warn(msg)
  io.stderr:write('[numbering.lua] warning: ' .. msg .. '\n')
end

local function find_origin(blocks)
  local origin = nil
  for _, block in ipairs(blocks) do
    if block.t == 'RawBlock' and block.format == 'html' then
      local n = block.text:match(ORIGIN_PATTERN)
      if n then
        if origin == nil then
          origin = tonumber(n)
        else
          warn('more than one <!-- origin: N --> comment; using the first (' .. origin .. ')')
        end
      end
    end
  end
  return origin
end

function Pandoc(doc)
  local origin = find_origin(doc.blocks)
  if origin == nil then return nil end

  -- counters[2] = "##" number, counters[3] = "###", counters[4] = "####"
  local counters = {}
  local started = false  -- seen the first "##"

  doc.blocks = doc.blocks:walk({
    Header = function(el)
      if el.level < TOP or el.level > BOTTOM then return nil end
      local title = pandoc.utils.stringify(el.content)

      if el.level == TOP then
        counters[TOP] = started and counters[TOP] + 1 or origin
        started = true
      else
        local parent = counters[el.level - 1]
        if parent == nil then
          warn('"' .. string.rep('#', el.level) .. ' ' .. title ..
               '" has no parent heading one level up; left unnumbered')
          return nil
        end
        counters[el.level] = (counters[el.level] or 0) + 1
      end
      -- a new heading restarts the numbering of the levels below it
      for level = el.level + 1, BOTTOM do counters[level] = nil end

      if title:match('^%d+[%.%-]') then
        warn('"' .. title .. '" already starts with a number; remove it to avoid double numbering')
      end

      local parts = {}
      for level = TOP, el.level do table.insert(parts, tostring(counters[level])) end
      local label = table.concat(parts, '-') .. '.'
      el.content = pandoc.Inlines({ pandoc.Str(label), pandoc.Space() }) .. el.content
      return el
    end,
  })
  return doc
end
