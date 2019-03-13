function! s:nvimAnnotate(comment, bufN, lineN)
    call nvim_buf_set_virtual_text(a:bufN, s:ns_id, a:lineN - 1, [[a:comment, "Comment"]], {})
endfunction

function! s:nvimClearAnnotation(bufN)
    call nvim_buf_clear_namespace(a:bufN, s:ns_id, 0, -1)
endfunction

function! s:nvimClearAndAnnotate(comment,bufN, lineN)
  call s:nvimClearAnnotation(a:bufN)
  call s:nvimAnnotate(a:comment, a:bufN, a:lineN)
endfunction

function! s:vimEcho(comment, ...)
    echom a:comment
endfunction

function! s:vimClearEcho(...)
    echo ''
endfunction

function! s:vimClearAndEcho(comment, ...)
    call s:vimClearEcho()
    call s:vimEcho(a:comment)
endfunction

if has('nvim') && has('nvim-0.3.4') && (g:blameLineUseVirtualText)
    let s:ns_id = nvim_create_namespace('nvim-blame-line')
    let s:annotateLine = function('s:nvimClearAndAnnotate')
    let s:clearAnnotation = function('s:nvimClearAnnotation')
else
    let s:annotateLine = function('s:vimClearAndEcho')
    let s:clearAnnotation = function('s:vimClearEcho')
endif

function! s:getAnnotation(bufN, lineN)
    let l:git_parent = fnamemodify(b:BlameLineGitdir, ':h')
    let l:gitcommand = 'cd '.l:git_parent.'; git --git-dir='.b:BlameLineGitdir.' --work-tree='.l:git_parent
    let l:blame = systemlist(l:gitcommand.' annotate --contents - '.expand('%:p').' --porcelain -L '.a:lineN.','.a:lineN.' -M', a:bufN)
    if v:shell_error > 0
        call s:vimEcho(l:blame[-1])
        return ''
    endif
    let l:commit = strpart(l:blame[0], 0, 40)
    let l:format = '%an | %ar | %s'
    if l:commit ==# '0000000000000000000000000000000000000000'
        let l:annotation = ['Not committed yet']
    else
        let l:annotation = systemlist(l:gitcommand.' show '.l:commit.' --format="'.l:format.'"')
    endif
    if v:shell_error > 0
        call s:vimEcho(l:annotation[-1])
        return ''
    endif
    return l:annotation[0]
endfunction

function! s:createCursorHandler(bufN)
    function! s:handler(buffer, lineN) closure
        let l:comment = s:getAnnotation(a:buffer, a:lineN)
        call s:annotateLine(l:comment, a:buffer, a:lineN)
    endfunction

    if has('timers') && has('lambda')
        let l:cursorTimer = 0

        function! s:debouncedHandler(buffer, lineN) closure
            call timer_stop(l:cursorTimer)
            let l:cursorTimer = timer_start(70, {-> s:handler(a:buffer, a:lineN)})
        endfunction

        return function('s:debouncedHandler', [a:bufN])
    else
        return function('s:handler', [a:bufN])
    endif
endfunction

function! s:createCursorHandlerSingle(bufN)
    function! s:handler(buffer, ...) closure
        call s:clearAnnotation(a:buffer)
        autocmd! clearBlameLine * <buffer>
    endfunction

    return function('s:handler', [a:bufN])
endfunction

function! blameline#InitBlameLine()
    if !exists('*b:ToggleBlameLine')
        let b:BlameLineGitdir = systemlist('cd '.expand('%:p:h').'; git rev-parse --git-dir')[-1]
        if v:shell_error > 0
            let b:ToggleBlameLine = function('s:vimEcho', [b:BlameLineGitdir])
            return
        endif

        let l:rel_to_git_parent = substitute(expand('%:p'), fnamemodify(b:BlameLineGitdir, ':h').'/', '', '')
        let l:fileExists = systemlist('cd '.expand('%:p:h').'; git cat-file -e HEAD:'.l:rel_to_git_parent)
        if v:shell_error > 0
            let b:ToggleBlameLine = function('s:vimEcho', l:fileExists)
            return
        endif

        let b:ToggleBlameLine = function('blameline#EnableBlameLine')
    endif
endfunction

function! blameline#EnableBlameLine()
    let b:onCursorMoved = s:createCursorHandler(bufnr('%'))
    augroup showBlameLine
        autocmd CursorMoved <buffer> call b:onCursorMoved(line('.'))
    augroup END
    call b:onCursorMoved(line('.'))

    let b:ToggleBlameLine = function('blameline#DisableBlameLine')
endfunction

function! blameline#DisableBlameLine()
    call s:annotateLine('', bufnr('%'), 1)
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('blameline#EnableBlameLine')
endfunction

function! blameline#SingleBlameLine()
    let l:comment = s:getAnnotation(bufnr('%'), line('.'))
    call s:annotateLine(l:comment, bufnr('%'), line('.'))

    let b:onCursorMoved = s:createCursorHandlerSingle(bufnr('%'))
    augroup clearBlameLine
        autocmd CursorMoved <buffer> call b:onCursorMoved(line('.'))
    augroup END
endfunction
