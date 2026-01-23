-- Health check for ragex.nvim

local M = {}

function M.check()
  local ragex = require("ragex")
  ragex.health()
end

return M
