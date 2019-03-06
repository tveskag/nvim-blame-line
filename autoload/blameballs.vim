function! blameballs#nvimAnnotate(bufN, lineN, comment)
    call nvim_buf_clear_namespace(a:bufN, 614, 0, -1)
    if a:comment !=# ''
        call nvim_buf_set_virtual_text(a:bufN, 614, a:lineN - 1, [[a:comment, "Comment"]], {})
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
    let l:blame = systemlist('cd '.l:git_parent.'; git --git-dir='.b:BlameLineGitdir.' --work-tree='.l:git_parent.' blame --contents - '.expand('%:p').' --line-porcelain -L '.a:lineN.','.a:lineN.' -M', a:bufN)
    if v:shell_error > 0
        echo l:blame[-1]
        return
    endif
    let l:author = strpart(l:blame[1], 7)
    let l:time = strftime("%d/%m %H:%M %Y", strpart(l:blame[3], 12))
    let l:summary = strpart(l:blame[9], 8)
    return l:author.' :: '.l:time.' :: '.l:summary
endfunction
