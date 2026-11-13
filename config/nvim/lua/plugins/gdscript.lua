return {
  -- Fix GDScript completion quirks from the Godot LSP
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      local orig = opts.sources and opts.sources.transform_items
      opts.sources = opts.sources or {}
      opts.sources.transform_items = function(ctx, items)
        if orig then items = orig(ctx, items) end
        if vim.bo.filetype ~= "gdscript" then return items end
        for _, item in ipairs(items) do
          -- Godot LSP includes the closing quote in action name completions;
          -- strip it so mini.pairs doesn't produce a double quote.
          if item.insertText and item.insertText:sub(-1) == '"' then
            item.insertText = item.insertText:sub(1, -2)
          end
          if item.textEdit and item.textEdit.newText and item.textEdit.newText:sub(-1) == '"' then
            item.textEdit.newText = item.textEdit.newText:sub(1, -2)
          end
          -- Godot LSP appends '(' to function completions without ')'.
          -- Convert to a snippet so the cursor lands inside the brackets.
          local text = (item.textEdit and item.textEdit.newText) or item.insertText
          if text and text:sub(-1) == "(" then
            item.insertTextFormat = 2
            if item.textEdit then
              item.textEdit.newText = item.textEdit.newText .. "$1)$0"
            else
              item.insertText = item.insertText .. "$1)$0"
            end
          end
        end
        return items
      end
      return opts
    end,
  },
}
