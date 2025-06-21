return {
  animation_group = vim.api.nvim_create_augroup("TinyGlimmer", { clear = true }),
  tiny_glimmer_animation_ns = vim.api.nvim_create_namespace("tiny-glimmer"),
}
