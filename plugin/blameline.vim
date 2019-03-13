if exists('g:blameline_loaded')
    finish
endif
let g:blameline_loaded = 1

let g:blameLineUseVirtualText = get(g:, 'blameLineUseVirtualText', 1)

augroup enableBlameLine
    autocmd!
    autocmd BufReadPre,FileReadPre * call blameline#InitBlameLine()
augroup END

command! ToggleBlameLine :call b:ToggleBlameLine()
command! EnableBlameLine :call blameline#EnableBlameLine()
command! DisableBlameLine :call blameline#DisableBlameLine()
command! SingleBlameLine :call blameline#SingleBlameLine()
