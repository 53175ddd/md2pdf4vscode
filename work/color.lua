-- pandoc Lua filter: colour text written as [text]{color=red} or [text]{color=#c00000}
-- by wrapping the span in Typst's #text(fill: ...)[...].
-- Accepted values: Typst's named colours below, or #rgb / #rrggbb hex codes.
-- Anything else is left uncoloured with a warning (and never passed to Typst as-is).
--
-- It also drops a line break between any span and adjacent East Asian text:
-- pandoc's east_asian_line_breaks extension does not look into spans, so
-- "[色]{color=red}<newline>の" would otherwise get a space in the PDF.

local NAMED = {
  black = true, gray = true, silver = true, white = true,
  navy = true, blue = true, aqua = true, teal = true, eastern = true,
  purple = true, fuchsia = true, maroon = true, red = true, orange = true,
  yellow = true, olive = true, green = true, lime = true,
}

local function typst_color(value)
  local v = value:lower():gsub('^%s+', ''):gsub('%s+$', '')
  if NAMED[v] then return v end
  if v:match('^#%x%x%x$') or v:match('^#%x%x%x%x%x%x$') then
    return 'rgb("' .. v .. '")'
  end
  return nil
end

local function color_span(el)
  local value = el.attributes.color
  if value == nil or not FORMAT:match('typst') then return nil end
  local fill = typst_color(value)
  if fill == nil then
    io.stderr:write('[color.lua] warning: unsupported color "' .. value .. '" (ignored)\n')
    return nil
  end
  local out = { pandoc.RawInline('typst', '#text(fill: ' .. fill .. ')[') }
  for _, inline in ipairs(el.content) do table.insert(out, inline) end
  table.insert(out, pandoc.RawInline('typst', ']'))
  return out
end

-- East Asian wide characters (CJK, kana, hangul, full-width forms and punctuation)
local function is_wide(cp)
  return cp ~= nil and (
    (cp >= 0x1100 and cp <= 0x11FF) or (cp >= 0x2E80 and cp <= 0xA4CF) or
    (cp >= 0xAC00 and cp <= 0xD7A3) or (cp >= 0xF900 and cp <= 0xFAFF) or
    (cp >= 0xFE30 and cp <= 0xFE4F) or (cp >= 0xFF00 and cp <= 0xFF60) or
    (cp >= 0xFFE0 and cp <= 0xFFE6) or (cp >= 0x20000 and cp <= 0x3FFFF))
end

local function first_cp(inline)
  local text = pandoc.utils.stringify(inline)
  if text == '' then return nil end
  return utf8.codepoint(text, 1)
end

local function last_cp(inline)
  local text = pandoc.utils.stringify(inline)
  if text == '' then return nil end
  return utf8.codepoint(text, utf8.offset(text, -1))
end

local function is_span(inline)
  return inline ~= nil and inline.t == 'Span'
end

local function drop_breaks_around_spans(inlines)
  local out = pandoc.Inlines({})
  for i, inline in ipairs(inlines) do
    local prev, nxt = inlines[i - 1], inlines[i + 1]
    local keep = true
    if inline.t == 'SoftBreak' and prev ~= nil and nxt ~= nil
        and (is_span(prev) or is_span(nxt))
        and is_wide(last_cp(prev)) and is_wide(first_cp(nxt)) then
      keep = false
    end
    if keep then out:insert(inline) end
  end
  return out
end

-- Line breaks must be fixed while the spans are still Span elements.
return {
  { Inlines = drop_breaks_around_spans },
  { Span = color_span },
}
