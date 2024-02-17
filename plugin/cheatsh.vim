if exists('g:loaded_nvim_cheat') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_nvim_cheat = 1

command! -nargs=* Cheat lua require'nvim-cheatsh'.open(<f-args>)
command! -nargs=0 CheatClose lua require'nvim-cheatsh'.close()
command! -nargs=0 CheatList lua require'nvim-cheatsh'.list()
