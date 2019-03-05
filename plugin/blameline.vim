if exists('g:blameline_loaded')
    finish
endif
let g:blameline_loaded = 1

function! EnableBlameLine()
    augroup showBlameLine
        autocmd CursorMoved <buffer> call blameballs#BlameLineAnnotate(bufnr('%'), line('.'))
    augroup END
    call blameballs#BlameLineAnnotate(bufnr('%'), line('.'))

    let b:ToggleBlameLine = function('DisableBlameLine')
endfunction

function! DisableBlameLine()
    call nvim_buf_clear_namespace(bufnr('%'), 614, 0, -1)
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('EnableBlameLine')
endfunction

function! ToggleBlameLine()
    call b:ToggleBlameLine()
endfunction

augroup enableBlameLine
    autocmd!
    autocmd BufReadPre,FileReadPre,BufEnter * call InitBlameLine()
augroup END
function InitBlameLine()
    if !exists('b:git_dir')
        let b:git_dir = system('git rev-parse --git-dir')[0]
    endif
    if !exists('*b:ToggleBlameLine')
        let b:ToggleBlameLine = function('EnableBlameLine')
    endif
endfunction
