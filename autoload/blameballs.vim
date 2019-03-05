function! blameballs#BlameLineAnnotate(bufN, lineN)

    call nvim_buf_clear_namespace(a:bufN, 614, 0, -1)

    let git_parent = fnamemodify(b:git_dir, ':h')
    let blame = systemlist('git --git-dir='.b:git_dir.' --work-tree='.l:git_parent.' blame --contents - '.expand('%:p').' --line-porcelain -L '.a:lineN.','.a:lineN.' -M', a:bufN)
    if v:shell_error > 0
        echo blame[-1]
        return
    endif
    let author = strpart(l:blame[1], 7)
    let time = strftime("%d/%m %H:%M %Y", strpart(l:blame[3], 12))
    let summary = strpart(l:blame[9], 8)
    let comment = l:author.' :: '.l:time.' :: '.l:summary

    call nvim_buf_set_virtual_text(a:bufN, 614, a:lineN - 1, [[l:comment, "Comment"]], {})

endfunction
