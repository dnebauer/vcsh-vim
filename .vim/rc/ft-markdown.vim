" Vim configuration: markdown file support

scriptencoding utf8  " required for C-Space mapping

function! s:MarkdownSupport()
    " only give feedback on first run    {{{1
    " - this function is run three times when opening vim with md file
    if exists('s:ran_previously') && s:ran_previously
        let l:first_run = 0
    else
        let l:first_run = 1
        let s:ran_previously = 1
    endif
    " tagbar support    {{{1
    " - from https://github.com/majutsushi/tagbar/wiki
    let l:bin = dn#rc#pluginsDir()
                \ . '/repos/github.com'
                \ . '/jszakmeister/markdown2ctags/markdown2ctags.py'
    if filereadable(l:bin)
        let g:tagbar_type_markdown = {
                    \ 'ctagstype'  : 'markdown',
                    \ 'ctagsbin'   : l:bin,
                    \ 'ctagsargs'  : '-f - --sort=yes',
                    \ 'kinds'      : ['s:sections', 'i:images'],
                    \ 'sro'        : '|',
                    \ 'kind2scope' : {'s' : 'section'},
                    \ 'sort'       : 0,
                    \ }
    endif
    " require pandoc for output generation    {{{1
    if l:first_run && !executable('pandoc')
        let l:msg = [ 'Cannot locate pandoc',
                    \ '- pandoc is needed to generate output',
                    \ '', ]
        call dn#rc#error(l:msg)
    endif
    " require pandoc-xnos filter suite for output generation    {{{1
    if l:first_run
        let l:filters = ['pandoc-eqnos', 'pandoc-fignos', 'pandoc-secnos',
                    \    'pandoc-tablenos', 'pandoc-xnos']
        let l:missing = []
        for l:filter in l:filters
            if !executable(l:filter)
                call add(l:missing, l:filter)
            endif
        endfor
        if !empty(l:missing)
            let l:msg = [ 'Cannot find entire pandoc-xnos filter suite',
                        \ '- missing: ' . join(l:missing, ', '),
                        \ '- this filter suite is used for cross-referencing',
                        \ '', ]
            call dn#rc#error(l:msg)
        endif
    endif
    " configure plugins vim-pandoc[-{syntax,after}]    {{{1
    let g:pandoc#filetypes#handled         = ['pandoc', 'markdown']
    let g:pandoc#filetypes#pandoc_markdown = 0
    let g:pandoc#after#modules#enabled     = ['neosnippet']
    let g:pandoc#modules#enabled           = [
                \ 'formatting', 'folding', 'command',
                \ 'keyboard',   'yaml',    'completion',
                \ 'toc',        'hypertext']
    let g:pandoc#formatting#mode                            = 'h'
    let g:pandoc#formatting#smart_autoformat_on_cursormoved = 1
    let g:pandoc#command#latex_engine                       = 'xelatex'
    let g:pandoc#command#custom_open    = 'dn#rc#pandocOpen'
    let g:pandoc#command#prefer_pdf     = 1
    let g:pandoc#command#templates_file = dn#rc#vimPath('home')
                \ . '/vim-pandoc-templates'
    let g:pandoc#compiler#command = 'panzer'
    let g:pandoc#compiler#arguments
                \ = ' ---quiet'
                \ . ' ---panzer-support="' . dn#rc#panzerPath() . '"'
    " insert hard space    {{{1
    " - map unicode non-breaking space to C-Space
    " - would prefer C-S-Space but terminal vim has a problem with mapping it
    "   (see https://vi.stackexchange.com/a/13329 for details)
    inoremap <buffer><silent><C-Space>  
    " improve sentence text object    {{{1
    call textobj#sentence#init()
    " add system dictionary to word completions    {{{1
    setlocal complete+=k
    " vim omnicompletion    {{{1
    if !has('nvim')
        setlocal omnifunc=htmlcomplete#CompleteTags
    endif
    " customise surround.vim plugin    {{{1
    " - strong emphasis (b)    {{{2
    let b:surround_98 = "__\r__"
    " - emphasis (i)    {{{2
    let b:surround_105 = "_\r_"
    " - inline code (`)    {{{2
    let b:surround_96 = "`\r`"
    " rewrap paragraph using <M-q>, i.e., Alt-q    {{{1
    " - linux terminal key codes for <M-q> not recognised by vim
    " - get terminal key codes using 'cat' or 'sed -n l'
    " - konsole key codes for <M-q> are 'q'
    " - '' is an escape entered in vim with <C-v> then <Esc>
    " - '' is represented in 'set' command with '\<Esc>'
    if has('unix') | execute "set <M-q>=\<Esc>q" | endif
    nnoremap <silent> <M-q> {gq}<Bar>:echo "Rewrapped paragraph"<CR>
    inoremap <silent> <M-q> <Esc>{gq}<CR>a
    " change filetype to trigger vim-pandoc plugin    {{{1
    set filetype=markdown.pandoc    " }}}1
endfunction

augroup vrc_markdown_files
    autocmd!
    autocmd FileType markdown call s:MarkdownSupport()
augroup END

" vim:foldmethod=marker:
