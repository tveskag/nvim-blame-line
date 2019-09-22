if has('nvim-0.3.2')
    let s:ns_id = nvim_create_namespace('blame-line')
endif

function! blameballs#nvimAnnotate(bufN, lineN, comment)
    call nvim_buf_clear_namespace(a:bufN, s:ns_id, 0, -1)
    if a:comment !=# ''
        call nvim_buf_set_virtual_text(a:bufN, s:ns_id, a:lineN - 1, [[a:comment, "Comment"]], {})
    endif
endfunction

function! blameballs#vimEcho(bufN, lineN, comment)
    echo ''
    if a:comment !=# ''
        echom a:comment
    endif
endfunction

function! blameballs#getAnnotation(bufN, lineN)
    let l:git_parent = fnamemodify(b:BlameLineGitdir, ':h')
    let l:gitcommand = 'cd '.l:git_parent.'; git --git-dir='.b:BlameLineGitdir.' --work-tree='.l:git_parent
    let l:blame = systemlist(l:gitcommand.' annotate --contents - '.expand('%:p').' --porcelain -L '.a:lineN.','.a:lineN.' -M', a:bufN)
    if v:shell_error > 0
        echo l:blame[-1]
        return
    endif
    let l:commit = strpart(l:blame[0], 0, 40)
    let l:format = '%an | %ar | %s'
    if l:commit ==# '0000000000000000000000000000000000000000'
        let l:annotation = ['Not committed yet']
    else
        let l:annotation = systemlist(l:gitcommand.' show '.l:commit.' --format="'.l:format.'"')
    endif
    if v:shell_error > 0
        echo l:annotation[-1]
        return
    endif
    return l:annotation[0]
endfunction

function! blameballs#createCursorHandler(bufN)
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
