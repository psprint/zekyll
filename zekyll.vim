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
let s:cur_index = 1
let s:index_size = 0
let s:index_size_new = -1
let s:characters = [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
                 \   "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]

let s:after_zekyll_spaces = "    "
let s:after_section_spaces = "    "
let s:after_switch_spaces = "    "
let s:line_welcome = 1
let s:line_index = 2
let s:line_index_size = s:line_index
let s:line_apply = 3
let s:line_rule = 4
let s:last_line = s:line_rule

let s:lzsd = []

" ------------------------------------------------------------------------------
" s:StartZekyll: this function is available via the <Plug>/<script> interface above
fun! s:StartZekyll()
    " content here

    "nmap <silent> gf :set lz<CR>:silent! call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <silent> gf :set lz<CR>:call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <silent> <CR> :set lz<CR>:call <SID>ProcessBuffer()<CR>:set nolz<CR>
    nmap <silent> o :set lz<CR>:call <SID>ProcessBuffer()<CR>:set nolz<CR>
    imap <silent> <CR> <C-O>:call <SID>NoOp()<CR>

    setlocal buftype=nofile
    setlocal ft=help
    call s:Render()
endfun

" UI management functions {{{1
" FUNCTION: Render() {{{2
fun! s:Render()
    " save the view
    let savedLine = line(".")
    let savedCol = col(".")
    let zeroLine = line("w0")

    call s:ResetState()
    %d_

    call s:SetIndex(s:cur_index)
    call s:ReadRepo()
    let s:index_size = len(s:listing)
    call s:ParseListingIntoArrays()

    call setline(s:line_welcome, "Welcome to Zekyll Manager~")
    call setline(s:line_index, s:RPad("Current index: " . s:cur_index, 18) . "|" . " Index size: " . s:index_size )
    call setline(s:line_apply, s:RPad("Apply: no", 18) . "|")
    call setline(s:line_rule, "=========================")
    call cursor(s:last_line+1,1)

    let text = ""
    for entry in s:lzsd
        let desc = substitute( entry[3], "_", " ", "g" )
        let text = text . "|".entry[1]."|" . s:after_zekyll_spaces . "[x]" . s:after_switch_spaces . "*".entry[2]."*" . s:after_section_spaces . desc . "\n"
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
" 2}}}
" 1}}}
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
        if len( result ) < 2
            " Something's wrong, skip this line
            echom "Skipped processing of line: " . line
            continue
        end
        let zekylls_entry = result[1]

        " sections entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.\([A-Z]\).*' )
        let sections_entry = result[1]

        " descriptions entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.[A-Z]--\(.*\)' )
        let descriptions_entry = result[1]

        call add( s:lzsd, [ listing_entry, zekylls_entry, sections_entry, descriptions_entry ]  )
    endfor
endfun
" 2}}}
" FUNCTION: GoToFile() {{{2
fun! s:GoToFile()
    let result = s:BufferLineToZSD( getline( "." ) )
    let zekyll = result[0]
    let section = result[1]
    let description = substitute( result[2], " ", "_", "g" )

    let dir = substitute( s:cur_repo_path, '/$', "", "" )

    let file_name = zekyll.".".section."--".description
    exec "edit " . dir . "/" . file_name
endfun
" 2}}}
" FUNCTION: ProcessBuffer() {{{2
fun! s:ProcessBuffer()

    "
    " Read new index?
    "

    let line = getline( s:line_index )
    let result = matchlist( line, 'Current index:[[:space:]]*\(\d\+\)' )
    if len( result ) > 0
        if s:cur_index != result[1]
            let s:cur_index = result[1]
            call s:Render()
            return
        end
    end

    "
    " Perform changes? Apply is "yes"?
    "

    let line = getline( s:line_apply )
    let result = matchlist( line, 'Apply:[[:space:]]*\([a-zA-Z0-9]\+\)' )
    if len( result ) > 0
        if result[1] ==? "yes"
            " Continue below
        else
            echom "Set \"Apply:\" line to \"yes\" to write changes to disk"
            return
        end
    else
        echom "Improper document, control lines have been modified"
        return
    end

    " Compute reference to all operations - current buffer's LZSD
    let new_lzsd = s:BufferToLZSD()

    " Compute renames, removals, rewrite, index size change
    let lzsd2_renames = s:GatherSecDescChanges(new_lzsd)
    let lzsd_deleted = s:GatherDeletedEntries(new_lzsd)
    " cnss - current, new, string, string
    let cnss = s:ComputeNewZekylls(new_lzsd)
    let s:index_size_new = s:GetNewIndexSize()

    " Perform renames
    call s:Rename2LZSD( lzsd2_renames )

    " Perform removals
    call s:RemoveLZSD( lzsd_deleted )

    " Perform rewrite (order change)
    call s:RewriteZekylls( cnss[2], cnss[3] )

    " Perform index size change
    call s:IndexChangeSize()

    " Refresh buffer (e.g. set Apply back to "no")
    call s:Render()
endfun
" 2}}}
" FUNCTION: ResetState() {{{2
fun! s:ResetState()
    let s:lzsd = []
endfun
" 2}}}
" FUNCTION: NoOp() {{{2
fun! s:NoOp()
endfun
" 2}}}
" 1}}}
" Helper functions {{{1
" FUNCTION: BufferToLZSD() {{{2
fun! s:BufferToLZSD()
    "
    " Convert buffer into lzsd
    "

    let last_line = line( "$" )
    let i = s:last_line + 1
    let new_lzsd = []
    while i <= last_line
        let line = getline(i)
        let i = i + 1

        let result = s:BufferLineToZSD( line )
        if len( result ) > 0
            let zekyll = result[0]
            let section = result[1]
            let description = substitute( result[2], " ", "_", "g" )
            let file_name = zekyll . "." . section . "--" . description

            let new_entry = [ file_name, zekyll, section, description ]
            call add( new_lzsd, new_entry )
        end
    endwhile

    return new_lzsd
endfun
" 1}}}
" FUNCTION: GatherDeletedEntries() {{{2
fun! s:GatherDeletedEntries(new_lzsd)
    let deleted = []
    " Examine every entry that we started up with
    let size = len( s:lzsd )
    let i = 0
    while i < size
        let zekyll = s:lzsd[i][1]

        " Search for that zekyll in buffer content
        let size2 = len( a:new_lzsd )
        let j = 0
        let found = 0
        while j < size2
            if a:new_lzsd[j][1] == zekyll
                let found = 1
                break
            end
            let j = j + 1
        endwhile

        if found == 0
            let entry = [ s:lzsd[i][0], zekyll, s:lzsd[i][2], s:lzsd[i][3] ]
            call add( deleted, entry )
        end

        let i = i + 1
    endwhile

    " Message
    if 1
        let size = len( deleted )
        let i = 0
        let delstr = ""
        while i < size
            let delstr = delstr . deleted[i][1]
            let i = i + 1
        endwhile
        echom "Deleted: " . delstr
    end

    return deleted
endfun
" 2}}}
" FUNCTION: GatherSecDescChanges() {{{2
fun! s:GatherSecDescChanges(new_lzsd)
    "
    " Gather changes do sections and descriptions
    "

    let lzsd2_renames = []
    let size2 = len( s:lzsd )
    let size1 = len( a:new_lzsd )
    let i = 0
    while i < size1
        " Look for current zekyll in initial zekylls list
        let found = 0
        let j = 0
        while j < size2
            if s:lzsd[j][1] == a:new_lzsd[i][1]
                let found = 1
                break
            end
            let j = j + 1
        endwhile

        if found == 1
            let changed = 0

            " Section changed?
            if s:lzsd[j][2] != a:new_lzsd[i][2]
                echom "Something changed 1 " . s:lzsd[j][2] . " vs " . a:new_lzsd[i][2]
                let changed = 1
            end

            " Description changed?
            if s:lzsd[j][3] != a:new_lzsd[i][3]
                echom "Something changed 2 " . s:lzsd[j][3] . " vs " . a:new_lzsd[i][3]
                let changed = 2
            end

            if changed > 0
                let entryA = [ s:lzsd[j][0], s:lzsd[j][1], s:lzsd[j][2], s:lzsd[j][3] ]
                let entryB = [ a:new_lzsd[i][0], a:new_lzsd[i][1], a:new_lzsd[i][2], a:new_lzsd[i][3] ]
                call add( lzsd2_renames, [ entryA, entryB ] )
            end
        end

        let i = i + 1
    endwhile

    return lzsd2_renames
endfun
" FUNCTION: ComputeNewZekylls() {{{2
" This function is only a wrapper to slice on s:index_zekylls
" and produce useful data structures. This is because zekylls
" are always ordered and without holes, and for given buffer
" there can be only one sequence of zekylls
fun! s:ComputeNewZekylls(new_lzsd)
    let size = len( a:new_lzsd )
    let newer_zekylls = s:index_zekylls[0:size-1]

    let i = 0
    let current_zekylls=[]
    let str_current = ""
    let str_newer = ""
    while i < size
        call add( current_zekylls, a:new_lzsd[i][1] )
        let str_current = str_current . a:new_lzsd[i][1]
        let str_newer = str_newer . newer_zekylls[i]
        let i = i + 1
    endwhile

    "echom str_current
    "echom str_newer

    return [ current_zekylls, newer_zekylls, str_current, str_newer ]
endfun
" 2}}}
" FUNCTION: GetNewIndexSize() {{{2
fun! s:GetNewIndexSize()
    let line = getline( s:line_index_size )
    let result = matchlist( line, 'Index size:[[:space:]]*\(\d\+\)' )
    if len( result ) > 0
        let index_size_new = result[1]
        call s:DebugMsg( "Got new index size " . index_size_new )
    else
        let index_size_new = -1
        call s:DebugMsg( "Couldn't get index new size" )
    end
    return index_size_new
endfun
" 2}}}
" FUNCTION: DebugMsg() {{{2
fun! s:DebugMsg(...)
    if exists("g:zekyll_debug") && g:zekyll_debug == 1
        let argsize = len( a:000 )
        let a = 0
        while a < argsize
            if type(a:000[a]) == type("")
                echom a:000[a]
            end

            if type(a:000[a]) == type([])
                let size = len( a:000[a] )
                let i = 0
                while i < size
                    echom a:000[a][i]
                    let i = i + 1
                endwhile
            end

            let a = a + 1
        endwhile
    end
endfun
" 2}}}
" FUNCTION: SetIndex() {{{2
"
" Sets s:index_zekylls array which contains all
" zekylls that potentially can be part of the
" index
"
fun! s:SetIndex(index)
    let s:index_zekylls=[]

    " Compute first element pointed to by index
    let first=(a:index-1)*150

    let i=first
    while i <= (first+150-1)
        " Convert the number to base 36 with leading zeros
        let base36 = s:ConvertIntegerToBase36(i)
        call add( s:index_zekylls, base36 )
        let i = i + 1
        " echom base36 . " " . i
    endwhile
endfun
" Utility functions {{{1
" FUNCTION: BufferLineToZSD() {{{2
fun! s:BufferLineToZSD(line)
    let result = matchlist( a:line, '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '\[.\]' .
                            \ '[[:space:]]\+' . '\*\([A-Z]\)\*' . '[[:space:]]\+' . '\(.*\)$' )
    if len( result ) > 0
        let zekyll = result[1]
        let section = result[2]
        let description = substitute( result[3], " ", "_", "g" )
        return [ zekyll, section, description ]
    end
    return []
endfun
" FUNCTION: NumbersToLetters() {{{2
fun! s:NumbersToLetters(numbers)
    let result=""
    for i in a:numbers
        let result = result . s:characters[i]
    endfor
    return result
endfun
" FUNCTION: ConvertIntegerToBase36() {{{2
"
" Takes number in $1, returns string [a-z0-9]+
" that is representation of the number in base 36
"
fun! s:ConvertIntegerToBase36(number)
    let digits = []

    let new_number=a:number
    while new_number != 0
        let remainder=new_number%36
        let new_number=new_number/36

        call add( digits, remainder )
    endwhile

    if len( digits ) == 0
        call add( digits, 0 )
    end
    if len( digits ) == 1
        call add( digits, 0 )
    end
    if len( digits ) == 2
        call add( digits, 0 )
    end

    let digits_reversed=[]
    let size = len( digits )
    let i = size-1
    while i >= 0
        call add( digits_reversed, digits[i] )
        let i = i - 1
    endwhile

    return s:NumbersToLetters( digits_reversed )
endfun
" 2}}}
" FUNCTION: ConvertIntegerToBase36() {{{2
function! s:RPad(str, number)
    return a:str . repeat(' ', a:number - len(a:str))
endfunction
" 2}}}
" 1}}}
" Backend functions {{{1
" FUNCTION: ReadRepo {{{2
fun! s:ReadRepo()
    let listing_text = system( "zkiresize -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -i " . s:cur_index . " -q")
    let s:listing = split(listing_text, '\n\+')
endfun
" 2}}}
" FUNCTION: RewriteZekylls() {{{2
fun! s:RewriteZekylls(src_zekylls, dst_zekylls)
    let cmd = "zkrewrite --noansi -w -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -z " . a:src_zekylls . " -Z " . a:dst_zekylls
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    let cmd_output = join( arr, "\n" )

    call s:DebugMsg( "Command [" . v:shell_error . "]: " . cmd, arr )
endfun
" 2}}}
" FUNCTION: RemoveLZSD() {{{2
fun! s:RemoveLZSD(lzsd)
    let result = 0
    for entry in a:lzsd
        let entry[3] = substitute( entry[3], " ", "_", "g" )
        let file_name = entry[1] . "." . entry[2] . "--" . entry[3]
        let cmd = "cd " . shellescape( s:cur_repo_path ) . " && mv " . shellescape(file_name) . " _" . shellescape(file_name)
        call system( cmd )
        let result = result + v:shell_error
    endfor

    return result
endfun
" 1}}}
" FUNCTION: Rename2LZSD() {{{2
fun! s:Rename2LZSD(llzzssdd)
    let result = 0
    for entry in a:llzzssdd 
        let entry[0][3] = substitute( entry[0][3], " ", "_", "g" )
        let old_file_name = entry[0][1] . "." . entry[0][2] . "--" . entry[0][3]
        let new_file_name = entry[1][1] . "." . entry[1][2] . "--" . entry[1][3]
        let cmd = "git -C " . shellescape( s:cur_repo_path ) . " mv " . shellescape(old_file_name) . " " . shellescape(new_file_name)

        let cmd_output = system( cmd )
        let arr = split( cmd_output, '\n\+' )

        call s:DebugMsg( "Command [" . v:shell_error . "]: " . cmd, arr )
        let result = result + v:shell_error
    endfor

    return result
endfun
" 2}}}
" FUNCTION: IndexChangeSize() {{{2
fun! s:IndexChangeSize()
    if s:index_size == s:index_size_new
        return
    end

    let cmd = "zkiresize -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -i " . s:cur_index .
                \ " -q -w -n -s " . s:index_size_new . " --desc 'New Zekyll' --section A"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    let cmd_output = join( arr, "\n" )

    let error_decode = ""
    if v:shell_error == 1
        let error_decode = "Improper options"
    elseif v:shell_error == 2
        let error_decode = "Negative index size"
    elseif v:shell_error == 3
        let error_decode = "Maximum index size exceeded"
    elseif v:shell_error == 4
        let error_decode = "Repository doesn't exist"
    elseif v:shell_error == 5
        let error_decode = "Inconsistent index"
    elseif v:shell_error == 6
        let error_decode = "No size requested"
    elseif v:shell_error == 7
        let error_decode = "No change in index size"
    elseif v:shell_error == 8
        let error_decode = "No agreement to continue"
    elseif v:shell_error == 9
        let error_decode = "Improper section given"
    elseif v:shell_error == 10
        let error_decode = "Improper description given"
    elseif v:shell_error == 11
        let error_decode = "[inconsistent]"
    elseif v:shell_error == 12
        let error_decode = "[inconsistent-l]"
    end

    if error_decode != ""
        echom "Error occured: " . error_decode
    end

    call s:DebugMsg( "Command [" . v:shell_error . "]: " . cmd, arr, error_decode )
endfun
" 2}}}
" ------------------------------------------------------------------------------
let &cpo=s:keepcpo
unlet s:keepcpo

