if exists('g:blameLine_loaded')
    finish
endif
let g:blameLine_loaded = 1

let g:blameLineGitFormat = get(g:, 'blameLineGitFormat', '%an | %ar | %s')
let g:blameLineUseVirtualText = get(g:, 'blameLineUseVirtualText', 1)
let g:blameLineVirtualTextHighlight = get(g:, 'blameLineVirtualTextHighlight', 'Comment')
let g:blameLineVirtualTextFormat = get(g:, 'blameLineVirtualTextFormat', '%s')
let g:blameLineVerbose = get(g:, 'blameLineVerbose', 0)
let g:blameLineMessageWhenNotYetCommited = get(g:, 'blameLineMessageWhenNotYetCommited', 'Not yet committed')

function s:createError(error)
    return g:blameLineVerbose ? {-> s:vimEcho(a:error) && s:DisableBlameLine()} : {-> s:DisableBlameLine()}
endfunction

let s:blameLineNsId = g:blameLineUseVirtualText && has('nvim') && has('nvim-0.3.4') ?
    \ nvim_create_namespace('nvim-blame-line') : 0

function! s:nvimAnnotate(comment, bufN, lineN)
    call nvim_buf_clear_namespace(a:bufN, s:blameLineNsId, 0, -1)
    call nvim_buf_set_extmark(a:bufN, s:blameLineNsId, a:lineN - 1, 0, {"hl_mode": "combine", "virt_text": [[a:comment, g:blameLineVirtualTextHighlight]]})
endfunction

function! s:vimEcho(comment, ...)
    mode
    echom 'nvim-blame-line Error: ' . string(a:comment)
    return 1
endfunction

function! s:clearAll()
    mode
    if s:blameLineNsId
        call nvim_buf_clear_namespace(a:bufN, s:blameLineNsId, 0, -1)
    endif
endfunction

function s:getCleanDir(gitdir)
    let l:clean_dir = substitute(a:gitdir, '.git/worktrees/', '', '')
    if len(l:clean_dir) > 3 && l:clean_dir[-4:] == '.git'
        let l:clean_dir = fnamemodify(l:clean_dir, ':h')
    endif
    return l:clean_dir
endfunction

function! s:getAnnotation(bufN, lineN, gitdir)
    let l:clean_file_path = substitute(expand('%:p'), '.git/worktrees/', '', '')
    let l:clean_dir = s:getCleanDir(a:gitdir)

    let l:gitcommand = 'git -C '.l:clean_dir
    let l:blame = systemlist(l:gitcommand.' annotate '.l:clean_file_path.' --porcelain -L '.a:lineN.','.a:lineN.' -M'.a:bufN)
    if v:shell_error > 0
        let b:onCursorMoved = s:createError(l:blame)
    endif
    let l:commit = strpart(l:blame[0], 0, 40)
    let l:format = g:blameLineGitFormat
    if l:commit ==# '0000000000000000000000000000000000000000'
        " show nothing when this line is not yet committed.
        let l:annotation = [g:blameLineMessageWhenNotYetCommited]
    else
        let l:annotation = systemlist(l:gitcommand.' show -s '.l:commit.' --format="'.l:format.'"')
    endif
    if v:shell_error > 0
        let b:onCursorMoved = s:createError(l:annotation)
    endif
    return printf(g:blameLineVirtualTextFormat, l:annotation[0])
endfunction

function! s:createCursorHandler(bufN, gitdir, anno)
    function! s:handler(buf, lineN) closure
        let l:comment = s:getAnnotation(a:buf, a:lineN, a:gitdir)
        call a:anno(l:comment, a:buf, a:lineN)
    endfunction

    if has('timers') && has('lambda')
        let l:cursorTimer = 0
        function! s:debouncedHandler(buf, lineN) closure
            call timer_stop(l:cursorTimer)
            let l:cursorTimer = timer_start(70, {-> s:handler(a:buf, a:lineN)})
        endfunction
        return function('s:debouncedHandler', [a:bufN])
    else
        return function('s:handler', [a:bufN])
    endif
endfunction

function s:getCursorHandler()
    let b:ToggleBlameLine = function('s:EnableBlameLine')
    let l:BlameLineGitdir = systemlist('git -C '.expand('%:p:h').' rev-parse --git-dir')[-1]
    if v:shell_error > 0
        return s:createError(l:BlameLineGitdir)
    endif
    if l:BlameLineGitdir[0] !=# '/'
        let l:BlameLineGitdir = expand('%:p:h').'/'.l:BlameLineGitdir
    endif

    let l:clean_dir = s:getCleanDir(l:BlameLineGitdir)
    let l:rel_to_git_parent = substitute(expand('%:p'), l:clean_dir.'/', '', '')
    let l:fileExists = systemlist('git -C ' .expand('%:p:h'). ' cat-file -e HEAD:' . l:rel_to_git_parent)
    if v:shell_error > 0
        return s:createError(l:fileExists)
    endif
    return s:createCursorHandler(bufnr('%'), l:BlameLineGitdir, s:blameLineNsId ? funcref('s:nvimAnnotate') : funcref('s:vimEcho'))
endfunction

function! s:InitBlameLine()
    let b:onCursorMoved = !exists('*b:ToggleBlameLine') ? s:getCursorHandler() : s:createError('Blameline failed at init')
endfunction

function! s:SingleBlameLine()
    if !exists('*b:onCursorMoved')
        let b:onCursorMoved = s:createError('Blameline failed')
    endif
    call b:onCursorMoved(line('.'))
    augroup showBlameLine
        autocmd! CursorMoved <buffer> call s:DisableBlameLine()
    augroup END
endfunction

function! s:EnableBlameLine()
    if !exists('*b:onCursorMoved')
        let b:onCursorMoved = s:createError('Blameline failed')
    endif
    augroup showBlameLine
        autocmd CursorMoved <buffer> call b:onCursorMoved(line('.'))
    augroup END
    call b:onCursorMoved(line('.'))
    let b:ToggleBlameLine = function('s:DisableBlameLine')
endfunction

function! s:DisableBlameLine()
    call nvim_buf_clear_namespace(bufnr('%'), s:blameLineNsId, 0, -1)
    autocmd! showBlameLine * <buffer>
    let b:ToggleBlameLine = function('s:EnableBlameLine')
endfunction

augroup enableBlameLine
    autocmd!
    autocmd BufReadPre,FileReadPre * call s:InitBlameLine()
augroup END

command! ToggleBlameLine :call b:ToggleBlameLine()
command! EnableBlameLine :call s:EnableBlameLine()
command! DisableBlameLine :call s:DisableBlameLine()
command! SingleBlameLine :call s:SingleBlameLine()
