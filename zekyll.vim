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
let s:cur_repo_path = fnameescape( $HOME )."/.zekyll/repos/psprint---zkl"
let s:repos_paths = [ fnameescape( $HOME )."/.zekyll/repos" ]

let s:lzsd = []
let s:listing = []
let s:inconsistent_listing = []

let s:cur_index = 1
let s:prev_index = -1
let s:index_size = -1
let s:index_size_new = -1

let s:consistent = "yes"
let s:are_errors = "no"
let s:save = "no"
let s:do_reset = "no"

let s:working_area_beg = 1
let s:working_area_end = 1

let s:longest_lzsd = 0

let s:code_selectors = []
let s:characters = [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
                 \   "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" ]


let s:after_zekyll_spaces = "    "
let s:after_section_spaces = "    "
let s:after_switch_spaces = "    "

let s:beg_of_warea_char = '-'
let s:end_of_warea_char = '-'

let s:line_welcome = 2
let s:line_consistent   = 4
let s:line_errors       = 4
let s:line_index        = 5
let s:line_reset        = 5
let s:line_code         = 6
let s:line_code2        = 6
let s:line_save         = 7
let s:line_index_size   = 7
let s:line_rule         = 8
let s:last_line = s:line_rule

let s:messages = [ ]

let s:savedLine = 1
let s:savedCol = 1
let s:zeroLine = 1

let s:pat_ZSD             = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<.>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_ZCSD            = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<\(.\)>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_Index_Reset     = 'Current index:[[:space:]]*<\?\(\d\+\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                            \ '\[[[:space:]]\+Reset:[[:space:]]*<\?\([a-zA-Z]\+\)>\?'

let s:pat_Save_IndexSize  = 'Save[[:blank:]]\+(\?<\?\([a-zA-Z]\+\)>\?)\?[[:blank:]]\+with[[:blank:]]\+index[[:blank:]]\+size[[:blank:]]\+<\?\([0-9]\+\)>\?'

let s:ACTIVE_NONE = 0
let s:ACTIVE_CURRENT_INDEX = 1
let s:ACTIVE_CODE = 2
let s:ACTIVE_SAVE_INDEXSIZE = 3
let s:ACTIVE_RESET = 4

" ------------------------------------------------------------------------------
" s:StartZekyll: this function is available via the <Plug>/<script> interface above
fun! s:StartZekyll()
    call s:Opener()

    call s:DoMappings()

    call s:DeepRender()
endfun

" UI management functions {{{1
" depth - how much should be rendered
"         0 - nothing, just some data gathered from buffer
"         1 - whole content but without reading from disk
"         2 - whole content after reading from disk
" FUNCTION: NormalRender() {{{2
fun! s:NormalRender( ... )
    let depth = 1
    if a:0 == 1
        let depth = a:1
    end

    call s:SaveView()

    call s:ResetState( depth )

    if depth >= 2
        call s:SetIndex(s:cur_index)
        call s:ReadRepo()
        let s:index_size = len(s:listing)
        call s:ParseListingIntoArrays()
        let s:longest_lzsd = s:LongestLZSD( s:lzsd )
    end

    " s:index_size_new holds value that corresponds to buffer
    " When first creating buffer we predict what the value will
    " be and set it to s:index_size
    if s:index_size_new == -1
        let s:index_size_new = s:index_size
    end

    if depth >= 1
        silent %d_
        call setline( s:line_welcome-1, ">" )
        call setline( s:line_welcome,   "     Welcome to Zekyll Manager" )
        if s:consistent ==? "no" || s:are_errors ==? "yes"
            call setline( s:line_welcome+1, ">" )
            let s:prefix = " "
        else
            call setline( s:line_welcome+1, "" )
            let s:prefix = ""
        end
        call setline( s:line_consistent, s:RPad( s:prefix . "Consistent: " . s:consistent, 22 ) . " | " . "Errors: " . s:are_errors )
        call setline( s:line_index,      s:GenerateIndexResetLine() )
        call setline( s:line_code,               "Code: .......  ~" )
        call setline( s:line_save,       s:GenerateSaveIndexSizeLine() )
        call setline( s:line_rule,       s:GenerateRule( 1 ) )
        call cursor(s:last_line+1,1)

        let text = ""
        for entry in s:lzsd
            let text = text . s:BuildLineFromFullEntry( entry )
        endfor

        let text = s:SetupSelectionCodes( text )
        let text = text . s:GenerateRule( 0 )

        let @l = text
        silent put l

    end

    if depth >= 0
        " Code line
        let resu = s:encode_zcode_arr01( reverse( copy(s:code_selectors) ) )
        call setline( s:line_code, s:GenerateCodeLine( resu[1] ) )

        let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
        call cursor(s:working_area_end+1,1)
        if line(".") != s:working_area_end+1 
            call setline(s:working_area_end+1, "")
            call cursor(s:working_area_end+1,1)
        end
        normal! dG
        call s:OutputMessages(1)
    end

    call s:RestoreView()
endfun
" 2}}}
" FUNCTION: ShallowRender() {{{2
fun! s:ShallowRender()
    return s:NormalRender(0)
endfun
" 2}}}
" FUNCTION: DeepRender() {{{2
fun! s:DeepRender()
    return s:NormalRender(2)
endfun
" 2}}}
" 1}}}
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
        if len( result ) == 0
            call s:DebugMsgT( 1, " Skipped processing of improper line: " . line )
            let s:are_errors = "YES"
            continue
        end
        let zekylls_entry = result[1]

        " sections entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.\([A-Z]\).*' )
        if len( result ) == 0
            call s:DebugMsgT( 1, " Skipped processing of improper line: " . line )
            let s:are_errors = "YES"
            continue
        end
        let sections_entry = result[1]

        " descriptions entry
        let result = matchlist( line, '[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\.[A-Z]--\(.*\)' )
        if len( result ) == 0
            call s:DebugMsgT( 1, " Skipped processing of improper line: " . line )
            let s:are_errors = "YES"
            continue
        end
        let descriptions_entry = result[1]

        call add( s:lzsd, [ listing_entry, zekylls_entry, sections_entry, descriptions_entry ]  )
    endfor
endfun
" 2}}}
" FUNCTION: GoToFile() {{{2
fun! s:GoToFile()
    call s:SaveView()
    let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
    call s:RestoreView()

    let line = line( "." )
    if line <= s:working_area_beg || line >= s:working_area_end
        return 0
    end

    let result = s:BufferLineToZSD( getline( "." ) )
    if len( result ) > 0
        let zekyll = result[0]
        let section = result[1]
        let description = substitute( result[2], " ", "_", "g" )

        let dir = substitute( s:cur_repo_path, '/$', "", "" )

        let file_name = zekyll . "." . section . "--" . description
        exec "edit " . dir . "/" . file_name

        return 1
    end

    return 0
endfun
" 2}}}
" FUNCTION: ProcessBuffer() {{{2
fun! s:ProcessBuffer( active )


    call s:SaveView()
    let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
    call s:RestoreView()

    "
    " Reset ?
    "

    if a:active == s:ACTIVE_RESET
        let result = matchlist( getline( s:line_reset ), s:pat_Index_Reset )
        if len( result ) > 0
            if result[2] ==? "yes"
                let s:do_reset = "no"
                call s:ResetRepo()
                call s:DeepRender()
                return
            end
        else
            call s:AppendMessageT( "*Error:* control lines modified, cannot use document - will regenerate (1)" )
            call s:NormalRender()
            return
        end
    end

    "
    " Read new index?
    "

    if a:active == s:ACTIVE_CURRENT_INDEX
        let result = matchlist( getline( s:line_index ), s:pat_Index_Reset )
        if len( result ) > 0
            if s:cur_index != result[1]
                let s:cur_index = result[1]
                call s:ResetCodeSelectors()
                call s:DeepRender()
                return
            end
        else
            call s:AppendMessageT( "*Error:* control lines modified, cannot use document - will regenerate (1)" )
            call s:NormalRender()
            return
        end
    end

    "
    " Perform changes? Save is "yes"?
    "

    if a:active == s:ACTIVE_SAVE_INDEXSIZE
        let result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize )
        if len( result ) > 0
            if result[1] ==? "yes"
                " Continue below
            else
                call s:AppendMessageT(" Set \"Save:\" or \"Reset:\" field to <yes> to write changes to disk or to reset Git repository")
                call s:ShallowRender()
                return
            end
        else
            call s:AppendMessageT( "*Error:* control lines modified, cannot use document - will regenerate (2)" )
            call s:NormalRender()
            return
        end
    end

    " Compute reference to all operations - current buffer's LZSD
    let [ new_lzsd, error ] = s:BufferToLZSD()

    if( error == 0 )
        " Compute renames, removals, rewrite, codes change, index size change
        let lzsd2_renames = s:GatherSecDescChanges(new_lzsd)
        let lzsd_deleted = s:GatherDeletedEntries(new_lzsd)
        " cnss - current, new, string, string
        let cnss = s:ComputeNewZekylls(new_lzsd)
        " Read buffer looking for state of Code Switches (codes)
        call s:ReadCodes()
        " Parse new index size
        let s:index_size_new = s:GetNewIndexSize()

        " Perform renames
        call s:Rename2LZSD( lzsd2_renames )

        " Perform removals
        call s:RemoveLZSD( lzsd_deleted )

        " Perform rewrite (order change)
        call s:RewriteZekylls( cnss[2], cnss[3] )

        " Perform index size change
        call s:IndexChangeSize()
    else
        call s:AppendMessageT("*Errors* during data processing, rereading state from disk")
    end

    " Refresh buffer (e.g. set Save back to "no")
    call s:DeepRender()
endfun
" 2}}}
" FUNCTION: ResetState() {{{2
fun! s:ResetState( ... )
    let depth = 0
    if a:0 == 1
        let depth = a:1
    end

    if depth >= 2
        let s:lzsd = []
        let s:listing = []
        let s:inconsistent_listing = []
        let s:index_size = -1
        let s:index_size_new = -1
        let s:consistent = "yes"
        let s:are_errors = "no"
        let s:do_reset = "no"
    end
endfun
" 2}}}
" FUNCTION: NoOp() {{{2
fun! s:NoOp()
    return 0
endfun
" 2}}}
" 1}}}
" Helper functions {{{1
" Will skip lines that arent proper
" FUNCTION: BufferToLZSD() {{{2
fun! s:BufferToLZSD()
    "
    " Convert buffer into lzsd
    "

    let error = 0
    let last_line = s:working_area_end - 1
    let i = s:working_area_beg + 1
    let new_lzsd = []
    while i <= last_line
        let line = getline(i)

        let result = s:BufferLineToZSD( line )
        if len( result ) > 0
            let zekyll = result[0]
            let section = result[1]
            let description = substitute( result[2], " ", "_", "g" )
            let file_name = zekyll . "." . section . "--" . description

            let new_entry = [ file_name, zekyll, section, description ]
            call add( new_lzsd, new_entry )
        else
            call s:AppendMessageT( "*Problem* occured in line {#" . i . "}. The problematic line: >", [ "  " . line ] )
            let s:are_errors = "YES"
            let error = 1
        end

        let i = i + 1
    endwhile

    return [ new_lzsd, error ]
endfun
" 1}}}
" FUNCTION: BufferToLZCSD() {{{2
fun! s:BufferToLZCSD()
    "
    " Convert buffer into lzsd
    "

    let last_line = line( "$" )
    let i = s:last_line + 1
    let new_lzcsd = []
    while i <= last_line
        let line = getline(i)
        let i = i + 1

        let result = s:BufferLineToZCSD( line )
        if len( result ) > 0
            let zekyll = result[0]
            let codes = result[1]
            let section = result[2]
            let description = substitute( result[3], " ", "_", "g" )
            let file_name = zekyll . "." . section . "--" . description

            let new_entry = [ file_name, zekyll, codes, section, description ]
            call add( new_lzcsd, new_entry )
        end
    endwhile

    return new_lzcsd
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
                let changed = 1
            end

            " Description changed?
            if s:lzsd[j][3] != a:new_lzsd[i][3]
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
    let result = matchlist( line, s:pat_Save_IndexSize )
    if len( result ) > 0
        let index_size_new = result[2]
    else
        let index_size_new = -1
    end
    return index_size_new
endfun
" 2}}}
" FUNCTION: DebugMsgT() {{{2
" Prepends current time in format *HH:MM* to first line
" The first line must be thus a string. It will be appended
" to s:messages here, rest will be routed to s:DebugMsgT()
fun! s:DebugMsgT( is_error, ... )
    " zekyll_debug == 1 - log level 1, will be displayed when is_error == true
    " zekyll_debug > 1 - log level 2, will be displayed also for is_error == false
    if exists("g:zekyll_debug") && ( (g:zekyll_debug == 1 && a:is_error > 0) || g:zekyll_debug > 1 )
        if len( a:000 ) > 0
            " Message pack
            let pack = []

            if exists("*strftime")
                let T = "*".strftime("%H:%M")."* "
            else
                let T = ""
            end

            " Case 1: first argument is a string, following can be list
            if type( a:000[0] ) == type( "" )
                " Remaining arguments, e.g. list
                let remaining = deepcopy( a:000 )
                let remaining = remaining[1:] 

                let B=""
                if len( remaining ) > 0 && type( remaining[0] ) == type( [] )
                    let B=" >"
                    call map( remaining[0], '"  " . v:val' )
                end

                " One place here where pack is addressed directly
                call add( pack, T . a:000[0] . B )

                if len( remaining ) > 0
                    call s:DebugMsgReal( a:is_error, pack, remaining )
                end
            " Case 2: list is first argument
            elseif len( a:000 ) > 0 && type( a:000[0] ) == type( [] )
                let all = deepcopy( a:000 )
                if len( all[0] ) > 0
                    let skipfirst = all[0][1:]
                    let B2 = ""
                    if len( skipfirst ) > 0
                        call map( skipfirst, '"  " . v:val' )
                        let all[0][1:] = skipfirst
                        let all[0][0] = all[0][0] . " >"
                    end

                    call s:DebugMsgReal( a:is_error, pack, all )
                end
            " Case 3: don't interfere with unrecognized content, just display
            else
                call s:DebugMsgReal( a:is_error, pack, a:000 )
            end
        end
    end
endfun
" 2}}}
" FUNCTION: DebugMsgReal() {{{2
fun! s:DebugMsgReal( is_error, pack, ZERO )
    if exists("g:zekyll_debug") && ( (g:zekyll_debug == 1 && a:is_error > 0) || g:zekyll_debug > 1 )
        let argsize = len( a:ZERO )
        let a = 0
        while a < argsize
            if type( a:ZERO[a] ) == type( "" ) && len( a:ZERO[a] ) > 0
                call add( a:pack, a:ZERO[a] )
            end

            if type(a:ZERO[a]) == type([])
                let size = len( a:ZERO[a] )
                let i = 0
                while i < size
                    call add( a:pack, a:ZERO[a][i] )
                    let i = i + 1
                endwhile
            end

            let a = a + 1
        endwhile

        call add( s:messages, a:pack )
    end
endfun
" 2}}}
" FUNCTION: OutputMessages() {{{2
fun! s:OutputMessages( delta )
    if !exists("g:zekyll_messages") || g:zekyll_messages == 1
        let last_line = line( "$" )

        let a = 1
        while a <= a:delta
            let last_line = last_line + 1
            call setline( last_line, "" )
            let a = a + 1
        endwhile

        let last_line = last_line + 1
        call setline( last_line, "<Messages>" )
        let msgsize = len( s:messages )
        let a = 0
        while a < msgsize
            let pack = s:messages[msgsize-a-1]

            let frst = 1
            for p in pack
                let last_line = last_line + 1
                if frst
                    let line = "{" . (msgsize-a) . "}" . p
                    call setline( last_line, line )
                    let frst = 0
                else
                    call setline( last_line, p )
                end
            endfor

            let a = a + 1
        endwhile
    end
endfun
" 2}}}
" FUNCTION: AppendMessageT() {{{2
" Prepends current time in format *HH:MM* to first line
" The first line must be thus a string. It will be appended
" to s:messages here, rest will be routed to s:AppendMessage()
fun! s:AppendMessageT(...)
    if !exists("g:zekyll_messages") || g:zekyll_messages == 1
        " Message pack
        if len( a:000 ) > 0
            let pack = []
            " Pre-process first element if it's string
            if type(a:000[0]) == type("")
                if exists("*strftime")
                    let T = "*".strftime("%H:%M")."* "
                else
                    let T = ""
                end
                call add( pack, T . a:000[0] )
                let remaining = copy(a:000)
                let remaining = remaining[1:] 
                call s:AppendMessageReal( pack, remaining )
            else
                " No pre-processing
                call s:AppendMessageReal( pack, a:000 )
            end
        end
    end
endfun
" 2}}}
" FUNCTION: AppendMessage() {{{2
fun! s:AppendMessage(...)
    " Message pack
    let pack = []
    call s:AppendMessageReal( pack, a:000 )
endfun
" 2}}}
" FUNCTION: AppendMessageReal() {{{2
fun! s:AppendMessageReal( pack, ZERO )
    if exists("g:zekyll_messages") == 0 || g:zekyll_messages == 1
        let argsize = len( a:ZERO )
        let a = 0
        while a < argsize
            if type(a:ZERO[a]) == type("")
                call add( a:pack, a:ZERO[a] )
            end

            if type(a:ZERO[a]) == type([])
                let size = len( a:ZERO[a] )
                let i = 0
                while i < size
                    call add( a:pack, a:ZERO[a][i] )
                    let i = i + 1
                endwhile
            end

            let a = a + 1
        endwhile

        " Store the message pack
        call add( s:messages, a:pack )
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
" 2}}}
" FUNCTION: ResetCodeSelectors() {{{2
" Sets code selectors to default state,
" in number corresponding to len( s:lzsd )
fun! s:ResetCodeSelectors()
    let s:code_selectors = []
    let size = len( s:lzsd )
    let i = 0
    while i < size
        call add( s:code_selectors, 1 )
        let i = i + 1
    endwhile
endfun
"2}}}
" FUNCTION: GatherCodeSelectors() {{{2
" Sets s:code_selectors from the buffer
fun! s:GatherCodeSelectors()
endfun
" 2}}}
" FUNCTION: GenerateSaveIndexSizeLine() {{{2
fun! s:GenerateSaveIndexSizeLine()
    return "[ Save (<" . s:save . ">) with index size <" . s:index_size_new . "> ]"
endfun
" 2}}}
" FUNCTION: GenerateIndexResetLine() {{{2
fun! s:GenerateIndexResetLine()
    let line = s:RPad( "[ Current index: <" . s:cur_index . ">", 20) . " ] | " . "[ Reset: <" . s:do_reset . ">"
    if s:do_reset ==? "yes"
        let line = line . " ]"
    else
        let line = line . "  ]"
    end
    return line
endfun
" 2}}}
" FUNCTION: GenerateCodeLine() {{{2
fun! s:GenerateCodeLine( code )
    return "[ Code:." . s:cur_index . "/" . s:RPad( a:code, 29, "." ) . " ] ~"
endfun
" 2}}}
" FUNCTION: IsEditAllowed() {{{2
fun! s:IsEditAllowed()
    let col = col( "." )
    return col == 18 || col >= 24
endfun
" 2}}}
" FUNCTION: Opener() {{{2
fun! s:Opener()
    let retval = 0
    if !exists("g:_zekyll_bufnr") || g:_zekyll_bufnr == -1
        tabnew
        exec "lcd " . fnameescape( $HOME ) . "/.zekyll"
        exec "file Zekyll\\ Manager"
        let g:_zekyll_bufname = bufname("%")
        let g:_zekyll_bufnr = bufnr("%")
        let retval = 1
    else
        " Try current tab
        let [winnr, all] = s:FindOurWindow( g:_zekyll_bufnr )
        if all > 0
            call s:AppendMessageT( " Welcome back! Using current tab" )
            exec winnr . "wincmd w"
            let retval = 1
        else
            " Try other tab
            let tabpagenr = s:FindOurTab( g:_zekyll_bufnr )
            if tabpagenr != -1
                exec 'normal! ' . tabpagenr . 'gt'
                let [winnr, all] = s:FindOurWindow( g:_zekyll_bufnr )
                if all > 0
                    call s:AppendMessageT( " Welcome back! Switched to already used tab" )
                    exec  winnr . "wincmd w"
                    let retval = 1
                else
                    call s:AppendMessageT( " Unexpected *error* occured, running second instance of Zekyll" . winnr )
                    let retval = 0
                end
            else
                tabnew
                exec ":silent! buffer " . g:_zekyll_bufnr
                call s:AppendMessageT(" Welcome back! Restored our buffer")
                let retval = 1
            end
        end
    end

    return retval
endfun
" 2}}}
" FUNCTION: DoMappings() {{{2
fun! s:DoMappings()
    "nmap <buffer> <silent> gf :set lz<CR>:silent! call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <buffer> <silent> gf :set lz<CR>:call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <buffer> <silent> <C-]> :set lz<CR>:call <SID>GoToFile()<CR>:set nolz<CR>
    nmap <buffer> <silent> <CR> :set lz<CR>:call <SID>Enter()<CR>:set nolz<CR>
    nnoremap <buffer> <space> :call <SID>Space()<CR>

    nmap <buffer> <silent> o <Nop>
    "nmap <buffer> <silent> p <Nop>
    "nmap <buffer> <silent> P <Nop>
    nmap <buffer> <silent> y <Nop>
    nmap <buffer> <silent> Y <Nop>
    :noremap <silent> <expr> p @" != "" ? 'p:let @"=""<cr>' : ""
    :noremap <silent> <expr> P @" != "" ? 'P:let @"=""<cr>' : ""
    nmap <buffer> <silent> D <Nop>
    nmap <buffer> <silent> v <Nop>

    vmap <buffer> <silent> p <Nop>
    vmap <buffer> <silent> P <Nop>
    vmap <buffer> <silent> D <Nop>

    imap <buffer> <silent> <CR> <Nop>

    setlocal buftype=nofile
    setlocal ft=help
    setlocal wrap

    " Latin, todo few special characters
    for i in range( char2nr('0'), char2nr('[') )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    for i in range( char2nr(']'), char2nr('{') )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    inoremap <buffer> <expr> } <SID>IsEditAllowed() ? "}" : ""

    " Greek and Coptic 0x370 0x3FF
    for i in range( 880, 1023 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    " Cyrillic 0x400 0x4FF
    for i in range( 1024, 1279 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    " Cyrillic Supplementary 0x500 - 0x52F
    for i in range( 1280, 1327 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    " Armenian 0x530 0x58F
    for i in range( 1328, 1423 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    " Hebrew 0x590 0x5FF
    for i in range( 1424, 1535 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    " Arabic 0x600 0x6FF
    for i in range( 1536, 1791 )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    if exists("g:zekyll_cjk") && g:zekyll_cjk == 1
        " CJK Unified Ideographs Extension A 0x3400 0x4DBF
        for i in range( 13312, 19903 )
            exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
        endfor
    end

    exec 'inoremap <buffer> <expr> ' . nr2char(8211) . ' <SID>IsEditAllowed() ? "' . nr2char(8211) . '" : ""'
endfun
" 2}}}
" FUNCTION: Enter() {{{2
fun! s:Enter()
    call s:SaveView()
    let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
    call s:RestoreView()

    let linenr = line( "." )
    let line = getline( linenr )
    if linenr <= s:working_area_beg 
        let line2 = substitute( line, '[^|]', "x", "g" )
        let col = col( "." )
        let pos = stridx( line2, "|" ) + 1
        if pos == -1
            return 0
        end

        if linenr == s:line_index
            if col < pos
                call s:ProcessBuffer( s:ACTIVE_CURRENT_INDEX )
            else
                call s:ProcessBuffer( s:ACTIVE_RESET )
            end
            return 1
        elseif linenr == s:line_code
            " TODO
        elseif linenr == s:line_save
            call s:ProcessBuffer( s:ACTIVE_SAVE_INDEXSIZE )
            return 1
        end

        return 0
    elseif linenr < s:working_area_end
       return s:GoToFile()
    end
endfun
" 2}}}
"1}}}
" Utility functions {{{1
" FUNCTION: DiscoverWorkArea() {{{2
" This function is needed to not rely on remembered numbers of lines
" denoting where working area starts. This is needed because e.g. an
" user might, just to check program's robustness, enter some new line
" to see what happens.
" Cursor position is saved, we can move it
fun! s:DiscoverWorkArea()
    let rule_beg = s:GenerateRule(1, -10)
    let rule_end = s:GenerateRule(0, -10)
    normal! G$
    let [lnum_beg, col_beg] = searchpos(rule_beg, 'w')
    let [lnum_end, col_end] = searchpos(rule_end, 'W')

    return [ lnum_beg, lnum_end ]
endfun
" 2}}}
" FUNCTION: BufferLineToZSD() {{{2
fun! s:BufferLineToZSD(line)
    let result = matchlist( a:line, s:pat_ZSD )
    if len( result ) > 0
        let zekyll = result[1]
        let section = result[2]
        let description = substitute( result[3], " ", "_", "g" )
        return [ zekyll, section, description ]
    end
    return []
endfun
" FUNCTION: BufferLineToZCSD() {{{2
" The same as BufferLineToZSD but also
" returns state of code selector
fun! s:BufferLineToZCSD(line)
    let result = matchlist( a:line, s:pat_ZCSD )
    if len( result ) > 0
        let zekyll = result[1]
        let codes = result[2]
        let section = result[3]
        let description = substitute( result[4], " ", "_", "g" )
        return [ zekyll, codes, section, description ]
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
" FUNCTION: RPad() {{{2
function! s:RPad(str, number, ...)
    if len(a:000) > 0 && type( a:000[0] ) == type( ' ' )
        return a:str . repeat(a:000[0], a:number - len(a:str))
    else
        return a:str . repeat(' ', a:number - len(a:str))
    end
endfunction
" 2}}}
" FUNCTION: LongestLZSD() {{{2
fun! s:LongestLZSD( lzsd )
    let size = len( a:lzsd )
    let longest = 0
    let i = 0
    while i < size
        let line = s:BuildLineFromFullEntry( a:lzsd[i] )
        let len = len( line )
        if longest < len
            let longest = len
        end
        let i = i + 1
    endwhile
    return longest
endfun
" 2}}}
" FUNCTION: BuildLineFromFullEntry() {{{2
fun! s:BuildLineFromFullEntry(entry, ...)
    let selector = "x"
    if a:0 > 0
        if a:1 == 1
            let selector = "x"
        else
            let selector = " "
        end
    end

    let desc = substitute( a:entry[3], "_", " ", "g" )
    let text = "|".a:entry[1]."|" . s:after_zekyll_spaces . "<" . selector . ">" . s:after_switch_spaces .
                    \ "*".a:entry[2]."*" . s:after_section_spaces . desc . "\n"
    return text
endfun
" 2}}}
" FUNCTION: ZSDToListing() {{{2
fun! s:ZSDToListing( zsd )
    let a:zsd[2] = substitute( a:zsd[2], " ", "_", "g" )
    let listing = a:zsd[0] . "." . a:zsd[1] . "--" . a:zsd[2]
    return listing
endfun
" 2}}}
" FUNCTION: SetupSelectionCodes() {{{2
" Here we have LZSD that is from buffer recreated after disk operations
fun! s:SetupSelectionCodes( text )
    if s:prev_index != s:cur_index
        call s:ResetCodeSelectors()
    elseif len( s:code_selectors ) > len( s:lzsd )
        let s:code_selectors = s:code_selectors[0:len(s:lzsd)-1]
    elseif len( s:code_selectors ) < len( s:lzsd )
        let diff = len( s:lzsd ) - len( s:code_selectors )
        let i = 0
        while i < diff
            call add( s:code_selectors, 1 )
            let i = i + 1
        endwhile
    end

    let s:prev_index = s:cur_index

    let text2 = ""
    let arr = split( a:text, '\n\+' )
    let size = len( arr )
    let i = 0
    while i < size
        let ZCSD = s:BufferLineToZCSD( arr[i] )
        let listing = s:ZSDToListing( s:ZcsdToZsd( ZCSD ) )
        let line = s:BuildLineFromFullEntry( s:ZcsdToLzds( ZCSD, listing ), s:code_selectors[i] )
        let text2 = text2 . line
        let i = i + 1
    endwhile

    return text2
endfun
" 2}}}
" FUNCTION: LzcsdToLzsd() {{{2
fun! s:LzcsdToLzsd( lzcsd )
    if len( a:lzcsd ) == 5
        return [ a:lzcsd[0], a:lzcsd[1], a:lzcsd[3], a:lzcsd[4] ]
    else
        return []
    end
endfun
" 2}}}
" FUNCTION: ZcsdToZsd() {{{2
" Strips off "C" (codes-elector) from Zcsd
fun! s:ZcsdToZsd( zcsd )
    if len( a:zcsd ) == 4
        return [ a:zcsd[0], a:zcsd[2], a:zcsd[3] ]
    else
        call s:DebugMsgT( 1, "*Error:* ZcsdToZsd given list of size: " . len( a:zcsd ) )
        return []
    end
endfun
" 2}}}
" FUNCTION: ZcsdToLzds() {{{2
fun! s:ZcsdToLzds( zcsd, listing )
    return [ a:listing, a:zcsd[0], a:zcsd[2], a:zcsd[3] ]
endf
"2}}}
" FUNCTION: ReadCodes() {{{2
fun! s:ReadCodes()
    let new_lzcsd = s:BufferToLZCSD()
    let s:code_selectors = []

    let sel_count = 0
    let size = len(new_lzcsd)
    let i = 0
    while i < size
        if new_lzcsd[i][2] == " "
            let selection = 0
        else
            let selection = 1
            let sel_count = sel_count + 1
        end
        call add( s:code_selectors, selection )
        let i = i + 1
    endwhile

    return sel_count
endfun
" 2}}}
" FUNCTION: div_8_bit_pack_numbers_36() {{{2
fun! s:div_8_bit_pack_numbers_36(nums)
    let numbers = []
    let numbers = a:nums

    "
    " Now operate on the array performing long-division
    "

    let cur = 0
    let last = len( numbers ) - 1
    let result=[]

    let prepared_for_division = numbers[cur]
    while 1 == 1
        let quotient = prepared_for_division/36

        call add( result, quotient )

        let recovered = quotient * 36
        let subtracted = prepared_for_division-recovered

        let cur = cur + 1
        if cur > last
            break
        end

        let prepared_for_division = 256 * subtracted + numbers[cur]
    endwhile

    " echom "Result of division: " . join( result, "," )
    " echom "Remainder: " . subtracted

    return [ result, subtracted ]
}
endfun
" 2}}}
" FUNCTION: arr_01_to_8_bit_pack_numbers() {{{2
fun! s:arr_01_to_8_bit_pack_numbers(arr)
    let bits = []
    let pack = []
    let numbers = []

    let bits = a:arr
    let bcount = 0
    let size = len( bits )
    let i = size - 1

    " Take packs of 8 bits, convert each to number and store in array
    while i >= 0
        " Insert bits[i] at start of the list pack
        call insert( pack, bits[ i ] )
        let bcount = bcount + 1
        if bcount < 8 && i != 0
            let i = i - 1
            continue
        else
            let i = i - 1
        end
        let bcount = 0

        " Convert the max. 8 bit pack to number
        let result = 0
        for p in pack
            let result = result * 2 + p
        endfor

        " Insert result at start of the list numbers
        call insert( numbers, result )

        let pack=[]
    endwhile

    return numbers
endfun
" 2}}}
" FUNCTION: encode_zcode_arr01() {{{2
fun! s:encode_zcode_arr01(arr01)
    let numbers = s:arr_01_to_8_bit_pack_numbers(a:arr01)
    return s:encode_zcode_8_bit_pack_numbers(numbers)
endfun
" 2}}}
" FUNCTION: encode_zcode_8_bit_pack_numbers() {{{2
"
" Takes 8-bit pack numbers whose bits mark which zekylls are active
" and encodes them to base 36 number expressed via a-z0-9
"
fun! s:encode_zcode_8_bit_pack_numbers(nums)
    let numbers = a:nums
    let nums_base36 = []
    let workingvar = []

    let workingvar = numbers

    let sum=0
    for i in workingvar
        let sum = sum + i
    endfor

    while sum != 0
        let res = s:div_8_bit_pack_numbers_36( workingvar )
        let workingvar = res[0]
        call insert( nums_base36, res[1] )

        " Check if workingvar is all zero
        let sum=0
        for i in workingvar
            let sum = sum + i
        endfor
    endwhile

    let str = s:NumbersToLetters( nums_base36 )
    return [ nums_base36, str ]
endfun
" 2}}}
" FUNCTION: Space() {{{2
fun! s:Space()
    call s:SaveView()
    let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
    call s:RestoreView()

    let linenr = line( "." )
    let line = getline( linenr )

    if linenr == s:working_area_beg
        if s:beg_of_warea_char == '-'
            let s:beg_of_warea_char = '='
        else
            let s:beg_of_warea_char = '-'
        end
        call setline( linenr, s:GenerateRule( 1 ) )
    elseif linenr == s:working_area_end
        if s:end_of_warea_char == '-'
            let s:end_of_warea_char = '='
        else
            let s:end_of_warea_char = '-'
        end
        call setline( linenr, s:GenerateRule( 0 ) )
    elseif linenr < s:working_area_beg
        " At reset line, or at save line?
        let s_result = matchlist( line, s:pat_Save_IndexSize ) " Save line
        let r_result = matchlist( line, s:pat_Index_Reset )     " Reset line

        " Save line?
        if len( s_result ) > 0
            " Get Reset line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Index_Reset ) " Reset line
            if len( r_result ) > 0
                if s_result[1] ==? "yes"
                    let s:save = "no"
                else
                    let s:save = "yes"
                    let s:do_reset = "no"
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( linenr, save_line )
                let reset_line = s:GenerateIndexResetLine()
                call setline( s:line_reset, reset_line )
            else
                return 0
            end

        " Reset line
        elseif len( r_result ) > 0
            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line
            if len( s_result ) > 0
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos = stridx( line2, "|" ) + 1
                let col = col( "." )
                if col > pos
                    if r_result[2] ==? "yes"
                        let s:do_reset = "no"
                    else
                        let s:do_reset = "yes"
                        let s:save = "no"
                    end
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let reset_line = s:GenerateIndexResetLine()
                call setline( linenr, reset_line )
                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( s:line_save, save_line )
            else
                return 0
            end
        end
    elseif linenr > s:working_area_beg
        let entrynr = linenr - s:working_area_beg - 1
        let ZCSD = s:BufferLineToZCSD( line )

        if len( ZCSD ) == 0
            return 0
        end

        if ZCSD[1] != " "
            let selector = 0
        else
            let selector = 1
        end

        let listing = s:ZSDToListing( s:ZcsdToZsd( ZCSD ) )
        let line = s:BuildLineFromFullEntry( s:ZcsdToLzds( ZCSD, listing ), selector )
        let prev = s:code_selectors[entrynr]
        let s:code_selectors[entrynr] = selector

        let line = substitute( line, '\n$', "", "" )
        call setline( linenr, line )
    end

    call s:ShallowRender()

    return 1
endfun
" 1}}}
" FUNCTION: SaveView() {{{2
fun! s:SaveView()
    let s:savedLine = line(".")
    let s:savedCol = col(".")
    let s:zeroLine = line("w0")
endfun
" 2}}}
" FUNCTION: RestoreView() {{{2
fun! s:RestoreView()
    " restore the view
    let savedScrolloff=&scrolloff
    let &scrolloff=0
    call cursor(s:zeroLine, 1)
    normal! zt
    call cursor(s:savedLine, s:savedCol)
    let &scrolloff = savedScrolloff
endfun
" 2}}}
" FUNCTION: GetUniqueNumber() {{{2
fun! s:GetUniqueNumber()
    " Establish the time stamp seed used to protect file name collisions
    " The seed is used only for removed file names
    if exists("*strftime")
        let ts = strftime("%s")
    else
        let ts = system( 'date +%s' )
        let ts_arr = split( ts, '\n\+' )
        let ts = ""
        if len( ts_arr ) > 0
            let ts = ts_arr[0]
        end

        let res = matchlist( ts, '^\([0-9]\+\)' )
        if len( res ) == 0
            let ts = s:GetRandomNumber()
        end
    end

    return ts
endfun
" 2}}}
" FUNCTION: GetRandomNumber() {{{2
fun! s:GetRandomNumber()
    let ts = system( 'echo $RANDOM' )
    let ts_arr = split( ts, '\n\+' )
    let ts = ""
    if len( ts_arr ) > 0
        let ts = ts_arr[0]
    end
    return ts
endfun
" 2}}}
" FUNCTION: GenerateRule() {{{2
fun! s:GenerateRule( top, ... )
    let delta = 0
    if a:0 > 0
        let delta = a:1
    end

    if( a:top == 1 )
        return s:RPad( s:beg_of_warea_char, s:longest_lzsd + delta, s:beg_of_warea_char )
    else
        return s:RPad( s:end_of_warea_char, s:longest_lzsd + delta, s:end_of_warea_char )
    end
endfun
" 2}}}
" FUNCTION: FindOurWindow() {{{2
fun! s:FindOurWindow( bufnr )
    let ourwin = -1
    let all = 0
    let win = 1
    while 1 == 1
        let bufnr = winbufnr(win)
        if bufnr < 0
            break
        endif
        if bufnr == a:bufnr
            if ourwin == -1
                let ourwin = win
            end
            let all = all + 1
        endif
        let win = win + 1
    endwhile

    return [ ourwin, all ]
endfun
" 2}}}
" FUNCTION: FindOurTab() {{{2
fun! s:FindOurTab( bufnr )
    let found = -1
    for i in range(tabpagenr('$'))
        let tabs = tabpagebuflist(i + 1)

        let j = 0
        let size = len( tabs )
        while j < size
            if tabs[j] == a:bufnr
                let found = i + 1
                break
            end
            let j = j + 1
        endwhile
    endfor
    return found
endfun
" 2}}}
" 1}}}
" Backend functions {{{1
" FUNCTION: ReadRepo {{{2
fun! s:ReadRepo()
    let listing_text = system( "zkiresize -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -i " . s:cur_index . " -q --consistent")
    if v:shell_error == 11
        let s:inconsistent_listing = split(listing_text, '\n\+')
        let s:inconsistent_listing= s:inconsistent_listing[1:]
        let listing_text = system( "zkiresize -p " . shellescape(s:repos_paths[0]."/psprint---zkl") . " -i " . s:cur_index . " -q -l")
        let s:listing = split(listing_text, '\n\+')
        call s:DebugMsgT( 1, " Inconsistent Listing: ", s:inconsistent_listing )
        call s:DebugMsgT( 0, " All Listing: ", s:listing )
        let s:consistent = "NO"
    else
        let s:listing = split(listing_text, '\n\+')
        let s:listing= s:listing[1:]
        let s:consistent = "yes"

        " call s:DebugMsgT("Listing:", s:listing)
    end

endfun
" 2}}}
" FUNCTION: RewriteZekylls() {{{2
fun! s:RewriteZekylls(src_zekylls, dst_zekylls)
    if len( a:src_zekylls ) == 0 && len( a:dst_zekylls ) == 0
        " No actual work to do - index is empty
        return 1
    endif

    let cmd = "zkrewrite --noansi -w -p " . shellescape( s:cur_repo_path ) . " -z " . a:src_zekylls . " -Z " . a:dst_zekylls
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )

    return 1
endfun
" 2}}}
" FUNCTION: RemoveLZSD() {{{2
fun! s:RemoveLZSD(lzsd)
    let ts = s:GetUniqueNumber()

    let result = 0
    let delarr = []
    for entry in a:lzsd
        let entry[3] = substitute( entry[3], " ", "_", "g" )
        let file_name = entry[1] . "." . entry[2] . "--" . entry[3]
        let cmd = "cd " . shellescape( s:cur_repo_path ) . " && mv -f " . shellescape(file_name) . " _" . shellescape(file_name) . "-" . shellescape(ts)
        let cmd_output = system( cmd )
        let arr = split( cmd_output, '\n\+' )

        call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )
        let result = result + v:shell_error

        " Message
        call add( delarr, "|(err:" . v:shell_error . ")| {" . entry[1] . "." . entry[2] . "} " . entry[3] )
    endfor

    if result > 0
        let s:are_errors = "YES"
    end

    " Message
    if len( delarr ) == 1
        call s:AppendMessageT( " Deleted: " . delarr[0] )
    elseif len( delarr ) >= 2
        call map( delarr, '" *>* " . v:val' )
        call s:AppendMessageT( " Deleted: ", delarr )
    end

    return result
endfun
" 1}}}
" FUNCTION: Rename2LZSD() {{{2
fun! s:Rename2LZSD(lzsd_lzsd)
    let result = 0
    let renarr = []
    for entry in a:lzsd_lzsd 
        let entry[0][3] = substitute( entry[0][3], " ", "_", "g" )
        let old_file_name = entry[0][1] . "." . entry[0][2] . "--" . entry[0][3]
        let new_file_name = entry[1][1] . "." . entry[1][2] . "--" . entry[1][3]
        let cmd = "git -C " . shellescape( s:cur_repo_path ) . " mv " . shellescape(old_file_name) . " " . shellescape(new_file_name)

        let cmd_output = system( cmd )
        let arr = split( cmd_output, '\n\+' )

        call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )
        let result = result + v:shell_error

        " Message
        call add( renarr, "|(err:" . v:shell_error . ")| {" . entry[0][1] . "." . entry[0][2] . "} " . entry[0][3] .
                \ " -> {" . entry[1][1] . "." . entry[1][2] . "} " . entry[1][3] )
    endfor

    if result > 0
        let s:are_errors = "YES"
    end

    " Message
    if len( renarr ) == 1
        call s:AppendMessageT( " Renamed: " . renarr[0] )
    elseif len( renarr ) >= 2
        call map( renarr, '" *>* " . v:val' )
        call s:AppendMessageT( " Renamed: ", renarr )
    end

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

    if v:shell_error != 0
        let s:are_errors = "YES"

        if s:index_size_new > s:index_size
            let msg="extension"
        else
            let msg="shrink"
        end
        call s:AppendMessageT( "*Error* during index {" . s:cur_index . "} " . msg .  " (from |" . s:index_size .
                               \ "| to |" . s:index_size_new . "| zekylls):", " *>* |(err:" . v:shell_error . ")|" . error_decode )
    else
        if s:index_size_new > s:index_size
            let msg="Extended"
        else
            let msg="Shrinked"
        end
        call s:AppendMessageT( " " . msg . " index {" . s:cur_index . "} from |" . s:index_size . "| to |" . s:index_size_new . "| zekylls" )
    end

    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr, error_decode )
endfun
" 2}}}
" FUNCTION: ResetRepo() {{{2
fun! s:ResetRepo()
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " reset --hard"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Repository reset successfully" )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem occured during repository reset" )
    end

    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )

    return 1
endfun
" 2}}}
" 1}}}
" ------------------------------------------------------------------------------
let &cpo=s:keepcpo
unlet s:keepcpo

