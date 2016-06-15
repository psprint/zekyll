" ------------------------------------------------------------------------------
" Exit when your app has already been loaded (or "compatible" mode set)
if exists("g:loaded_zekyll") || &cp
    finish
endif

let g:loaded_zekyll = 1 " your version number
let s:keepcpo = &cpo
set cpo&vim

" Public Interface:
if !hasmapto('<Plug>StartZekyll')
    map <unique> <Leader>c <Plug>StartZekyll
endif

" Global Maps:
"
map <silent> <unique> <script> <Plug>StartZekyll :set lz<CR>:call <SID>StartZekyll()<CR>:set nolz<CR>

" Script Variables:
let s:cur_repo = "psprint/zkl"
let s:cur_repo_path = $HOME."/.zekyll/repos/psprint---zkl"
let s:repos_paths = [ $HOME."/.zekyll/repos" ]

let s:after_zekyll_spaces = "    "
let s:after_section_spaces = "    "

let s:lzsd = []

" ------------------------------------------------------------------------------
" s:StartZekyll: this function is available via the <Plug>/<script> interface above
fun! s:StartZekyll()
    " content here

    "nmap <silent> gf :set lz<CR>:silent! call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <silent> gf :set lz<CR>:call <SID>GoToFile()<CR>:set nolz<CR>

    setlocal buftype=nofile
    setlocal ft=help
    call s:render()
endfun

fun! s:render()
    " save the view
    let savedLine = line(".")
    let savedCol = col(".")
    let zeroLine = line("w0")

    call setline(1, "Welcome to Zekyll Manager")
    call setline(2, "=========================")
    call cursor(2,1)

    call s:ReadRepo()
    call s:ParseListingIntoArrays()

    let text = ""
    for entry in s:lzsd
        let text = text . entry[1] . s:after_zekyll_spaces . entry[2] . s:after_section_spaces . entry[3] . "\n"
    endfor

    let @l = text
    silent put l

    " restore the view
    let savedScrolloff=&scrolloff
    let &scrolloff=0
    call cursor(zeroLine, 1)
    normal! zt
    call cursor(savedLine, savedCol)
    let &scrolloff = savedScrolloff
endfun

" Functionality functions {{{1
" FUNCTION: InterfaceHeader() {{{2
fun! s:InterfaceHeader()
endfun
" 2}}}
" FUNCTION: ReadRepos() {{{2
fun! s:ReadRepos()
endfun
" 2}}}
" FUNCTION: OpenRepo() {{{2
fun! s:OpenRepo()
endfun
" 2}}}
" FUNCTION: OpenZekyll() {{{2
fun! s:OpenZekyll()
endfun
" 2}}}
" FUNCTION: ChangeDescriptionOfZekyll() {{{2
fun! s:ChangeDescriptionOfZekyll()
endfun
" 2}}}
" FUNCTION: ExchangeZekylls() {{{2
fun! s:ExchangeZekylls()
endfun
" 2}}}
" FUNCTION: AddZekyll() {{{2
fun! s:AddZekyll()
endfun
" 2}}}
" FUNCTION: DeleteZekyll() {{{2
fun! s:DeleteZekyll()
endfun
" 2}}}
" FUNCTION: ChangeZekyllsSection() {{{2
fun! s:ChangeZekyllsSection()
endfun
" 2}}}
" FUNCTION: SectionSortOrder() {{{2
fun! s:SectionSortOrder()
endfun
" 2}}}
" FUNCTION: ZekyllSortOrder() {{{2
fun! s:ZekyllSortOrder()
endfun
" 2}}}
" FUNCTION: CreateTag() {{{2
fun! s:CreateTag()
endfun
" 2}}}
" FUNCTION: CommitChanges() {{{2
fun! s:CommitChanges()
endfun
" 2}}}
" }}}
" Low level functions {{{1
" FUNCTION: {{{2
fun! s:ReadRepo()
    let listing_text = system( "zkiresize -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -i 1 -q")
    let s:listing = split(listing_text, '\n\+')
endfun
" 2}}}
" FUNCTION: ParseListingIntoArrays() {{{2
fun! s:ParseListingIntoArrays()
    for line in s:listing
        let listing_entry = ""
        let zekylls_entry = ""
        let sections_entry = ""
        let descriptions_entry = ""

        " Clear any path
        let path = substitute( s:cur_repo_path, '/$', "", "" )
        let line = substitute( line, '^' . s:cur_repo_path, "", "" )
        
        " Listing entry
        let listing_entry = line

        " zekylls entry
        let result = matchlist( line, '\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)\.[A-Z].*' )
        let zekylls_entry = "|".result[1]."|"

        " sections entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.\([A-Z]\).*' )
        let sections_entry = "*".result[1]."*"

        " descriptions entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.[A-Z]--\(.*\)' )
        let descriptions_entry = substitute( result[1], "[-]", " ", "g" )

        call add( s:lzsd, [ listing_entry, zekylls_entry, sections_entry, descriptions_entry ]  )
    endfor
endfun
" 2}}}
" FUNCTION: GoToFile() {{{2
fun! s:GoToFile()
    let line = getline(".")
    let result = matchlist( line, '|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|    \*\([A-Z]\)\*    \(.*\)' )
    let zekyll = result[1]
    let section = result[2]
    let description = substitute( result[3], " ", "-", "g" )

    let dir = substitute( s:cur_repo_path, '/$', "", "" )

    let file_name = zekyll.".".section."--".description
    exec "edit " . dir . "/" . file_name
endfun
" 2}}}
" 1}}}

" ------------------------------------------------------------------------------
let &cpo=s:keepcpo
unlet s:keepcpo

