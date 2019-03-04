function! EnableBlameLine()
    augroup showGitComments
        autocmd CursorMoved <buffer> call blameballs#GitCommentAnnotate(bufnr('%'), line('.'))
    augroup END
    call blameballs#GitCommentAnnotate(bufnr('%'), line('.'))

    let b:ToggleBlameLine = function('DisableBlameLine')
endfunction

function! DisableBlameLine()
    call nvim_buf_clear_namespace(bufnr('%'), 614, 0, -1)
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('EnableBlameLine')
endfunction

augroup enableGitCommentsOnBufEnter
    autocmd!
    autocmd BufReadPre,FileReadPre * call InitBlameLine()
augroup END
function InitBlameLine()
    if !exists('*b:ToggleBlameLine')
        let b:ToggleBlameLine = function('EnableBlameLine')
    endif
endfunction
