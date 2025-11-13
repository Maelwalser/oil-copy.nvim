local M = {}

--- @param opts table | nil
function M.setup(opts)
  -- Set default options
  opts = opts or {}
  opts.keymap = opts.keymap or "<leader>cf"
  local core = require("oil-copy.core")

  -- Define the keymap
  local new_keymaps = {
    [opts.keymap] = {
      callback = core.copy_entry_contents,
      desc = "Copy entry contents to clipboard",
      mode = "n",
    },
  }

  -- Get the user's current oil.nvim config 
  local lazy_oil_opts = {}
  local success, lazy_spec = pcall(require, "lazy.core.spec").find("oil.nvim")
  if success and lazy_spec and lazy_spec.opts then
    lazy_oil_opts = vim.deepcopy(lazy_spec.opts)
  end

  local final_oil_opts = vim.tbl_deep_extend(
    "force",
    lazy_oil_opts,
    {
      keymaps = new_keymaps,
    }
  )

  require("oil").setup(final_oil_opts)
end

return M
