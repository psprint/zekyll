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
" Current ref, is detached, all refs, branches, tags
let s:refs = [ "master", 0, [], [], [] ]
let s:srcdst = [ "origin" ]

let s:cur_index = 1
let s:prev_index = -1
let s:index_size = -1
let s:index_size_new = -1

let s:consistent = "yes"
let s:are_errors = "no"
let s:save = "no"
let s:do_reset = "no"
let s:commit = "no"
let s:do_status = "no"
let s:push_where = "nop"
let s:push_what = "nop"
let s:pull_where = "nop"
let s:pull_what = "nop"
let s:do_branch = "nop"
let s:do_tag = "nop"
let s:do_dbranch = "nop"
let s:do_dtag = "nop"

" Used by zcode buttons
let s:c_code = ""
let s:c_ref = ""
let s:c_file = ""
let s:c_repo = ""

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
let s:line_commit       = 4
let s:line_index        = 5
let s:line_reset        = 5
let s:line_checkout     = 5
let s:line_status       = 6
let s:line_origin       = 6
let s:line_btops        = 7
let s:line_code         = 8
let s:line_save         = 9
let s:line_index_size   = 9
let s:line_rule         = 10
let s:last_line = s:line_rule

let s:messages = [ ]

let s:savedLine = 1
let s:savedCol = 1
let s:zeroLine = 1

let s:pat_ZSD             = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<.>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_ZCSD            = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<\(.\)>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_Commit          = 'Consistent:[[:space:]]\+[a-zA-Z]\+[[:space:]]\+|[[:space:]]\+Errors:[[:space:]]\+[a-zA-Z]\+' . '[[:space:]]\+|[[:space:]]\+' .
                               \ '\[[[:space:]]\+Commit:[[:space:]]*<\?\([a-zA-Z]\{-1,}\)>\?[[:space:]]\+\]'

let s:pat_Index_Reset_Checkout = 'Current index:[[:space:]]*<\?\(\d\+\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                                \ '\[[[:space:]]\+Reset:[[:space:]]*<\?\([a-zA-Z]\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                                \ '\[[[:space:]]\+Checkout:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+\]'

let s:pat_Status_Push_Pull  = '\[[[:space:]]\+Status:[[:space:]]*<\?\([a-zA-Z]\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                              \ '\[[[:space:]]\+Push:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+<\?\(.\{-1,}\)>\?[[:space:]]\+\]' . 
                              \ '[[:space:]]\+|[[:space:]]\+' .
                              \ '\[[[:space:]]\+Pull:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+<\?\(.\{-1,}\)>\?[[:space:]]\+\]'

let s:pat_BTOps             = '\[[[:space:]]\+New Branch:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                              \'\[[[:space:]]\+Add Tag:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                              \'\[[[:space:]]\+Delete Branch:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
                              \'\[[[:space:]]\+Delete Tag:[[:space:]]*<\?\(.\{-1,}\)>\?[[:space:]]\+\]'

let s:pat_Save_IndexSize  = 'Save[[:blank:]]\+(\?<\?\([a-zA-Z]\{-1,}\)>\?)\?[[:blank:]]\+with[[:blank:]]\+index[[:blank:]]\+size[[:blank:]]\+<\?\([0-9]\+\)>\?'

let s:pat_Code            = '\[[[:space:]]\+Code:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Ref:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+File Name:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Repo:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*'

let s:ACTIVE_NONE = 0
let s:ACTIVE_CURRENT_INDEX = 1
let s:ACTIVE_CODE = 2
let s:ACTIVE_SAVE_INDEXSIZE = 3
let s:ACTIVE_RESET = 4
let s:ACTIVE_COMMIT = 5
let s:ACTIVE_CHECKOUT = 6
let s:ACTIVE_STATUS = 7
let s:ACTIVE_PUSH = 8
let s:ACTIVE_PULL = 9
let s:ACTIVE_NEW_BRANCH = 10
let s:ACTIVE_ADD_TAG = 11
let s:ACTIVE_DELETE_BRANCH = 12
let s:ACTIVE_DELETE_TAG = 13

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

    if depth >= 1
        let s:refs = s:ListAllRefs()
    end

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
        call setline( s:line_consistent, s:GenerateCommitLine() )
        call setline( s:line_index,      s:GenerateIndexResetLine() )
        call setline( s:line_origin,     s:GenerateStatusPushPullLine() )
        call setline( s:line_btops,      s:GenerateBTOpsLine() )
        call setline( s:line_code,       s:GenerateCodeLine( "", s:c_ref, s:c_file, s:c_repo ) )
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
        call s:ResetCodeLine()

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
    " New Branch?
    "

    if a:active == s:ACTIVE_NEW_BRANCH
        " Get BTOps line
        let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line
        if bt_result[1] != "nop"
            call s:DoNewBranch( bt_result[1] )
            call s:NormalRender()
        end
        return
    end

    "
    " Add Tag?
    "

    if a:active == s:ACTIVE_ADD_TAG
        " Get BTOps line
        let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line
        if bt_result[2] != "nop"
            call s:DoAddTag( bt_result[2] )
            call s:NormalRender()
        end
        return
    end

    "
    " Delete Branch?
    "

    if a:active == s:ACTIVE_DELETE_BRANCH
        " Get BTOps line
        let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line
        if bt_result[3] != "nop"
            call s:DoDeleteBranch( bt_result[3] )
            call s:NormalRender()
        end
        return
    end

    "
    " Delete Tag?
    "

    if a:active == s:ACTIVE_DELETE_TAG
        " Get BTOps line
        let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line
        if bt_result[4] != "nop"
            call s:DoDeleteTag( bt_result[4] )
            call s:NormalRender()
        end
        return
    end

    "
    " Status ?
    "

    if a:active == s:ACTIVE_STATUS
        call s:DoStatus()
        call s:NormalRender()
        return
    end

    "
    " Pull / Push ?
    "

    if a:active == s:ACTIVE_PUSH
        " Get Push Pull line
        let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line
        if p_result[2] ==? "nop" || p_result[2] ==? "..." || p_result[3] ==? "nop" || p_result[3] ==? "..."
            call s:AppendMessageT("Please set destination (e.g. origin) and branch (e.g. master)")
        else
            call s:DoPush( p_result[2], p_result[3] )
        end
        call s:NormalRender()
        return
    end

    if a:active == s:ACTIVE_PULL
        " Get Push Pull line
        let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line
        if p_result[4] ==? "nop" || p_result[4] ==? "..." || p_result[5] ==? "nop" || p_result[5] ==? "..."
            call s:AppendMessageT("Please set source (e.g. origin) and branch (e.g. master)")
        else
            call s:DoPull( p_result[4], p_result[5] )
        end
        call s:NormalRender()
        return
    end

    "
    " Commit ?
    "

    if a:active == s:ACTIVE_COMMIT
        call s:DoCommit()
        call s:NormalRender()
        return
    end

    "
    " Checkout ?
    "

    if a:active == s:ACTIVE_CHECKOUT
        let result = matchlist( getline( s:line_checkout ), s:pat_Index_Reset_Checkout )
        if len( result ) > 0
            let ref = result[3]
            if s:CheckGitState()
                call s:DoCheckout( ref )
            end
            call s:NormalRender()
            return
        else
            call s:AppendMessageT( "*Error:* control lines modified, cannot use document - will regenerate (3)" )
            call s:NormalRender()
            return
        end
    end

    "
    " Reset ?
    "

    if a:active == s:ACTIVE_RESET
        let result = matchlist( getline( s:line_reset ), s:pat_Index_Reset_Checkout )
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
        let result = matchlist( getline( s:line_index ), s:pat_Index_Reset_Checkout )
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
        let line = line . " ]   "
    else
        let line = line . "  ]   "
    end
    let line = line . "   | [ Checkout: <" . s:refs[0]. "> ]"
    return line
endfun
" 2}}}
" FUNCTION: GenerateCommitLine() {{{2
fun! s:GenerateCommitLine()
    return s:RPad( s:prefix . "Consistent: " . s:consistent, 22 ) . " | " .
         \ s:RPad( "Errors: " . s:are_errors, 21 ) . " | " .
         \ s:RPad( "[ Commit: <" . s:commit . "> ]", 16 )
endfun
" 2}}}
" FUNCTION: GenerateCodeLine() {{{2
fun! s:GenerateCodeLine( code, ref, file_name, repo )
    let line = "[ Code: " . s:cur_index . "/" . s:RPad( a:code, 15, " " ) . " ] "
    let line = line . "[ Ref: " . s:RPad( a:ref, 15, " " ) . " ] "
    let line = line . "[ File Name: " . s:RPad( a:file_name, 15, " " ) . " ] "
    let line = line . "[ Repo: " . s:RPad( a:repo, 15, " " ) . " ] ~"
    return line
endfun
" 2}}}
" FUNCTION: GenerateStatusPushPullLine() {{{2
fun! s:GenerateStatusPushPullLine( )
    let line =        s:RPad( "[ Status: <" . s:do_status. ">", 20)  . " ] | "
    let line = line . s:RPad( "[ Push: <"   . s:push_where. ">", 13) . " " . s:RPad( "<"   . s:push_what. ">", 5) . " ] | "
    let line = line . s:RPad( "[ Pull: <"   . s:pull_where. ">", 13) . " " . s:RPad( "<"   . s:pull_what. ">", 5) . " ]"
    return line
endfun
" 2}}}
" FUNCTION: GenerateBTOpsLine() {{{2
fun! s:GenerateBTOpsLine( )
    let line =        s:RPad( "[ New Branch: <"    . s:do_branch. ">", 15)  . " ]  | "
    let line = line . s:RPad( "[ Add Tag: <"       . s:do_tag. ">", 15)     . " ]    | "
    let line = line . s:RPad( "[ Delete Branch: <" . s:do_dbranch. ">", 15) . " ] | "
    let line = line . s:RPad( "[ Delete Tag: <"    . s:do_dtag. ">", 15)    . " ]"
    return line
endfun
" 2}}}
" FUNCTION: IsEditAllowed() {{{2
fun! s:IsEditAllowed()
    let line = line( "." )
    if line == s:line_index || line == s:line_index_size || line == s:line_code || line == s:line_btops || line == s:line_origin
        return 1
    end

    let col = col( "." )
    return col == 18 || col >= 24
endfun
" 2}}}
" FUNCTION: IsCodeLine() {{{2
fun! s:IsCodeLine()
    if line( "." ) == s:line_code
        return 1
    else
        return 0
    end
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
    nmap <buffer> <silent> <C-G> :set lz<CR>:!read<CR>:set nolz<CR>

    nmap <buffer> <silent> o <Nop>
    nmap <buffer> <silent> v <Nop>
    nmap <buffer> <silent> D <Nop>
    nmap <buffer> <silent> y <Nop>
    nmap <buffer> <silent> Y <Nop>
    noremap <buffer> <silent> <expr> p @" != "" ? 'p:let @"=""<cr>' : ""
    noremap <buffer> <silent> <expr> P @" != "" ? 'P:let @"=""<cr>' : ""
    "map <expr> i <SID>IsCodeLine() ? 'R' : 'i'

    vmap <buffer> <silent> D <Nop>
    vmap <buffer> <silent> p <Nop>
    vmap <buffer> <silent> P <Nop>

    imap <buffer> <silent> <CR> <Nop>

    setlocal buftype=nofile
    setlocal ft=help
    setlocal nowrap
    setlocal tw=290

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
        " Process the line like if it was one of multiple-button lines
        let line2 = substitute( line, '[^|]', "x", "g" )
        let pos1 = stridx( line2, "|" ) + 1
        let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
        let pos3 = pos2 + stridx( line2[pos1 :], "|" ) + 1
        let col = col( "." )

        if linenr == s:line_commit
            if col > pos2
                call s:ProcessBuffer( s:ACTIVE_COMMIT )
            end
            return 1
        elseif linenr == s:line_index
            if col < pos1
                call s:ProcessBuffer( s:ACTIVE_CURRENT_INDEX )
            elseif col > pos1 && col < pos2
                call s:ProcessBuffer( s:ACTIVE_RESET )
            elseif col > pos2
                call s:ProcessBuffer( s:ACTIVE_CHECKOUT )
            end
            return 1
        elseif linenr == s:line_origin
            if col < pos1
                call s:ProcessBuffer( s:ACTIVE_STATUS )
            elseif col > pos1 && col < pos2
                call s:ProcessBuffer( s:ACTIVE_PUSH )
            elseif col > pos2
                call s:ProcessBuffer( s:ACTIVE_PULL )
            end
            return 1
        elseif linenr == s:line_btops
            if col < pos1
                call s:ProcessBuffer( s:ACTIVE_NEW_BRANCH )
            elseif col > pos1 && col < pos2
                call s:ProcessBuffer( s:ACTIVE_ADD_TAG )
            elseif col > pos2 && col < pos3
                call s:ProcessBuffer( s:ACTIVE_DELETE_BRANCH )
            elseif col > pos3
                call s:ProcessBuffer( s:ACTIVE_DELETE_TAG )
            end
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
" FUNCTION: ResetCodeLine() {{{2
fun! s:ResetCodeLine()
    " First parse screen for ref, file name, repo
    let result = matchlist( getline( s:line_code ), s:pat_Code )
    if len( result ) > 0
        let s:c_ref = result[2]
        let s:c_file = result[3]
        let s:c_repo = result[4]

        let appendix = []
        call extend( appendix, s:BitsStart() )
        call extend( appendix, s:BitsRef(s:c_ref) )
        call extend( appendix, s:BitsFile(s:c_file) )
        call extend( appendix, s:BitsRepo(s:c_repo) )
        call extend( appendix, s:BitsStop() )
        let appendix = s:BitsRemoveIfStartStop( appendix )

        let code_bits = reverse( copy( s:code_selectors ) )

        if len( appendix ) == 0
            " There is no appendix, we should check if data is
            " properly ended with two reversed SS or without SS
            let rev_bits = reverse( copy( s:bits['ss'] ) )
            if s:BitsCompareSuffix( code_bits, rev_bits )
                call extend( code_bits, rev_bits )
            end
        else
            " Append the appendix, reversed
            call extend( code_bits, reverse( copy( appendix ) ) )
        end

        " echom "Code bits: " . join( code_bits, "," ) . " reversed SS: " . join( reverse( copy( s:bits['ss'] ) ), "," )
        " echom "Appendix: " . join( appendix, "," )

        let resu = s:encode_zcode_arr01( code_bits )
        call setline( s:line_code, s:GenerateCodeLine( resu[1], s:c_ref, s:c_file, s:c_repo ) )
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
        let s_result = matchlist( line, s:pat_Save_IndexSize )          " Save line
        let r_result = matchlist( line, s:pat_Index_Reset_Checkout )    " Reset line
        let c_result = matchlist( line, s:pat_Commit )                  " Commit line
        let p_result = matchlist( line, s:pat_Status_Push_Pull )           " Push Pull line
        let bt_result = matchlist( line, s:pat_BTOps )                  " BTOps line

        " Save line?
        if len( s_result ) > 0

            " Get Reset line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Index_Reset_Checkout ) " Reset line

            " Get Commit line
            unlet c_result
            let c_result = matchlist( getline( s:line_commit ), s:pat_Commit ) " Commit line

            " Get Push Pull line
            unlet p_result
            let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( r_result ) > 0 && len( c_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                if s_result[1] ==? "yes"
                    let s:save = "no"
                else
                    call s:TurnOff()
                    let s:save = "yes"
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( linenr, save_line )
                let commit_line = s:GenerateCommitLine()
                call setline( s:line_commit, commit_line )
                let reset_line = s:GenerateIndexResetLine()
                call setline( s:line_reset, reset_line )
                let origin_line = s:GenerateStatusPushPullLine()
                call setline( s:line_origin, origin_line )
                let btops_line = s:GenerateBTOpsLine()
                call setline( s:line_btops, btops_line )
            else
                return 0
            end

        " Reset line
        elseif len( r_result ) > 0

            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Commit line
            unlet c_result
            let c_result = matchlist( getline( s:line_commit ), s:pat_Commit ) " Commit line

            " Get Push Pull line
            unlet p_result
            let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( c_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let col = col( "." )
                if col > pos1 && col < pos2
                    if r_result[2] ==? "yes"
                        let s:do_reset = "no"
                    else
                        call s:TurnOff()
                        let s:do_reset = "yes"
                    end
                elseif col > pos2
                    let choices = s:refs[2]
                    let s:refs[0] = s:IterateOver( choices, s:refs[0] )

                    " Only one button in use
                    call s:TurnOff()
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let reset_line = s:GenerateIndexResetLine()
                call setline( linenr, reset_line )
                let commit_line = s:GenerateCommitLine()
                call setline( s:line_commit, commit_line )
                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( s:line_save, save_line )
                let origin_line = s:GenerateStatusPushPullLine()
                call setline( s:line_origin, origin_line )
                let btops_line = s:GenerateBTOpsLine()
                call setline( s:line_btops, btops_line )
            else
                return 0
            end
        " Commit line
        elseif len( c_result ) > 0

            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line
            
            " Get Reset line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Index_Reset_Checkout ) " Reset line

            " Get Push Pull line
            unlet p_result
            let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( r_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let col = col( "." )
                if col > pos2
                    if c_result[1] ==? "yes"
                        let s:commit = "no"
                    else
                        call s:TurnOff()
                        let s:commit = "yes"
                    end
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let commit_line = s:GenerateCommitLine()
                call setline( linenr, commit_line )
                let reset_line = s:GenerateIndexResetLine()
                call setline( s:line_reset, reset_line )
                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( s:line_save, save_line )
                let origin_line = s:GenerateStatusPushPullLine()
                call setline( s:line_origin, origin_line )
                let btops_line = s:GenerateBTOpsLine()
                call setline( s:line_btops, btops_line )
            else
                return 0
            end
        " Push Pull line
        elseif len( p_result ) > 0
            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Reset line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Index_Reset_Checkout ) " Reset line

            " Get Commit line
            unlet c_result
            let c_result = matchlist( getline( s:line_commit ), s:pat_Commit ) " Commit line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( c_result ) > 0 && len( r_result ) > 0 && len( bt_result ) > 0
                let line2 = substitute( line, '[^|<]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let col = col( "." )
                if col < pos1
                    if p_result[1] ==? "yes"
                        let s:do_status = "no"
                    else
                        call s:TurnOff()
                        let s:do_status = "yes"
                    end
                elseif col > pos1 && col < pos2
                    " At which of the two <...> cursor is?
                    let posa = pos1 + stridx( line2[pos1 :], "<" ) + 1
                    let posb = posa + stridx( line2[posa :], "<" ) + 1

                    if col > posa && col < posb
                        let choices = [ "nop" ] + s:srcdst + [ "..." ]
                        let s:push_where = s:IterateOver( choices, p_result[2] )

                        if s:push_where !=? "nop"
                            call s:TurnOff("NoPush")
                        end
                    elseif col > posb
                        let choices = [ "nop" ] + s:refs[3] + [ "..." ]
                        let s:push_what = s:IterateOver( choices, p_result[3] )

                        if s:push_what !=? "nop"
                            call s:TurnOff("NoPush")
                        end
                    end
                elseif col > pos2
                    " At which of the two <...> cursor is?
                    let posa = pos2 + stridx( line2[pos1 :], "<" ) + 1
                    let posb = posa + stridx( line2[posa :], "<" ) + 1

                    if col > posa && col < posb
                        let choices = [ "nop" ] + s:srcdst + [ "..." ]
                        let s:pull_where = s:IterateOver( choices, p_result[4] )

                        if s:pull_where !=? "nop"
                            call s:TurnOff("NoPull")
                        end
                    elseif col > posb
                        let choices = [ "nop" ] + s:refs[3] + [ "..." ]
                        let s:pull_what = s:IterateOver( choices, p_result[5] )

                        if s:pull_what !=? "nop"
                            call s:TurnOff("NoPull")
                        end
                    end
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let origin_line = s:GenerateStatusPushPullLine()
                call setline( linenr, origin_line )
                let commit_line = s:GenerateCommitLine()
                call setline( s:line_commit, commit_line )
                let reset_line = s:GenerateIndexResetLine()
                call setline( s:line_reset, reset_line )
                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( s:line_save, save_line ) 
                let btops_line = s:GenerateBTOpsLine()
                call setline( s:line_btops, btops_line )
            else
                return 0
            end
        " BTOps line?
        elseif len( bt_result ) > 0
            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Reset line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Index_Reset_Checkout ) " Reset line

            " Get Commit line
            unlet c_result
            let c_result = matchlist( getline( s:line_commit ), s:pat_Commit ) " Commit line

            " Get Push Pull line
            unlet p_result
            let p_result = matchlist( getline( s:line_origin ), s:pat_Status_Push_Pull ) " Push Pull line

            if len( s_result ) > 0 && len( r_result ) > 0 && len( c_result ) > 0 && len( p_result )
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let pos3 = pos2 + stridx( line2[pos2 :], "|" ) + 1
                let col = col( "." )
                if col < pos1
                    if bt_result[1] !=? "nop"
                        let s:do_branch = "nop"
                    else
                        call s:TurnOff()
                        let s:do_branch = "..."
                    end
                elseif col > pos1 && col < pos2
                    if bt_result[2] !=? "nop"
                        let s:do_tag = "nop"
                    else
                        call s:TurnOff()
                        let s:do_tag = "..."
                    end
                elseif col > pos2 && col < pos3
                    if bt_result[3] !=? "nop"
                        let s:do_dbranch = "nop"
                    else
                        call s:TurnOff()
                        let s:do_dbranch = "..."
                    end
                elseif col > pos3
                    if bt_result[4] !=? "nop"
                        let s:do_dtag = "nop"
                    else
                        call s:TurnOff()
                        let s:do_dtag = "..."
                    end
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                let btops_line = s:GenerateBTOpsLine()
                call setline( linenr, btops_line )
                let commit_line = s:GenerateCommitLine()
                call setline( s:line_commit, commit_line )
                let reset_line = s:GenerateIndexResetLine()
                call setline( s:line_reset, reset_line )
                let save_line = s:GenerateSaveIndexSizeLine()
                call setline( s:line_save, save_line )
                let origin_line = s:GenerateStatusPushPullLine()
                call setline( s:line_origin, origin_line )
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
" FUNCTION: TurnOffExcept() {{{2
fun! s:TurnOff(...)
    let except = ""
    if a:0 > 0
        let except = a:1
    end

    let s:commit = "no"
    let s:do_reset = "no"
    let s:do_status = "no"
    let s:save = "no"

    if except != "NoPush"
        let s:push_where = "nop"
        let s:push_what = "nop"
    end

    if except != "NoPull"
        let s:pull_where = "nop"
        let s:pull_what = "nop"
    end

    let s:do_branch = "nop"
    let s:do_tag = "nop"
    let s:do_dbranch = "nop"
    let s:do_dtag = "nop"
endfun
" 2}}}
" FUNCTION: IterateOver() {{{2
fun! s:IterateOver( choices, current )
    " Find where current points to
    let found = -1
    for i in range(0, len(a:choices)-1)
        if a:choices[i] == a:current
            let found = i
            break
        end
    endfor

    " Iterate one or set to first
    if found == -1
        return a:choices[0]
    else
        let found = (found + 1) % len( a:choices )
        return a:choices[ found ]
    end
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
" FUNCTION: DoCommit() {{{2
fun! s:DoCommit()
    let cmd = ":!echo \"===============================================\" && git -C " . shellescape( s:cur_repo_path ) . " commit"
    exec cmd

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Commit ended successfully" )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem during commit. Press Ctrl-G to view Git's output." )
    end
endfun
" 2}}}
" FUNCTION: DoCheckout() {{{2
fun! s:DoCheckout(ref)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " checkout " . shellescape(a:ref)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    
    let pattern="Note:\\|HEAD\\ is\\ now\\|Previous\\ HEAD\\|Switched\\ to\\|Already on\\|error:"
    call filter(arr, 'v:val =~ pattern')

    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Checkout successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with checkout >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoStatus() {{{2
fun! s:DoStatus()
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " status -u no"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    
    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Status successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with status >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoPull() {{{2
fun! s:DoPull(source, branch)
    let source = a:source
    let branch = a:branch
    if source ==? "nop"
        let source = "origin"
    end 
    if branch ==? "nop"
        let branch = "master"
    end

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " pull " . shellescape( source ) . " " . shellescape( branch )
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    
    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Pull " . source . " " . branch . " successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with pull " . source . " " . branch . " >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoPush() {{{2
fun! s:DoPush(destination, branch)
    let destination = a:destination
    let branch = a:branch
    if destination ==? "nop"
        let destination = "origin"
    end 
    if branch ==? "nop"
        let branch = "master"
    end

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " push " . shellescape( destination ) . " " . shellescape( branch )
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Push " . destination . " " . branch . " successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with push " . destination . " " . branch . " >", arr )
    end
endfun
" 2}}}
" FUNCTION: CheckGitState() {{{2
" Will check if there are any unsaved operations
fun! s:CheckGitState()
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " status --porcelain"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    let pattern = '^[RA]\|\ D'
    call filter(arr, 'v:val =~ pattern')

    if len( arr ) > 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT(" Please commit or reset before checking out other ref. The problematic, uncommited files are: >", arr)
        return 0
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT(" Allowed to perform checkout >", arr)
        return 1
    end
    return 1
endfun
" 2}}}
" FUNCTION: ListAllRefs() {{{2
fun! s:ListAllRefs()
    "
    " Branch
    "

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " branch --list --no-color"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    if v:shell_error != 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with branch --list >", arr )
    end
    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )

    "
    " Tag
    "

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " tag -l"
    let cmd_output = system( cmd )
    let arr2 = split( cmd_output, '\n\+' )

    if v:shell_error != 0
        call map( arr2, '" " . v:val' )
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with tag -l >", arr2 )
    end
    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr2 )

    "
    " Post-processing
    "

    " Find active branch
    let arr1 = []
    let active = ""
    let detached = 0
    for ref in arr
        if ref =~ "^\*.*"
            let ref = substitute( ref, "^\* ", "", "" )
            if ref =~ "(.*)"
                let detached = 1
                let ref = substitute( ref, '(HEAD detached at \(.*\))', '\1', "" )
            end
            let active = ref
        end
        call add( arr1, ref )
    endfor

    " Remove whitespace from all arr1 and arr2 elements
    call map( arr1, 'substitute( v:val, "^ \\+", "", "g" )' )
    call map( arr2, 'substitute( v:val, "^ \\+", "", "g" )' )

    " Make ref list unique
    let all = sort(arr1 + arr2)
    let all = filter(copy(all), 'index(all, v:val, v:key+1)==-1')

    return [ active, detached, all, arr1, arr2 ]
endfun
" 2}}}
" FUNCTION: DoNewBranch() {{{2
fun! s:DoNewBranch(ref)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " checkout -b " . shellescape(a:ref)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Checkout -b successful >", arr )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with checkout -b >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoAddTag() {{{2
fun! s:DoAddTag(ref)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " tag " . shellescape(a:ref)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Tag successful", arr )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with tag >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoDeleteBranch() {{{2
fun! s:DoDeleteBranch(ref)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " branch -d " . shellescape(a:ref)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Branch -d successful >", arr )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with branch -d >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoDeleteTag() {{{2
fun! s:DoDeleteTag(ref)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " tag -d " . shellescape(a:ref)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Tag -d successful >", arr )
    else
        call s:AppendMessageT( "|(err:" . v:shell_error . ")| Problem with tag -d >", arr )
    end
endfun
" 2}}}
" 1}}}
" Bits functions {{{1
" FUNCTION: BitsStart() {{{2
fun! s:BitsStart()
    return s:bits['ss']
endfun
" 2}}}
" FUNCTION: BitsStop() {{{2
fun! s:BitsStop()
    return s:bits['ss']
endfun
" 2}}}
" FUNCTION: BitsRef() {{{2
fun! s:BitsRef( ref )
    let bits = []

    let ref = deepcopy( a:ref )
    if ref == " "
        let ref = ""
    end

    for lt in split( ref, '\zs' )
        if has_key( s:bits, lt )
            call extend( bits, s:bits[lt] )
        else
            call s:AppendMessageT(" Incorrect character in ref name: `" . lt . "'")
        end
    endfor

    " Ref preamble
    if len( bits ) > 0
        let bits = s:bits['ref'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsFile() {{{2
fun! s:BitsFile( file )
    let bits = []

    let file = deepcopy( a:file )
    if file == " "
        let file = ""
    end

    for lt in split( file, '\zs' )
        if lt == "."
            call extend( bits, s:bits["/"] )
        elseif lt == "/"
            call s:AppendMessageT(" Incorrect character in file name: `" . lt . "'")
        else
            if has_key( s:bits, lt )
                call extend( bits, s:bits[lt] )
            else
                call s:AppendMessageT(" Incorrect character in file name: `" . lt . "'")
            end
        end
    endfor

    " File preamble
    if len( bits ) > 0
        let bits = s:bits['file'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsRepo() {{{2
fun! s:BitsRepo( repo )
    let bits = []

    let repo = deepcopy( a:repo )
    if repo == " "
        let repo = ""
    end

    for lt in split( repo, '\zs' )
        if has_key( s:bits, lt )
            call extend( bits, s:bits[lt] )
        else
            call s:AppendMessageT(" Incorrect character in file name: `" . lt . "'")
        end
    endfor

    " Repo preamble
    if len( bits ) > 0
        let bits = s:bits['repo'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsRemoveIfStartStop() {{{2
" This function also ensures that the code ends
" at double SS bits if data ends at SS bits
fun! s:BitsRemoveIfStartStop( appendix )
    let appendix = deepcopy( a:appendix )

    if s:BitsCompareSuffix( appendix, s:bits['ss'] )
        call remove( appendix, len(appendix) - len(s:bits['ss']), -1 )

        if s:BitsCompareSuffix( appendix, s:bits['ss'] )
            call remove( appendix, len(appendix) - len(s:bits['ss']), -1 )

            " Two consecutive SS bits occured, correct removal
        else
            " We couldn't remove second SS bits, so it means
            " that there is some meta data, and we should
            " restore already removed last SS bits
            call extend( appendix, s:bits['ss'] )
        end
    else
        " This shouldn't happen, this function must be
        " called after adding SS bits
        return []
    end

    return appendix
endfun
" 2}}}
" FUNCTION: BitsCompareSuffix() {{{2
fun! s:BitsCompareSuffix( long_bits, short_bits )
    " Check if short_bits occur at the end of long_bits
    let range = range( len( a:long_bits ) - len( a:short_bits ) + 1, len( a:long_bits ) )
    let equal = 1
    let s = 0
    for l in map(range, "v:val - 1")
        if a:long_bits[l] != a:short_bits[s]
            let equal = 0
            break
        end
        let s = s + 1
    endfor

    return equal
endfun
" 2}}}
" Coding functions {{{1
" FUNCTION: LettersToNumbers() {{{2
fun! s:LettersToNumbers( letters )
    let reply=[]
    for l in split( a:letters, '\zs' )
        let number = index( s:characters, l )
        call add( reply, number )
    endfor
    return reply
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
" FUNCTION: div2() {{{2
" input - zcode's letters
" return - [ zcode's letters after division, remainder 0 or 1 ]
fun! s:div2( letters )
    "
    " First translate the letters to numbers and put them into array
    "

    let numbers = []
    let numbers = s:LettersToNumbers( a:letters )

    "
    " Now operate on the array performing long-division
    "

    let cur = 0
    let last = len( numbers ) - 1

    let result = []

    let prepared_for_division = numbers[ cur ]
    while 1
        let quotient = prepared_for_division / 2

        call add( result, quotient )

        let recovered = quotient * 2
        let subtracted = prepared_for_division - recovered

        let cur = cur + 1
        if cur > last
            break
        end

        let prepared_for_division = 36 * subtracted + numbers[ cur ]
    endwhile

    "
    " Now convert the result to letters
    "

    let REPLY = s:NumbersToLetters( result )

    "
    " Return
    "

    let reply=[ REPLY, subtracted ]

    return reply
endfun
" 2}}}
" FUNCTION: decode_zcode() {{{2
"
" Takes zekyl code, i.e. 1/someletters
" and decodes it to series of zekylls
"
fun! s:decode_zcode( zcode )
    let splitted = split( a:zcode, "/" )

    if len( splitted ) != 2
        " Improper zcode
        return []
    end

    let number = splitted[0]
    let letters = splitted[1]

    " The zcode can have at most 30 digits
    " This is the 150 bits (150 zekylls)
    " written in base 36. We have to obtain
    " the 150 bits. We will implement division
    " in base 36 and gradually obtain the 150 bits.

    let bits = []
    let workingvar = letters
    while workingvar !~ "^a*$"
        let reply = s:div2( workingvar )
        let workingvar = reply[0]
        call insert( bits, reply[1] )
        " echom "After div " . workingvar . "/" . reply[1]
    endwhile
    " echom "Bits of the letters " . letters . " are: " . join( bits, "" )
    return bits
}
endfun
" 2}}}
" FUNCTION: process_meta_data() {{{2
" Arg 1 - bits decoded from zcode
" reply - [ bits to skip, { file : "", ref : "", repo : "", wordref : "", chksum : "", site : "",
"                           unused1 : "", unused2 : "", unused3 : "", error : "" } ]
fun! s:process_meta_data( bits )
    let bits = reverse( deepcopy( a:bits ) )
    let strbits = join( bits, "" )
    let init_len = len( strbits )
    let to_skip = 0

    let decoded = {
      \  "file"     : "",
      \  "ref"      : "",
      \  "repo"     : "",
      \  "wordref"  : "",
      \  "chksum"   : "",
      \  "site"     : "",
      \  "unused1"  : "",
      \  "unused2"  : "",
      \  "unused3"  : "",
      \  "error"    : "",
      \ }

    " Is there SS?
    let ss_len = len( s:codes['ss'] )
    if strbits[ 0 : ss_len-1 ] == s:codes['ss']
        let strbits = strbits[ ss_len : -1 ]
        " Is there immediate following SS?
        if strbits[ 0 : ss_len-1 ] == s:codes['ss']
            " We should skip one SS and there is nothing to decode
            let to_skip = ss_len
            return [ to_skip, decoded ]
        end

        "
        " Follows meta data, decode it
        "

        " keys of the decoded dictionary
        let current_selector = "error"
        let trylen = 0
        let mat = ""
        let trystr = ""
        while 1
            let mat=""
            for trylen in range(1,7)
                " Take substring of len $trylen and check if
                " it matches any Huffman code
                let trystr = strbits[ 0 : trylen-1 ]
                if has_key( s:rcodes, trystr )
                    let mat = s:rcodes[ trystr ]
                    break
                end
            endfor

            " General failure in decoding the string
            if mat == ""
                let to_skip = -1
                return [ to_skip, decoded ]
            end

            " Skip decoded bits
            let strbits = strbits[ trylen : -1 ]

            " Handle what has been matched, either selector or data
            if mat == "ss"
                break
            elseif mat == "file" || mat == "ref" || mat == "repo" || mat == "wordref" || mat == "chksum" || mat == "site"
                let current_selector = mat
            elseif mat == "unused1" || mat == "unused2" || mat == "unused3"
                let current_selector = mat
            else
                " File names use "/" to encode "." character. "/" itself is unavailable
                if mat == "/" && current_selector == "file"
                    mat = "."
                end

                let decoded[ current_selector ] = decoded[ current_selector ] . mat
            end
        endwhile

        let to_skip = init_len - len( strbits )
    else
        let to_skip = 0
    end

    return [ to_skip, decoded ]
endfun
" 2}}}
" FUNCTION: get_zekyll_bits_for_code() {{{2
"
" Gets zekyll bits for given code ($1)
" Also gets meta data: ref, file, repo
" and puts it into return array [ bits,
" meta_data ]
"
fun! s:get_zekyll_bits_for_code( zcode )
    let bits = s:decode_zcode ( a:zcode )

    let [ to_skip, meta_reply ] = s:process_meta_data( bits )
    " meta_reply contains: { file : "", ref : "", repo : "", wordref : "", chksum : "", site : "",
    "                        unused1 : "", unused2 : "", unused3 : "", error : "" }
    " to_skip contains: number of final bits that contained the meta data

    " Skip bits that were processed as meta data

    let before = len (bits)
    let bits = bits[ 0 : -1*to_skip-1 ]

    return [ bits, meta_reply ]
endfun
" 2}}
" 1}}}
" ------------------------------------------------------------------------------

let s:bits = {
\ 'ss'       :  [ 1,1,0,0,1,1 ],
\ 'file'     :  [ 1,1,0,0,0,0 ],
\ 'ref'      :  [ 1,1,0,0,0,1 ],
\ 'repo'     :  [ 1,1,0,1,0,0 ],
\ 'wordref'  :  [ 1,0,1,0,0,0 ],
\ 'chksum'   :  [ 1,0,1,0,0,1 ],
\ 'site'     :  [ 0,0,0,0,1,0 ],
\ 'unused1'  :  [ 0,1,0,0,1,0 ],
\ 'unused2'  :  [ 0,1,0,0,1,1 ],
\ 'unused3'  :  [ 1,0,1,1,1,0 ],
\ '-'        :  [ 0,0,1,1,0,0 ],
\ '_'        :  [ 0,0,1,1,0,1 ],
\ '/'        :  [ 0,0,1,1,1,1 ],
\ '0'        :  [ 0,1,0,0,0,0 ],
\ '1'        :  [ 0,0,0,0,1,1 ],
\ '2'        :  [ 0,0,0,0,0,0 ],
\ '3'        :  [ 0,0,0,0,0,1 ],
\ '4'        :  [ 0,0,0,1,1,0 ],
\ '5'        :  [ 0,0,0,1,1,1 ],
\ '6'        :  [ 0,0,0,1,0,0 ],
\ '7'        :  [ 0,0,0,1,0,1 ],
\ '8'        :  [ 0,0,1,0,1,0 ],
\ '9'        :  [ 0,0,1,0,1,1 ],
\ 'A'        :  [ 1,0,1,0,1,1 ],
\ 'B'        :  [ 1,1,0,1,1,1,0 ],
\ 'C'        :  [ 1,1,0,1,1,1,1 ],
\ 'D'        :  [ 1,1,0,1,1,0,0 ],
\ 'E'        :  [ 1,1,0,1,1,0,1 ],
\ 'F'        :  [ 1,1,1,1,0,1,0 ],
\ 'G'        :  [ 1,1,1,1,0,1,1 ],
\ 'H'        :  [ 1,1,1,1,0,0,0 ],
\ 'I'        :  [ 1,1,1,1,0,0,1 ],
\ 'J'        :  [ 1,1,1,1,1,1,0 ],
\ 'K'        :  [ 1,1,1,1,1,1,1 ],
\ 'L'        :  [ 1,1,1,1,1,0,0 ],
\ 'M'        :  [ 1,1,1,1,1,0,1 ],
\ 'N'        :  [ 1,1,1,0,0,1,0 ],
\ 'O'        :  [ 1,1,1,0,0,1,1 ],
\ 'P'        :  [ 1,1,1,0,0,0,0 ],
\ 'Q'        :  [ 1,1,1,0,0,0,1 ],
\ 'R'        :  [ 1,1,1,0,1,1,0 ],
\ 'S'        :  [ 1,1,1,0,1,1,1 ],
\ 'T'        :  [ 1,1,1,0,1,0,0 ],
\ 'U'        :  [ 1,1,1,0,1,0,1 ],
\ 'V'        :  [ 1,1,0,1,0,1,0 ],
\ 'W'        :  [ 1,1,0,1,0,1,1 ],
\ 'X'        :  [ 0,0,1,0,0,0 ],
\ 'Y'        :  [ 0,0,1,0,0,1 ],
\ 'Z'        :  [ 0,0,1,1,1,0 ],
\ 'a'        :  [ 1,0,1,1,1,1 ],
\ 'b'        :  [ 0,1,0,0,0,1 ],
\ 'c'        :  [ 1,0,1,1,0,0 ],
\ 'd'        :  [ 1,0,1,1,0,1 ],
\ 'e'        :  [ 1,1,0,0,1,0 ],
\ 'f'        :  [ 0,1,0,1,1,0 ],
\ 'g'        :  [ 0,1,0,1,1,1 ],
\ 'h'        :  [ 0,1,0,1,0,0 ],
\ 'i'        :  [ 0,1,0,1,0,1 ],
\ 'j'        :  [ 1,0,0,0,1,0 ],
\ 'k'        :  [ 1,0,0,0,1,1 ],
\ 'l'        :  [ 1,0,0,0,0,0 ],
\ 'm'        :  [ 1,0,0,0,0,1 ],
\ 'n'        :  [ 1,0,0,1,1,0 ],
\ 'o'        :  [ 1,0,0,1,1,1 ],
\ 'p'        :  [ 1,0,0,1,0,0 ],
\ 'q'        :  [ 1,0,0,1,0,1 ],
\ 'r'        :  [ 0,1,1,0,1,0 ],
\ 's'        :  [ 0,1,1,0,1,1 ],
\ 't'        :  [ 0,1,1,0,0,0 ],
\ 'u'        :  [ 0,1,1,0,0,1 ],
\ 'v'        :  [ 0,1,1,1,1,0 ],
\ 'w'        :  [ 0,1,1,1,1,1 ],
\ 'x'        :  [ 0,1,1,1,0,0 ],
\ 'y'        :  [ 0,1,1,1,0,1 ],
\ 'z'        :  [ 1,0,1,0,1,0 ]
\ }

let s:codes={
\ 'ss'          : "110011",
\ 'file'        : "110000",
\ 'ref'         : "110001",
\ 'repo'        : "110100",
\ 'wordref'     : "101000",
\ 'chksum'      : "101001",
\ 'site'        : "000010",
\ 'unused1'     : "010010",
\ 'unused2'     : "010011",
\ 'unused3'     : "101110",
\ '-'           : "001100",
\ '_'           : "001101",
\ '/'           : "001111",
\ '0'           : "010000",
\ '1'           : "000011",
\ '2'           : "000000",
\ '3'           : "000001",
\ '4'           : "000110",
\ '5'           : "000111",
\ '6'           : "000100",
\ '7'           : "000101",
\ '8'           : "001010",
\ '9'           : "001011",
\ 'A'           : "101011",
\ 'B'           : "1101110",
\ 'C'           : "1101111",
\ 'D'           : "1101100",
\ 'E'           : "1101101",
\ 'F'           : "1111010",
\ 'G'           : "1111011",
\ 'H'           : "1111000",
\ 'I'           : "1111001",
\ 'J'           : "1111110",
\ 'K'           : "1111111",
\ 'L'           : "1111100",
\ 'M'           : "1111101",
\ 'N'           : "1110010",
\ 'O'           : "1110011",
\ 'P'           : "1110000",
\ 'Q'           : "1110001",
\ 'R'           : "1110110",
\ 'S'           : "1110111",
\ 'T'           : "1110100",
\ 'U'           : "1110101",
\ 'V'           : "1101010",
\ 'W'           : "1101011",
\ 'X'           : "001000",
\ 'Y'           : "001001",
\ 'Z'           : "001110",
\ 'a'           : "101111",
\ 'b'           : "010001",
\ 'c'           : "101100",
\ 'd'           : "101101",
\ 'e'           : "110010",
\ 'f'           : "010110",
\ 'g'           : "010111",
\ 'h'           : "010100",
\ 'i'           : "010101",
\ 'j'           : "100010",
\ 'k'           : "100011",
\ 'l'           : "100000",
\ 'm'           : "100001",
\ 'n'           : "100110",
\ 'o'           : "100111",
\ 'p'           : "100100",
\ 'q'           : "100101",
\ 'r'           : "011010",
\ 's'           : "011011",
\ 't'           : "011000",
\ 'u'           : "011001",
\ 'v'           : "011110",
\ 'w'           : "011111",
\ 'x'           : "011100",
\ 'y'           : "011101",
\ 'z'           : "101010",
\ }

" Reverse map of Huffman codes
let s:rcodes = {
\ "110011"         : 'ss',
\ "110000"         : 'file',
\ "110001"         : 'ref',
\ "110100"         : 'repo',
\ "101000"         : 'wordref',
\ "101001"         : 'chksum',
\ "000010"         : 'site',
\ "010010"         : 'unused1',
\ "010011"         : 'unused2',
\ "101110"         : 'unused3',
\ "001100"         : '-',
\ "001101"         : '_',
\ "001111"         : '/',
\ "010000"         : '0',
\ "000011"         : '1',
\ "000000"         : '2',
\ "000001"         : '3',
\ "000110"         : '4',
\ "000111"         : '5',
\ "000100"         : '6',
\ "000101"         : '7',
\ "001010"         : '8',
\ "001011"         : '9',
\ "101011"         : 'A',
\ "1101110"        : 'B',
\ "1101111"        : 'C',
\ "1101100"        : 'D',
\ "1101101"        : 'E',
\ "1111010"        : 'F',
\ "1111011"        : 'G',
\ "1111000"        : 'H',
\ "1111001"        : 'I',
\ "1111110"        : 'J',
\ "1111111"        : 'K',
\ "1111100"        : 'L',
\ "1111101"        : 'M',
\ "1110010"        : 'N',
\ "1110011"        : 'O',
\ "1110000"        : 'P',
\ "1110001"        : 'Q',
\ "1110110"        : 'R',
\ "1110111"        : 'S',
\ "1110100"        : 'T',
\ "1110101"        : 'U',
\ "1101010"        : 'V',
\ "1101011"        : 'W',
\ "001000"         : 'X',
\ "001001"         : 'Y',
\ "001110"         : 'Z',
\ "101111"         : 'a',
\ "010001"         : 'b',
\ "101100"         : 'c',
\ "101101"         : 'd',
\ "110010"         : 'e',
\ "010110"         : 'f',
\ "010111"         : 'g',
\ "010100"         : 'h',
\ "010101"         : 'i',
\ "100010"         : 'j',
\ "100011"         : 'k',
\ "100000"         : 'l',
\ "100001"         : 'm',
\ "100110"         : 'n',
\ "100111"         : 'o',
\ "100100"         : 'p',
\ "100101"         : 'q',
\ "011010"         : 'r',
\ "011011"         : 's',
\ "011000"         : 't',
\ "011001"         : 'u',
\ "011110"         : 'v',
\ "011111"         : 'w',
\ "011100"         : 'x',
\ "011101"         : 'y',
\ "101010"         : 'z',
\ }

let &cpo=s:keepcpo
unlet s:keepcpo

