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

function! InitBlameLine()
    if !exists('b:git_dir')
        let b:BlameLineGitdir = system('cd '.expand(':p:h').'; git rev-parse --git-dir')[0]
    else
        let b:BlameLineGitdir = b:git_dir
    endif

    if !exists('*b:ToggleBlameLine')
        let b:ToggleBlameLine = function('blameline#EnableBlameLine')
    endif
endfunction

function! s:createCursorHandler(bufN)
    function! s:handler(lineN) closure
        let l:comment = blameballs#getAnnotation(a:bufN, a:lineN)
        call s:annotateLine(a:bufN, a:lineN, l:comment)
    endfunction

    if has('timers') && has('lambda')
        let l:cursorTimer = 0

        function! s:debouncedHandler(lineN) closure
            call timer_stop(l:cursorTimer)
            let l:cursorTimer = timer_start(20, {-> s:handler(a:lineN)})
        endfunction

        return funcref('s:debouncedHandler')
    else
        return funcref('s:handler')
    endif
endfunction


function! blameline#EnableBlameLine()
    let s:onCursorMoved = s:createCursorHandler(bufnr('%'))
    augroup showBlameLine
        autocmd CursorMoved <buffer> call s:onCursorMoved(line('.'))
    augroup END
    call s:onCursorMoved(line('.'))

    let b:ToggleBlameLine = function('blameline#DisableBlameLine')
endfunction

function! blameline#DisableBlameLine()
    call s:annotateLine(bufnr('%'), 0, '')
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('blameline#EnableBlameLine')
endfunction

command! ToggleBlameLine :call b:ToggleBlameLine()
command! EnableBlameLine :call blameline#EnableBlameLine()
command! DisableBlameLine :call blameline#DisableBlameLine()
