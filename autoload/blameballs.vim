function! blameballs#GitCommentAnnotate(bufN, lineN)
    call nvim_buf_clear_namespace(a:bufN, 614, 0, -1)
    let git_parent = fnamemodify(b:git_dir, ':h')
    let gblame = system('git --git-dir='.b:git_dir.' --work-tree='.l:git_parent.' blame '.expand('%:p').' --line-porcelain -L '.a:lineN.','.a:lineN)
    let blamelist = split(l:gblame, '\n')
    let author = strpart(l:blamelist[1], 7)
    let time = strftime("%d/%m %H:%M %Y", strpart(l:blamelist[3], 12))
    let summary = strpart(l:blamelist[9], 8)
    let comment = l:author.' :: '.l:time.' :: '.l:summary

    call nvim_buf_set_virtual_text(a:bufN, 614, a:lineN - 1, [[l:comment, "Comment"]], {})
endfunction
