-- pandoc Lua filter: a line consisting only of <!-- pagebreak --> (as its own
-- paragraph, i.e. with blank lines around it) becomes a page break in the PDF.
-- Previews such as GitHub hide the comment, so the source stays readable.
-- Matching ignores case and surrounding spaces: <!--PageBreak--> works too.
-- Other HTML comments are left alone (they are dropped from the PDF as before).

local function is_pagebreak(text)
  return text:lower():match('^%s*<!%-%-%s*pagebreak%s*%-%->%s*$') ~= nil
end

function RawBlock(el)
  if el.format ~= 'html' or not FORMAT:match('typst') then return nil end
  if is_pagebreak(el.text) then
    -- weak: no empty page if the break already falls at the top of a page
    return pandoc.RawBlock('typst', '#pagebreak(weak: true)')
  end
  return nil
end
