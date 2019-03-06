if exists('g:blameline_loaded')
    finish
endif
let g:blameline_loaded = 1

let g:blameLineUseVirtualText = get(g:, 'blameLineUseVirtualText', 1)

if has('nvim') && has('nvim-0.3.4') && (g:blameLineUseVirtualText)
    let s:annotateLine = function('blameballs#nvimAnnotate')
else
    let s:annotateLine = function('blameballs#vimEcho')
endif

augroup enableBlameLine
    autocmd!
    autocmd BufReadPre,FileReadPre,BufEnter * call InitBlameLine()
augroup END

function! s:onCursorMoved(bufN, lineN)
    let l:comment = blameballs#getAnnotation(a:bufN, a:lineN)
    call s:annotateLine(a:bufN, a:lineN, l:comment)
endfunction

function! InitBlameLine()
    if !exists('b:git_dir')
        let b:BlameLineGitdir = system('cd '.expand(':p:h').'; git rev-parse --git-dir')[0]
    else
        let b:BlameLineGitdir = b:git_dir
    endif

    if !exists('*b:ToggleBlameLine')
        let b:ToggleBlameLine = function('EnableBlameLine')
    endif
endfunction

function! EnableBlameLine()
    augroup showBlameLine
        autocmd CursorMoved <buffer> call s:onCursorMoved(bufnr('%'), line('.'))
    augroup END
    call s:onCursorMoved(bufnr('%'), line('.'))

    let b:ToggleBlameLine = function('DisableBlameLine')
endfunction

function! DisableBlameLine()
    call s:annotateLine(bufnr('%'), 0, '')
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('EnableBlameLine')
endfunction

function! ToggleBlameLine()
    call b:ToggleBlameLine()
endfunction
