function! EnableGitComments()
    augroup showGitComments
        autocmd CursorMoved <buffer> call blameballs#GitCommentAnnotate(bufnr('%'), line('.'))
    augroup END
    call blameballs#GitCommentAnnotate(bufnr('%'), line('.'))

    let b:ToggleGitComments = function('DisableGitComments')
endfunction

function! DisableGitComments()
    call nvim_buf_clear_namespace(bufnr('%'), 614, 0, -1)
    autocmd! showGitComments * <buffer>
    let b:ToggleGitComments = function('EnableGitComments')
endfunction

augroup enableGitCommentsOnBufEnter
    autocmd!
    autocmd BufReadPre,FileReadPre * call InitGitComment()
augroup END
function InitGitComment()
    if !exists('*b:ToggleGitComments')
        let b:ToggleGitComments = function('EnableGitComments')
    endif
endfunction
