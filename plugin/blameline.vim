if exists('g:blameline_loaded')
    finish
endif
let g:blameline_loaded = 1

let g:blameLineUseVirtualText = get(g:, 'blameLineUseVirtualText', 1)
let g:blameLineVirtualTextHighlight = get(g:, 'blameLineVirtualTextHighlight', 'Comment')
let g:blameLineVirtualTextPrefix = get(g:, 'blameLineVirtualTextPrefix', '')

augroup enableBlameLine
    autocmd!
    autocmd BufReadPre,FileReadPre * call s:InitBlameLine()
augroup END

command! ToggleBlameLine :call b:ToggleBlameLine()
command! EnableBlameLine :call s:EnableBlameLine()
command! DisableBlameLine :call s:DisableBlameLine()
command! SingleBlameLine :call s:SingleBlameLine()

function! s:nvimAnnotate(comment, bufN, lineN)
    call nvim_buf_clear_namespace(a:bufN, g:blameline_ns_id, 0, -1)
    call nvim_buf_set_virtual_text(a:bufN, g:blameline_ns_id, a:lineN - 1, [[a:comment, g:blameLineVirtualTextHighlight]], {})
endfunction

function! s:vimEcho(comment, ...)
    mode
    if string(a:comment) ==# ''
        return 0
    endif
    echom string(a:comment)
    return 1
endfunction

if has('nvim') && has('nvim-0.3.4') && (g:blameLineUseVirtualText)
    let g:blameline_ns_id = nvim_create_namespace('nvim-blame-line')
    let s:annotateLine = function('s:nvimAnnotate')
else
    let s:annotateLine = function('s:vimEcho')
endif
let b:onCursorMoved = {-> s:vimEcho('Blameline not yet initialized')}

function! s:getAnnotation(bufN, lineN, gitdir)
    let l:git_parent = fnamemodify(a:gitdir, ':h')
    let l:gitcommand = 'cd '.l:git_parent.'; git --git-dir='.a:gitdir.' --work-tree='.l:git_parent
    let l:blame = systemlist(l:gitcommand.' annotate --contents - '.expand('%:p').' --porcelain -L '.a:lineN.','.a:lineN.' -M', a:bufN)
    if v:shell_error > 0
        call s:vimEcho(l:blame)
    endif
    let l:commit = strpart(l:blame[0], 0, 40)
    let l:format = '%an | %ar | %s'
    if l:commit ==# '0000000000000000000000000000000000000000'
        let l:annotation = ['Not yet committed']
    else
        let l:annotation = systemlist(l:gitcommand.' show '.l:commit.' --format="'.l:format.'"')
    endif
    if v:shell_error > 0
        call s:vimEcho(l:annotation)
    endif
    return g:blameLineVirtualTextPrefix . l:annotation[0]
endfunction

function! s:createCursorHandler(bufN, gitdir)
    function! s:handler(lineN) closure
        let l:comment = s:getAnnotation(a:bufN, a:lineN, a:gitdir)
        call s:annotateLine(l:comment, a:bufN, a:lineN)
    endfunction

    if has('timers') && has('lambda')
        let l:cursorTimer = 0
        function! s:debouncedHandler(lineN) closure
            call timer_stop(l:cursorTimer)
            let l:cursorTimer = timer_start(70, {-> s:handler(a:lineN)})
        endfunction
        return function('s:debouncedHandler')
    else
        return function('s:handler')
    endif
endfunction

function! s:InitBlameLine()
    if !exists('*b:ToggleBlameLine')
        let b:ToggleBlameLine = function('s:EnableBlameLine')
        let l:BlameLineGitdir = systemlist('cd '.expand('%:p:h').'; git rev-parse --git-dir')[-1]
        if v:shell_error > 0
            let b:onCursorMoved = {-> s:vimEcho(l:BlameLineGitdir) && s:DisableBlameLine()}
            return
        endif
        if l:BlameLineGitdir[0] !=# '/'
            let l:BlameLineGitdir = expand('%:p:h').'/'.l:BlameLineGitdir
        endif

        let l:rel_to_git_parent = substitute(expand('%:p'), escape(fnamemodify(l:BlameLineGitdir, ':h').'/', '.'), '', '')
        let l:fileExists = systemlist('cd ' . expand('%:p:h') . '; git cat-file -e HEAD:' . l:rel_to_git_parent)
        if v:shell_error > 0
            let b:onCursorMoved = {-> s:vimEcho(l:fileExists) && s:DisableBlameLine()}
            return
        endif
        let b:onCursorMoved = s:createCursorHandler(bufnr('%'), l:BlameLineGitdir)
    endif
endfunction

function! s:SingleBlameLine()
    call b:onCursorMoved(line('.'))
    augroup showBlameLine
        autocmd! CursorMoved <buffer> call s:DisableBlameLine()
    augroup END
endfunction

function! s:EnableBlameLine()
    augroup showBlameLine
        autocmd CursorMoved <buffer> call b:onCursorMoved(line('.'))
    augroup END
    call b:onCursorMoved(line('.'))
    let b:ToggleBlameLine = function('s:DisableBlameLine')
endfunction

function! s:DisableBlameLine()
    call s:annotateLine('', bufnr('%'), 1)
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('s:EnableBlameLine')
endfunction
