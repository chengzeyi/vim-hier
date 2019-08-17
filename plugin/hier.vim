" hier.vim:		Highlight quickfix errors & Echo error message
" Last Modified: 2019 Aug 17
" Author:		Cheng Zeyi <ichengzeyi@gmail.com>
" Version:		1.0

if (exists("g:loaded_hier") && g:loaded_hier) || &cp
    finish
endif
let g:loaded_hier = 1

let g:hier_enabled = ! exists('g:hier_enabled') ? 1 : g:hier_enabled

let g:hier_echo_current_message = ! exists('g:hier_echo_current_message') ? 1 : g:hier_echo_current_message

let g:hier_highlight_group_qf = ! exists('g:hier_highlight_group_qf') ? 'SpellBad' : g:hier_highlight_group_qf
let g:hier_highlight_group_qfw = ! exists('g:hier_highlight_group_qfw') ? 'SpellLocal' : g:hier_highlight_group_qfw
let g:hier_highlight_group_qfi = ! exists('g:hier_highlight_group_qfi') ? 'SpellRare' : g:hier_highlight_group_qfi

let g:hier_highlight_group_loc = ! exists('g:hier_highlight_group_loc') ? 'SpellBad' : g:hier_highlight_group_loc
let g:hier_highlight_group_locw = ! exists('g:hier_highlight_group_locw') ? 'SpellLocal' : g:hier_highlight_group_locw
let g:hier_highlight_group_loci = ! exists('g:hier_highlight_group_loci') ? 'SpellRare' : g:hier_highlight_group_loci

if eval('g:hier_highlight_group_qf') != ''
    exec "hi! link QFError    ".g:hier_highlight_group_qf
endif
if eval('g:hier_highlight_group_qfw') != ''
    exec "hi! link QFWarning  ".g:hier_highlight_group_qfw
endif
if eval('g:hier_highlight_group_qfi') != ''
    exec "hi! link QFInfo     ".g:hier_highlight_group_qfi
endif

if eval('g:hier_highlight_group_loc') != ''
    exec "hi! link LocError   ".g:hier_highlight_group_loc
endif
if eval('g:hier_highlight_group_locw') != ''
    exec "hi! link LocWarning ".g:hier_highlight_group_locw
endif
if eval('g:hier_highlight_group_loci') != ''
    exec "hi! link LocInfo    ".g:hier_highlight_group_loci
endif

function! s:Getlist(winnr, type)
    if a:type == 'qf'
        return getqflist()
    else
        return getloclist(a:winnr)
    endif
endfunction

let s:hier_id2item = {}
function! s:Hier(clearonly)
    for m in getmatches()
        for h in ['QFError', 'QFWarning', 'QFInfo', 'LocError', 'LocWarning', 'LocInfo']
            if m.group == h
                call matchdelete(m.id)
            endif
        endfor
    endfor

    for lnum in keys(s:hier_id2item)
        call remove(s:hier_id2item, lnum)
    endfor

    if g:hier_enabled == 0 || a:clearonly == 1
        return
    endif

    let bufnr = bufnr('%')

    for type in ['qf', 'loc']
        for i in s:Getlist(0, type)
            if i.bufnr == bufnr
                let hi_group = 'QFError'
                if i.type == 'I' || i.type == 'info'
                    let hi_group = 'QFInfo'
                elseif i.type == 'W' || i.type == 'warning'
                    let hi_group = 'QFWarning'
                elseif eval('g:hier_highlight_group_'.type) == ""
                    continue
                endif

                if i.lnum > 0
                    let id = i.bufnr . i.lnum
                    let s:hier_id2item[id] = i
                    call matchadd(hi_group, '\%'.i.lnum.'l')
                elseif i.pattern != ''
                    call matchadd(hi_group, i.pattern)
                endif
            endif
        endfor
    endfor
endfunction

function! s:EchoMessage(message)
    let [old_ruler, old_showcmd] = [&ruler, &showcmd]

    let message = substitute(a:message, "\t", repeat(' ', &tabstop), 'g')
    let message = strpart(message, 0, winwidth(0)-1)
    let message = substitute(message, "\n", '', 'g')

    set noruler noshowcmd
    redraw

    echo message

    let [&ruler, &showcmd] = [old_ruler, old_showcmd]
endfunction

function! s:EchoCurrentMessage()
    let id = bufnr('%') . line('.')
    if !has_key(s:hier_id2item, id) | return | endif
    call s:EchoMessage(s:hier_id2item[id].text)
endfunction

command! -nargs=0 HierUpdate call s:Hier(0)
command! -nargs=0 HierClear call s:Hier(1)

command! -nargs=0 HierStart let g:hier_enabled = 1 | HierUpdate
command! -nargs=0 HierStop let g:hier_enabled = 0 | HierClear

command! -nargs=0 HierToggle let g:hier_enabled = !g:hier_enabled | call s:Hier(!g:hier_enabled)

augroup Hier
    au!
    au QuickFixCmdPost,BufEnter,WinEnter * :HierUpdate
    if g:hier_echo_current_message
        autocmd CursorMoved * call s:EchoCurrentMessage()
    endif
augroup END

