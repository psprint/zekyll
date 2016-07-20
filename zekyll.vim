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
    map <unique> <Leader>z <Plug>StartZekyll
endif

" Global Maps:
"
map <silent> <unique> <script> <Plug>StartZekyll :set lz<CR>:call <SID>StartZekyll()<CR>:set nolz<CR>

" Script Variables:
let s:nowait = (v:version > 703 ? '<nowait>' : '')
let s:home = fnameescape( $HOME )
let s:cur_repo = "psprint/zkl"
let s:cur_repo_path = s:home . "/.zekyll/repos/gh---psprint---zkl---master"
let s:repos_paths = [ s:home . "/.zekyll/repos" ]

let s:lzsd = []
let s:listing = []
let s:inconsistent_listing = []
let s:index_zekylls = []
" Current rev, is detached, all revs, branches, tags
let s:revs = [ "master", 0, [], [], [] ]
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
let s:c_rev = ""
let s:c_file = ""
let s:c_repo = ""
let s:c_site = "gh"

let s:working_area_beg = 1
let s:working_area_end = 1

let s:longest_lzsd = 0

let s:code_selectors = []
let s:characters = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h",
                \  "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]


let s:after_zekyll_spaces = "    "
let s:after_section_spaces = "    "
let s:after_switch_spaces = "    "

let s:beg_of_warea_char = '-'
let s:end_of_warea_char = '-'

" Welcome line
let s:line_welcome = 2

" First line: repo and its path
let s:line_repo_data = 4

" First line, current index
let s:line_consistent   = 5
let s:line_errors       = 5
let s:line_index        = 5

" Git operations 1
let s:line_commit       = 6
let s:line_reset        = 6
let s:line_checkout     = 6
let s:line_gitops1      = 6

" Git operations 2, Status, Push, Pull
let s:line_status       = 7
let s:line_push         = 7
let s:line_pull         = 7
let s:line_gitops2      = 7

" Branch/Tag operations
let s:line_btops        = 8

" Code line
let s:line_code         = 9

" Save line
let s:line_save         = 10
let s:line_index_size   = 10

let s:line_rule         = 11
let s:last_line = s:line_rule

let s:messages = [ ]

let s:savedLine = 1
let s:savedCol = 1
let s:zeroLine = 1

let s:pat_ZSD             = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<.>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_ZCSD            = '^|\([a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]\)|' . '[[:space:]]\+' . '<\(.\)>' .
                               \ '[[:space:]]\+' . '\*\?\([A-Z]\)\*\?' . '[[:space:]]\+' . '\(.*\)$'

let s:pat_Index          = 'Consistent:[[:space:]]\+[a-zA-Z]\+[[:space:]]\+|[[:space:]]\+Errors:[[:space:]]\+[a-zA-Z]\+' . '[[:space:]]\+|[[:space:]]\+' .
                               \ '\[[[:space:]]\+Current index:[[:space:]]*<\?\(\d\+\)>\?[[:space:]]\+\]'

let s:pat_Commit_Reset_Checkout = 'Commit:[[:space:]]*<\?\([a-zA-Z]\{-1,}\)>\?[[:space:]]\+\]' . '[[:space:]]\+|[[:space:]]\+' .
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

let s:pat_Save_IndexSize  = 'Save[[:space:]]\+(\?<\?\([a-zA-Z]\{-1,}\)>\?)\?[[:space:]]\+with[[:space:]]\+index[[:space:]]\+size[[:space:]]\+<\?\([0-9]\+\)>\?'

let s:pat_Code            = '\[[[:space:]]\+Code:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Rev:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+File Name:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Repo:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Site:[[:space:]]*<\?\(.\{-2}\)>\?[[:space:]]*\][[:space:]]*'

let s:pat_Repo_Data       = '\[[[:space:]]\+Path:[[:space:]]*\(.\{-1,}\)[[:space:]]*\][[:space:]]*' .
                          \ '\[[[:space:]]\+Repo spec:[[:space:]]*\(.\{-1,}\)[[:space:]]*\]'

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
let s:ACTIVE_CODE = 14
let s:ACTIVE_REF = 15
let s:ACTIVE_FILE = 16
let s:ACTIVE_REPO = 17
let s:ACTIVE_PATH = 18
let s:ACTIVE_REPO_SPEC = 19
let s:ACTIVE_BROWSE = 20

let s:called_GenerateCodeFromState = 0
let s:last_message_count = 0
let s:decode_message = ""
let s:reported_duplicate_zekylls = []

" ------------------------------------------------------------------------------
" s:StartZekyll: this function is available via the <Plug>/<script> interface above
fun! s:StartZekyll()
    call s:Opener()

    setlocal buftype=nofile
    setlocal nowrap
    setlocal tw=1024
    setlocal magic
    setlocal matchpairs=

    call s:SetupSyntaxHighlighting()

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

    " Read buffer and build data structure s:code_selectors
    " - only when there is any index set, otherwise there's
    " also no contents in buffer (first load)
    if len( s:index_zekylls ) > 0
        call s:ReadCodes()
    end

    if depth >= 1
        let s:revs = s:ListAllRevs()
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

    " Remember len of code selectors before truncation/expand
    " (in SetupSelectionCodes)
    let formsg_old_len = len( s:code_selectors )

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
        call setline( s:line_repo_data,  s:GenerateRepoDataLine() )
        call setline( s:line_consistent, s:GenerateIndexLine() )
        call setline( s:line_commit,     s:GenerateCommitResetLine() )
        call setline( s:line_gitops2,    s:GenerateStatusPushPullLine() )
        call setline( s:line_btops,      s:GenerateBTOpsLine() )
        call setline( s:line_code,       s:GenerateCodeLine( s:cur_index, s:c_code, s:c_rev, s:c_file, s:c_repo, s:c_site ) )
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
    else
        " To display information on error also in shallow renders
        if s:consistent ==? "no" || s:are_errors ==? "yes"
            call setline( s:line_welcome+1, ">" )
            let s:prefix = " "
        else
            call setline( s:line_welcome+1, "" )
            let s:prefix = ""
        end
        call setline( s:line_consistent, s:GenerateIndexLine() )
    end

    " Error mark is short-lived
    call s:MarkErrorsDuringGeneration(0)

    if depth >= 0
        let formsg_old_code = s:c_code

        call s:GenerateCodeWasCalled()
        let [ correct_generation, s:c_code ] = s:GenerateCodeFromState()
        " Restore mark that tells if GenerateCodeFromState was already called in this run
        call s:GenerateCodeWasCalled(0)

        let zcode1 = s:cur_index . "/" . formsg_old_code
        let zcode2 = s:cur_index . "/" . s:c_code

        " Message about misadapted Zcode
        if len( s:code_selectors ) < formsg_old_len
            let msg = "Warning: the Zcode " . zcode1 . " is for index of size|" . formsg_old_len . "|or more, current index is of size|" . len( s:code_selectors ) . "|"
            let msg = msg . (correct_generation ? "– truncated Zcode to: " . zcode2 : '. Error: could not truncate the Zcode')
            call s:AppendMessageT( msg )
        end

        " Message about Zcode decoding
        if s:decode_message != ""
            let msg = ( formsg_old_len > len( s:code_selectors ) ? "Decoded the misadapted Zcode " : "Successfully decoded Zcode " ) . zcode1 . s:decode_message
            call s:AppendMessageT( msg )
            let s:decode_message = ""
        end

        call setline( s:line_code, s:GenerateCodeLine( s:cur_index, s:c_code, s:c_rev, s:c_file, s:c_repo, s:c_site ) )

        if !correct_generation
            call s:AppendMessageT( "Error: couldn't generate code for current index, selections and meta-data" )
        end

        let [ s:working_area_beg, s:working_area_end ] = s:DiscoverWorkArea()
        call cursor(s:working_area_end+1,1)
        if line(".") != s:working_area_end+1 
            call setline(s:working_area_end+1, "")
            call cursor(s:working_area_end+1,1)
        end
        normal! dG
        if len( s:messages ) - s:last_message_count >= 3
            call s:AppendMessageT("------------ 3 or more messages generated ------------")
        end
        let s:last_message_count = len( s:messages )
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
        let path = substitute( s:cur_repo_path, '[\\/]\+$', "", "" )
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
    " New repository path?
    "

    if a:active == s:ACTIVE_PATH
        let result = matchlist( getline( s:line_repo_data ), s:pat_Repo_Data )
        if len( result ) > 0
            let result[1] = fnamemodify( result[1], ':p' )
            if isdirectory( result[1] )
                let s:cur_repo_path = result[1]
                let s:cur_repo = s:PathToRepo( s:cur_repo_path )
                if s:cur_repo == "(non-standard)"
                    let path = substitute( s:cur_repo_path, '[\\/]\+$', '', 'g' )
                    call s:AppendMessageT( "Loading repository from: " . fnamemodify( path, ':t' ) )
                else
                    call s:AppendMessageT( "Loading repository: " . s:cur_repo )
                end
                call s:DeepRender()
            else
                call s:AppendMessageT("Error: provided path to repository doesn't exist")
                call s:ShallowRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (13)" )
            call s:NormalRender()
        end
        return
    end

    "
    " New repository spec?
    "

    if a:active == s:ACTIVE_REPO_SPEC
        let result = matchlist( getline( s:line_repo_data ), s:pat_Repo_Data )
        if len( result ) > 0
            let cur_repo = result[2]
            let cur_repo_path = s:RepoToPath( cur_repo )
            if cur_repo_path == ""
                call s:AppendMessageT("Error: incorrect repo spec given")
                call s:ShallowRender()
            elseif !isdirectory( cur_repo_path )
                call s:AppendMessageT("Error: repo spec correct, but path it points to doesn't exist")
                call s:ShallowRender()
            else
                let s:cur_repo = cur_repo
                let s:cur_repo_path = cur_repo_path
                call s:AppendMessageT( "Loading repository: " . s:cur_repo )
                call s:DeepRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (13)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Browse?
    "

    if a:active == s:ACTIVE_BROWSE
        execute ":ZMDirvish"
        return
    end

    "
    " New Branch?
    "

    if a:active == s:ACTIVE_NEW_BRANCH
        " Get BTOps line
        let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line
        if len( bt_result ) > 0
            if bt_result[1] != "nop"
                call s:DoNewBranch( bt_result[1] )
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (1)" )
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
        if len( bt_result ) > 0
            if bt_result[2] != "nop"
                call s:DoAddTag( bt_result[2] )
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (2)" )
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
        if len( bt_result ) > 0
            if bt_result[3] != "nop"
                call s:DoDeleteBranch( bt_result[3] )
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (3)" )
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
        if len( bt_result ) > 0
            if bt_result[4] != "nop"
                call s:DoDeleteTag( bt_result[4] )
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (4)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Status ?
    "

    if a:active == s:ACTIVE_STATUS
        let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line
        if len( p_result ) > 0
            if p_result[1] ==? "yes"
                call s:DoStatus()
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (5)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Pull / Push ?
    "

    if a:active == s:ACTIVE_PUSH
        " Get Status line
        let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line
        if len( p_result ) > 0
            if p_result[2] ==? "nop" || p_result[2] ==? "..." || p_result[3] ==? "nop" || p_result[3] ==? "..."
                call s:AppendMessageT("Please set destination (e.g. origin) and branch (e.g. master)")
            else
                call s:DoPush( p_result[2], p_result[3] )
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (6)" )
        end
        call s:NormalRender()
        return
    end

    if a:active == s:ACTIVE_PULL
        " Get Status line
        let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line
        if len( p_result ) > 0
            if p_result[4] ==? "nop" || p_result[4] ==? "..." || p_result[5] ==? "nop" || p_result[5] ==? "..."
                call s:AppendMessageT("Please set source (e.g. origin) and branch (e.g. master)")
            else
                call s:DoPull( p_result[4], p_result[5] )
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (7)" )
        end
        call s:NormalRender()
        return
    end

    "
    " Commit ?
    "

    if a:active == s:ACTIVE_COMMIT
        let r_result = matchlist( getline( s:line_gitops1 ), s:pat_Commit_Reset_Checkout ) " Commit line
        if len( r_result ) > 0
            if r_result[1] ==? "yes"
                call s:DoCommit()
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (8)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Checkout ?
    "

    if a:active == s:ACTIVE_CHECKOUT
        let result = matchlist( getline( s:line_checkout ), s:pat_Commit_Reset_Checkout )
        if len( result ) > 0
            let rev = result[3]
            if s:CheckGitState()
                call s:DoCheckout( rev )
                call s:DeepRender()
            else
                call s:NormalRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (9)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Reset ?
    "

    if a:active == s:ACTIVE_RESET
        let result = matchlist( getline( s:line_reset ), s:pat_Commit_Reset_Checkout )
        if len( result ) > 0
            if result[2] ==? "yes"
                let s:do_reset = "no"
                call s:ResetRepo()
                call s:DeepRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (10)" )
            call s:NormalRender()
        end
        return
    end

    "
    " Read new index?
    "

    if a:active == s:ACTIVE_CURRENT_INDEX
        let result = matchlist( getline( s:line_index ), s:pat_Index )
        if len( result ) > 0
            if s:cur_index != result[1]
                let s:cur_index = result[1]
                call s:ResetCodeSelectors()
                call s:DeepRender()
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (11)" )
            call s:NormalRender()
        end
        return
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
                call s:AppendMessageT( "Set \"Save:\" or \"Reset:\" field to <yes> to write changes to disk or to reset Git repository" )
                call s:ShallowRender()
                return
            end
        else
            call s:AppendMessageT( "Error: control lines modified, cannot use document - will regenerate (12)" )
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
        call s:AppendMessageT("Error: problem during processing of Zekyll list, rereading state from disk")
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
" FUNCTION: GenerateSaveIndexSizeLine() {{{2
fun! s:GenerateSaveIndexSizeLine()
    return "[ Save (<" . s:save . ">) with index size <" . s:index_size_new . "> ]"
endfun
" 2}}}
" FUNCTION: GenerateCommitResetLine() {{{2
fun! s:GenerateCommitResetLine()
    let line = s:RPad( "[ Commit: <" . s:commit. ">", 19) . " ] | " . "[ Reset: <" . s:do_reset . ">"
    if s:do_reset ==? "yes"
        let line = line . " ]   "
    else
        let line = line . "  ]   "
    end
    let line = line . "   | [ Checkout: <" . s:revs[0]. "> ]"
    return line
endfun
" 2}}}
" FUNCTION: GenerateIndexLine() {{{2
fun! s:GenerateIndexLine()
    let pad = 21
    if s:prefix == " "
        let pad = 20
    end
    return s:.prefix . s:RPad( "Consistent: " . s:consistent, pad ) . " | " .
         \ s:RPad( "Errors: " . s:are_errors, 21 ) . " | " .
         \ s:RPad( "[ Current index: <" . s:cur_index. "> ]", 16 )
endfun
" 2}}}
" FUNCTION: GenerateCodeLine() {{{2
fun! s:GenerateCodeLine( index, code, rev, file_name, repo, site )
    let line = "[ Code: " . a:index . "/" . s:RPad( a:code, 10, " " ) . " ] "
    let line = line . "[ Rev: " . s:RPad( a:rev, 7, " " ) . " ] "
    let line = line . "[ File Name: " . s:RPad( a:file_name, 7, " " ) . " ] "
    let line = line . "[ Repo: " . s:RPad( a:repo, 7, " " ) . " ] "
    let line = line . "[ Site: <" . a:site . "> ] ~"
    return line
endfun
" 2}}}
" FUNCTION: GenerateStatusPushPullLine() {{{2
fun! s:GenerateStatusPushPullLine( )
    let line =        s:RPad( "[ Status: <" . s:do_status. ">", 19)  . " ] | "
    let line = line . s:RPad( "[ Push: <"   . s:push_where. ">", 13) . " " . s:RPad( "<"   . s:push_what. ">", 5) . " ] | "
    let line = line . s:RPad( "[ Pull: <"   . s:pull_where. ">", 13) . " " . s:RPad( "<"   . s:pull_what. ">", 5) . " ]"
    return line
endfun
" 2}}}
" FUNCTION: GenerateBTOpsLine() {{{2
fun! s:GenerateBTOpsLine( )
    let line =        s:RPad( "[ New Branch: <"    . s:do_branch. ">", 15)  . " ] | "
    let line = line . s:RPad( "[ Add Tag: <"       . s:do_tag. ">", 15)     . " ]    | "
    let line = line . s:RPad( "[ Delete Branch: <" . s:do_dbranch. ">", 15) . " ] | "
    let line = line . s:RPad( "[ Delete Tag: <"    . s:do_dtag. ">", 15)    . " ]"
    return line
endfun
" 2}}}
" FUNCTION: GenerateRepoDataLine() {{{2
fun! s:GenerateRepoDataLine()
    let path = fnamemodify( s:cur_repo_path, ':~' )
    let path = substitute( path, '[\\/]\+$', '', 'g' )
    return s:RPad( "[ Path: " . path . " ]", 20 ) . s:RPad( " [ Repo spec: " . s:cur_repo . " ]", 15 ) . " [ Browse ] ~"
endfun
" 2}}}
" FUNCTION: ResetControlLines() {{{2
fun! s:ResetControlLines( )
    let index_rdata = s:GenerateRepoDataLine()
    call setline( s:line_repo_data, index_rdata )
    let index_line = s:GenerateIndexLine()
    call setline( s:line_index, index_line )
    let commit_line = s:GenerateCommitResetLine()
    call setline( s:line_reset, commit_line )
    let status_line = s:GenerateStatusPushPullLine()
    call setline( s:line_gitops2, status_line )
    let btops_line = s:GenerateBTOpsLine()
    call setline( s:line_btops, btops_line )
    let save_line = s:GenerateSaveIndexSizeLine()
    call setline( s:line_save, save_line )
    let code_line = s:GenerateCodeLine( s:cur_index, s:c_code, s:c_rev, s:c_file, s:c_repo, s:c_site )
    call setline( s:line_code, code_line )
endfun
" 2}}}
" FUNCTION: IsEditAllowed() {{{2
fun! s:IsEditAllowed()
    let line = line( "." )
    if line == s:line_index || line == s:line_index_size || line == s:line_code || line == s:line_btops || line == s:line_gitops2 || line == s:line_repo_data
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
        if isdirectory( s:home . "/.zekyll/repos" )
            exec "lcd " . s:home . "/.zekyll/repos"
        elseif isdirectory( s:home . "/.zekyll" )
            exec "lcd " . s:home . "/.zekyll"
        end
        exec "file Zekyll\\ Manager"
        let g:_zekyll_bufname = bufname("%")
        let g:_zekyll_bufnr = bufnr("%")
        let retval = 1
    else
        " Try current tab
        let [winnr, all] = s:FindOurWindow( g:_zekyll_bufnr )
        if all > 0
            call s:AppendMessageT( "Welcome back! Using current tab" )
            exec winnr . "wincmd w"
            let retval = 1
        else
            " Try other tab
            let tabpagenr = s:FindOurTab( g:_zekyll_bufnr )
            if tabpagenr != -1
                exec 'normal! ' . tabpagenr . 'gt'
                let [winnr, all] = s:FindOurWindow( g:_zekyll_bufnr )
                if all > 0
                    call s:AppendMessageT( "Welcome back! Switched to already used tab" )
                    exec  winnr . "wincmd w"
                    let retval = 1
                else
                    call s:AppendMessageT( "Unexpected *error* occured, running second instance of Zekyll" . winnr )
                    let retval = 0
                end
            else
                tabnew
                exec ":silent! buffer " . g:_zekyll_bufnr
                call s:AppendMessageT( "Welcome back! Restored our buffer" )
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

    imap <buffer> <silent> <CR> <ESC><CR>

    " Latin, todo few special characters
    for i in range( char2nr('0'), char2nr('[') )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    for i in range( char2nr(']'), char2nr('{') )
        exec 'inoremap <buffer> <expr> ' . nr2char(i) . ' <SID>IsEditAllowed() ? "' . nr2char(i) . '" : ""'
    endfor

    inoremap <buffer> <expr> } <SID>IsEditAllowed() ? "}" : ""
    inoremap <buffer> <expr> / <SID>IsEditAllowed() ? "/" : ""

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

    " File manager, ZMDirvish
    nnoremap <buffer><silent> <Plug>(zmdirvish_up) :<C-U>exe "ZMDirvish %:h".repeat(":h",v:count1)<CR>
    if !hasmapto('<Plug>(zmdirvish_up)', 'n')
        execute 'nmap '.s:nowait.'<buffer> - <Plug>(zmdirvish_up)'
    endif
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
        let pos3 = pos2 + stridx( line2[pos2 :], "|" ) + 1
        let col = col( "." )

        if linenr == s:line_index
            if col > pos2
                call s:ProcessBuffer( s:ACTIVE_CURRENT_INDEX )
            end
            return 1
        elseif linenr == s:line_gitops1
            if col < pos1
                call s:ProcessBuffer( s:ACTIVE_COMMIT )
            elseif col > pos1 && col < pos2
                call s:ProcessBuffer( s:ACTIVE_RESET )
            elseif col > pos2
                call s:ProcessBuffer( s:ACTIVE_CHECKOUT )
            end
            return 1
        elseif linenr == s:line_gitops2
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
            let line2 = substitute( line, '[^]]', "x", "g" )
            let pos1 = stridx( line2, "]" ) + 1
            let pos2 = pos1 + stridx( line2[pos1 :], "]" ) + 1
            let pos3 = pos2 + stridx( line2[pos2 :], "]" ) + 1
            let pos4 = pos3 + stridx( line2[pos3 :], "]" ) + 1

            if col <= pos1
                if s:ComputeCodingState("decode")
                    " Need normal render to regenerate entries,
                    " not only messages, as ShallowRender does
                    call s:NormalRender()
                end
            else
                if s:ComputeCodingState("regenerate")
                    call s:ShallowRender()
                end
            end

        elseif linenr == s:line_save
            call s:ProcessBuffer( s:ACTIVE_SAVE_INDEXSIZE )
            return 1

        elseif linenr == s:line_repo_data
            let line2 = substitute( line, '[^]]', "x", "g" )
            let pos1 = stridx( line2, "]" ) + 1
            let pos2 = pos1 + stridx( line2[pos1 :], "]" ) + 1
            let pos3 = pos2 + stridx( line2[pos2 :], "]" ) + 1

            if col <= pos1
                call s:ProcessBuffer( s:ACTIVE_PATH )
            elseif col > (pos1 + 1) && col <= pos2
                call s:ProcessBuffer( s:ACTIVE_REPO_SPEC )
            elseif col > (pos2 + 1) && col <= pos3
                call s:ProcessBuffer( s:ACTIVE_BROWSE )
            end
        end

        return 0
    elseif linenr < s:working_area_end
       return s:GoToFile()
    end
endfun
" 2}}}
" FUNCTION: ComputeCodingState() {{{2
fun! s:ComputeCodingState( op )
    let correct_buffer = 1

    let new_index = s:cur_index

    if a:op == "regenerate"
        let [ correct_generation, s:c_code ] = s:GenerateCodeFromBuffer()
        if correct_generation
            if s:are_errors ==? "yes"
                let msg = "Erroneously created code"
            else
                let msg = "Succesfully created code"
            end

            " Enumerate used fields
            if s:c_rev != "" || s:c_file != "" || s:c_repo != "" || s:c_site != ""
                let msg = msg . " for"
            end
            let was = 0
            if s:c_rev != ""
                let [ was, msg ] = [ 1, msg . " rev: '" . s:c_rev . "'" ]
            end
            if s:c_file != ""
                let msg = msg . (was ? "," : "")
                let [ was, msg ] = [ 1, msg . " file: '" . s:c_file."'" ]
            end
            if s:c_repo != ""
                let msg = msg . (was ? "," : "")
                let [ was, msg ] = [ 1, msg . " repo: '" . s:c_repo ."'" ]
            end
            if s:c_site != "" && s:c_site != "gh"
                let msg = msg . (was ? "," : "")
                let [ was, msg ] = [ 1, msg . " site: '" . s:c_site."'" ]
            end

            " How many selections message
            let msg = msg . (was ? " and " : " for ")
            let cnt = 0
            for i in range(0, len( s:code_selectors ) - 1)
                let cnt = s:code_selectors[i] ? cnt + 1 : cnt
            endfor
            let msg = msg . "current " . cnt . " selection(s)"

            " Finally append the Zcode
            let msg = msg . ": " . s:cur_index . "/" . s:c_code
            call s:AppendMessageT( msg )
        else
            " TODO: this may not always mean incorrect buffer
            correct_buffer = 0
        end
    elseif a:op == "decode"
        let result = matchlist( getline( s:line_code ), s:pat_Code )
        if len( result ) > 0
            let correct_zcode = 1
            let split_result = split( result[1], "/" )
            if len( split_result ) == 1
                " Code, i.e. no index - or index alone
                if result[1] =~ "/[[:space:]]*$"
                    let new_index = split_result[0]
                    let s:c_code = ""
                else
                    let s:c_code = split_result[0]
                end
            elseif len( split_result ) == 2
                " Zcode, i.e. code with index
                let new_index = split_result[0]
                let s:c_code = split_result[1]
            else
                let correct_zcode = 0
            end

            if correct_zcode
                call s:UpdateStateForZcode( new_index, new_index . "/" . s:c_code )
            else
                call s:AppendMessageT( "Incorrectly formatted Zcode enterred" )
            end
        else
            let correct_buffer = 0
        end
    end

    let call_render = 1

    if !correct_buffer
        if a:op == "decode"
            call s:AppendMessageT( "Error: control lines modified, cannot use document and decode Zcode - will regenerate the document (13)" )
        elseif a:op == "regenerate"
            call s:AppendMessageT( "Error: control lines modified, cannot use document and create Zcode - will regenerate the document (14)" )
        end

        let call_render = 0
        call s:NormalRender()
    else
        " Load new index
        if s:cur_index != new_index
            let s:cur_index = new_index

            let call_render = 0
            call s:DeepRender()
        end
    end

    return call_render
endfun
" 2}}}
" FUNCTION: GenerateCodeFromBuffer() {{{2
" Returns true/false integer denoting status of the operation,
" and in second element of the returned list – string with the
" code generated or kept unchanged
fun! s:GenerateCodeFromBuffer()
    let result = matchlist( getline( s:line_code ), s:pat_Code )
    if len( result ) > 0
        let s:c_rev = result[2]
        let s:c_file = result[3]
        let s:c_repo = result[4]
        let s:c_site = result[5]

        let [ s:c_rev, s:c_file, s:c_repo, s:c_site ] = s:TrimBlanks( s:c_rev, s:c_file, s:c_repo, s:c_site )

        call s:GenerateCodeWasCalled()
        return s:GenerateCodeFromState()
    else
        return [0, s:c_code ]
    end

endfun
" 2}}}
" FUNCTION: GenerateCodeFromState() {{{2
" Generates code from current values of s:c_* variables
" TODO: error handling
fun! s:GenerateCodeFromState()
    let appendix = []
    call extend( appendix, s:BitsStart() )
    call extend( appendix, s:BitsRev(s:c_rev) )
    call extend( appendix, s:BitsFile(s:c_file) )
    call extend( appendix, s:BitsRepo(s:c_repo) )
    call extend( appendix, s:BitsSite(s:c_site) )
    call extend( appendix, s:BitsStop() )
    let appendix = s:BitsRemoveIfStartStop( appendix )

    " Include version bits
    let code_bits = reverse( s:BitsVersion() + copy( s:code_selectors ) )

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

    return [1, resu[1] ]
endfun
" 2}}}
" FUNCTION: UpdateStateForZcode() {{{2
fun! s:UpdateStateForZcode( new_index, zcode )
    let [ error, bits, meta_data ] = s:get_zekyll_bits_for_code( a:zcode )
    if error
        call s:AppendMessageT( "Error when decoding Zcode '" . a:zcode . "', it is probably mistyped and thus inconsistent" )
        return 0
    end

    let problems = 0
    call reverse( bits )
    let new_len = len( bits )
    let cur_len = len( s:code_selectors )

    let s:code_selectors = bits
    let s:c_rev = has_key( meta_data, 'rev' ) ? meta_data['rev'] : ""
    let s:c_file = has_key( meta_data, 'file' ) ? meta_data['file'] : ""
    let s:c_repo = has_key( meta_data, 'repo' ) ? meta_data['repo'] : ""
    if has_key( meta_data, 'site' )
        let site_id = meta_data['site']
        if has_key( s:rsites, site_id )
            let s:c_site = s:rsites[site_id]
        else
            if site_id == ""
                let s:c_site = ""
            else
                call s:AppendMessageT( "Incorrect decoded site: " . site_id . " (should be number 1..3)" )
            end
        end
    end

    " Beginning of message will be set in NormalRender
    let msg = ""

    " Enumerate decoded fields
    if s:c_rev != "" || s:c_file != "" || s:c_repo != "" || (s:c_site != "" && s:c_site != "gh")
        let msg = msg . " with"
    end
    let was = 0
    if s:c_rev != ""
        let [ was, msg ] = [ 1, msg . " rev: '" . s:c_rev . "'" ]
    end
    if s:c_file != ""
        let msg = msg . (was ? "," : "")
        let [ was, msg ] = [ 1, msg . " file: '" . s:c_file."'" ]
    end
    if s:c_repo != ""
        let msg = msg . (was ? "," : "")
        let [ was, msg ] = [ 1, msg . " repo: '" . s:c_repo ."'" ]
    end
    if s:c_site != "" && s:c_site != "gh"
        let msg = msg . (was ? "," : "")
        let [ was, msg ] = [ 1, msg . " site: '" . s:c_site."'" ]
    end

    " How many selections message
    let msg = msg . (was ? " and with " : ". It contained ")
    let cnt = 0
    for i in range(0, len( s:code_selectors ) - 1)
        let cnt = s:code_selectors[i] ? cnt + 1 : cnt
    endfor
    let msg = msg . cnt . " selection(s)"

    " Store the message, it will be displayed in NormalRender
    let s:decode_message = msg

    " Update site to default value when needed
    if s:c_site == ""
        let s:c_site = "gh"
    end
    return 1
endfun
" 2}}}
" FUNCTION: GenerateCodeWasCalled() {{{2
fun! s:GenerateCodeWasCalled( ... )
    " Reset?
    if a:0 && a:1 == 0
        let s:called_GenerateCodeFromState = 0
    " Check?
    elseif a:0 && a:1 == 1
        return s:called_GenerateCodeFromState <= 1
    " Count
    else
        let s:called_GenerateCodeFromState = s:called_GenerateCodeFromState + 1
    end
    return 1
endfun
"1}}}
" FUNCTION: MarkErrorsDuringGeneration() {{{2
fun! s:MarkErrorsDuringGeneration( ... )
    " Reset?
    if a:0 && a:1 == 0
        let s:are_errors = "no"
    " Check?
    elseif a:0 && a:1 == 1
        return s:are_errors ==? "yes"
    " Mark
    else
        let s:are_errors = "YES"
    end
    return 1
endfun
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
        if len( s:code_selectors ) == 0
            call s:ResetCodeSelectors()
        end
    end

    " What's needed is finding maximum zekyll in s:lzsd and
    " then altering s:code_selectors - s:lzsd may be newer
    " than buffer that s:ReadCodes() read, but here it can
    " be compensated - s:code_selectors will be in general
    " inherited, however s:lzsd length will be taken into
    " account (that's the compensation)

    let max_zekyll = s:FindMaxZekyllInLZ( s:lzsd )
    let new_size = ( max_zekyll == "" ) ? 0 : index( s:index_zekylls, max_zekyll )
    if new_size == -1
        call s:AppendMessageT( 'Warning: incorrect zekyll read ("' . max_zekyll . '"), cannot correctly map which zekylls are selected, please reload' )
    else
        let new_size = new_size + 1

        if len( s:code_selectors ) > new_size
            let s:code_selectors = ( new_size == 0 ) ? [] : s:code_selectors[ 0 : new_size-1 ]
        elseif len( s:code_selectors ) < new_size
            let diff = new_size - len( s:code_selectors )
            call extend( s:code_selectors, repeat( [ 0 ], diff ) )
        end
    end

    let s:prev_index = s:cur_index

    let text2 = ""
    let arr = split( a:text, '\n\+' )
    let size = len( arr )
    let i = 0
    while i < size
        let ZCSD = s:BufferLineToZCSD( arr[i] )

        " Get knowledge whether this zekyll is selected
        let selection = 0
        let idx = index( s:index_zekylls, ZCSD[0] )
        if idx == -1
            call s:AppendMessageT( 'Warning: found malformed zekyll ("' . ZCSD[0] . '"), cannot include it in Zcode, will also deselect it' )
        else
            " We now have a mapping of zekyll into its location
            " in s:code_selectors - use it
            let selection = s:code_selectors[ idx ]
        end

        let listing = s:ZSDToListing( s:ZcsdToZsd( ZCSD ) )
        let line = s:BuildLineFromFullEntry( s:ZcsdToLzds( ZCSD, listing ), selection )
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
        call s:DebugMsgT( 1, "Error: ZcsdToZsd given list of size: " . len( a:zcsd ) )
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

    let max_zekyll = s:FindMaxZekyllInLZ( new_lzcsd )
    " Will hold selection state of each occurred zekyll
    " to be read in order as are zekylls in s:index_zekylls
    let selectionMap = {}

    let sel_count = 0
    let size = len(new_lzcsd)
    let i = 0
    while i < size
        let zekyll = new_lzcsd[i][1]
        if new_lzcsd[i][2] == " "
            let selection = 0
        else
            let selection = 1
            let sel_count = sel_count + 1
        end
        if has_key( selectionMap, zekyll )
            " Report once per session
            if index( s:reported_duplicate_zekylls, zekyll ) == -1
                call add( s:reported_duplicate_zekylls, zekyll )
                call s:AppendMessageT( "Warning: duplicate zekyll found (" . zekyll . "), Zcode will take into account only last duplicate zekyll" )
            end
        end
        let selectionMap[ zekyll ] = selection
        let i = i + 1
    endwhile

    " Read selectionMap in order as are zekylls in s:index_zekylls
    if max_zekyll != ""
        for i in range( 0, len( s:index_zekylls ) - 1 )
            let zekyll = s:index_zekylls[ i ]
            let selection = get( selectionMap, zekyll, 0 )
            call add( s:code_selectors, selection )
            if zekyll == max_zekyll
                break
            end
        endfor
    end

    return sel_count
endfun
" 2}}}
" FUNCTION: FindMaxZekyllInLZ() {{{2
fun! s:FindMaxZekyllInLZ( lzcsde )
    let max_zekyll = ""
    for i in range( 0, len( a:lzcsde ) - 1 )
        if max_zekyll < a:lzcsde[i][1]
            let max_zekyll = a:lzcsde[i][1]
        end
    endfor
    return max_zekyll
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
        " At which line: save, commit, index, status, BTOps, code?
        let s_result = matchlist( line, s:pat_Save_IndexSize )          " Save line
        let r_result = matchlist( line, s:pat_Commit_Reset_Checkout )   " Commit line
        let i_result = matchlist( line, s:pat_Index )                   " Index line
        let p_result = matchlist( line, s:pat_Status_Push_Pull )        " Status line
        let bt_result = matchlist( line, s:pat_BTOps )                  " BTOps line
        let st_result = matchlist( line, s:pat_Code )                   " Code line

        " Index line (1)
        if len( i_result ) > 0

            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line
            
            " Get Commit line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Commit_Reset_Checkout ) " Commit line

            " Get Status line
            unlet p_result
            let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( r_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let col = col( "." )
                if col > pos2
                    call s:TurnOff()
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                " Redraw Control Lines
                call s:ResetControlLines()
            else
                return 0
            end
        " Commit line (2)
        elseif len( r_result ) > 0

            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Index line
            unlet i_result
            let i_result = matchlist( getline( s:line_index ), s:pat_Index ) " Index line

            " Get Status line
            unlet p_result
            let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( i_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                let line2 = substitute( line, '[^|]', "x", "g" )
                let pos1 = stridx( line2, "|" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "|" ) + 1
                let col = col( "." )
                if col < pos1
                    if r_result[1] ==? "yes"
                        let s:commit = "no"
                    else
                        call s:TurnOff()
                        let s:commit = "yes"
                    end
                elseif col > pos1 && col < pos2
                    if r_result[2] ==? "yes"
                        let s:do_reset = "no"
                    else
                        call s:TurnOff()
                        let s:do_reset = "yes"
                    end
                elseif col > pos2
                    let choices = s:revs[2]
                    let s:revs[0] = s:IterateOver( choices, s:revs[0] )

                    " Only one button in use
                    call s:TurnOff()
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                " Redraw Control Lines
                call s:ResetControlLines()
            else
                return 0
            end
        " Status line (3)
        elseif len( p_result ) > 0
            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Commit line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Commit_Reset_Checkout ) " Commit line

            " Get Index line
            unlet i_result
            let i_result = matchlist( getline( s:line_index ), s:pat_Index ) " Index line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( s_result ) > 0 && len( i_result ) > 0 && len( r_result ) > 0 && len( bt_result ) > 0
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
                        let choices = [ "nop" ] + s:revs[3] + [ "..." ]
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
                        let choices = [ "nop" ] + s:revs[3] + [ "..." ]
                        let s:pull_what = s:IterateOver( choices, p_result[5] )

                        if s:pull_what !=? "nop"
                            call s:TurnOff("NoPull")
                        end
                    end
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                " Redraw Control Lines
                call s:ResetControlLines()
            else
                return 0
            end
        " BTOps line? (4)
        elseif len( bt_result ) > 0
            " Get Save line
            unlet s_result
            let s_result = matchlist( getline( s:line_save ), s:pat_Save_IndexSize ) " Save line

            " Get Commit line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Commit_Reset_Checkout ) " Commit line

            " Get Index line
            unlet i_result
            let i_result = matchlist( getline( s:line_index ), s:pat_Index ) " Index line

            " Get Status line
            unlet p_result
            let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line

            if len( s_result ) > 0 && len( r_result ) > 0 && len( i_result ) > 0 && len( p_result )
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

                " Redraw Control Lines
                call s:ResetControlLines()
            end
        " Save line? (5)
        elseif len( s_result ) > 0

            " Get Commit line
            unlet r_result
            let r_result = matchlist( getline( s:line_reset ), s:pat_Commit_Reset_Checkout ) " Commit line

            " Get Index line
            unlet i_result
            let i_result = matchlist( getline( s:line_index ), s:pat_Index ) " Index line

            " Get Status line
            unlet p_result
            let p_result = matchlist( getline( s:line_gitops2 ), s:pat_Status_Push_Pull ) " Status line

            " Get BTOps line
            unlet bt_result
            let bt_result = matchlist( getline( s:line_btops ), s:pat_BTOps ) " BTOps line

            if len( r_result ) > 0 && len( i_result ) > 0 && len( p_result ) > 0 && len( bt_result ) > 0
                if s_result[1] ==? "yes"
                    let s:save = "no"
                else
                    call s:TurnOff()
                    let s:save = "yes"
                end

                " Get current index size so that it can be preserved
                let s:index_size_new = s_result[2]

                " Redraw Control Lines
                call s:ResetControlLines()
            else
                return 0
            end
        " Code line? (6)
        elseif len( st_result ) > 0
                let line2 = substitute( line, '[^[]', "x", "g" )
                let pos1 = stridx( line2, "[" ) + 1
                let pos2 = pos1 + stridx( line2[pos1 :], "[" ) + 1
                let pos3 = pos2 + stridx( line2[pos2 :], "[" ) + 1
                let pos4 = pos3 + stridx( line2[pos3 :], "[" ) + 1
                let pos5 = pos4 + stridx( line2[pos4 :], "[" ) + 1
                let col = col( "." )

                if col > pos5
                    let choices = [ "gh", "bb", "gl" ]
                    let s:c_site = s:IterateOver( choices, st_result[5] )

                    " Redraw Control Lines
                    call s:ResetControlLines()
                end
        end
    elseif linenr > s:working_area_beg
        let ZCSD = s:BufferLineToZCSD( line )

        if len( ZCSD ) == 0
            return 0
        end

        if ZCSD[1] != " "
            let selector = 0
        else
            let selector = 1
        end

        " Find this line's location in s:code_selectors
        let idx = index( s:index_zekylls, ZCSD[0] )
        if idx == -1
            call s:AppendMessageT( 'Warning: found malformed zekyll ("' . ZCSD[0] . '"), cannot include it in Zcode, will also deselect it' )
            let selector = 0
        else
            " We now have a mapping of zekyll into its location
            " in s:code_selectors - use it
            let s:code_selectors[ idx ] = selector
        end

        let listing = s:ZSDToListing( s:ZcsdToZsd( ZCSD ) )
        let line = s:BuildLineFromFullEntry( s:ZcsdToLzds( ZCSD, listing ), selector )

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

    let length = s:longest_lzsd > 45 ? s:longest_lzsd : 45
    if( a:top == 1 )
        return s:RPad( s:beg_of_warea_char, length + delta, s:beg_of_warea_char )
    else
        return s:RPad( s:end_of_warea_char, length + delta, s:end_of_warea_char )
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
" FUNCTION: TrimBlanks() {{{2
fun! s:TrimBlanks( ... )
    let result = []
    for entry in a:000
        let new_entry = substitute( entry, "^[[:space:]]*", "", "" )
        let new_entry = substitute( new_entry, "[[:space:]]*$", "", "" )
        call add( result, new_entry )
    endfor

    return result
endfun
" 2}}}
" FUNCTION: SetupSyntaxHighlighting() {{{2
fun! s:SetupSyntaxHighlighting()
    setlocal ft=help
    syn match helpOption          "'.\{-1,\}'"
    syn match helpType            "(err:0)"
    syn match helpHyperTextJump   "(err:-\?[1-9]\d*)"
    syn match helpHyperTextJump   "Error:"
    syn match helpUnderlined      "\d\+/[a-z0-9]\+"
    syn match helpOption          '--\+ 3 or more .* --\+'
endfun
" 2}}}
" FUNCTION: PathToRepo() {{{2
fun! s:PathToRepo( path )
    let path = substitute( a:path, '[\\/]\+$', '', 'g' )
    let result = matchlist( path, '\([a-z0-9][a-z0-9]\)---\([a-zA-Z0-9][a-zA-Z0-9-]*\)---\([a-zA-Z0-9_-]\+\)---\([a-zA-Z0-9_/.~-]\+\)$' )
    if len( result ) > 0
        let repo = ""
        if result[1] !=? "gh"
            let repo = result[1] . "@"
        end
        let repo = repo . result[2]

        " Repo is appended when it is not "zkl"
        " or when branch is not "master"
        if result[3] !=? "zkl" || result[4] !=? "master"
            let repo = repo . "/" . result[3]
        end

        if result[4] !=? "master"
            let repo = repo . "/" . result[4]
        end
    else
        let repo = "(non-standard)"
    end

    return repo
endfun
" 2}}}
" FUNCTION: RepoToPath() {{{2
fun! s:RepoToPath( repo )
    let last_node = ""
    let path = ""

    " xy@user/repo/rev
    let result = matchlist( a:repo, '^\([a-zA-Z][a-zA-Z]\)@\([a-zA-Z0-9][a-zA-Z0-9-]*\)[/]\([a-zA-Z0-9_-]\+\)[/]\([a-zA-Z0-9_-]\+\)$' )
    if len( result ) > 0
        let last_node = result[1] . "---" . result[2] . "---" . result[3] . "---" . result[4]
    else
        " user/repo/rev
        let result = matchlist( a:repo, '^\([a-zA-Z0-9][a-zA-Z0-9-]*\)[/]\([a-zA-Z0-9_-]\+\)[/]\([a-zA-Z0-9_-]\+\)$' )
        if len( result ) > 0
            let last_node = "gh---" . result[1] . "---" . result[2] . "---" . result[3]
        else
            " xy@user/repo
            let result = matchlist( a:repo, '^\([a-zA-Z][a-zA-Z]\)@\([a-zA-Z0-9][a-zA-Z0-9-]*\)[/]\([a-zA-Z0-9_-]\+\)$' )
            if len( result ) > 0
                let last_node = result[1] . "---" . result[2] . "---" . result[3] . "---master"
            else
                " user/repo
                let result = matchlist( a:repo, '^\([a-zA-Z0-9][a-zA-Z0-9-]*\)[/]\([a-zA-Z0-9_-]\+\)$' )
                if len( result ) > 0
                    let last_node = "gh---" . result[1] . "---" . result[2] . "---master"
                end
            end
        end
    end

    if last_node != ""
        let path = fnamemodify( s:repos_paths[0], ':p' ) . last_node
    end

    return path
endfun
" 2}}}
" 1}}}
" Backend functions {{{1
" FUNCTION: ReadRepo {{{2
fun! s:ReadRepo()
    let listing_text = system( "zkiresize --req -p " . shellescape(s:cur_repo_path) . " -i " . s:cur_index . " -q --consistent")
    if v:shell_error == 11
        let s:inconsistent_listing = split(listing_text, '\n\+')
        let s:inconsistent_listing= s:inconsistent_listing[1:]
        let listing_text = system( "zkiresize --req -p " . shellescape(s:cur_repo_path) . " -i " . s:cur_index . " -q -l")
        let s:listing = split(listing_text, '\n\+')
        call s:AppendMessageT( "Inconsistent Listing: >", map(copy(s:inconsistent_listing), '" " . v:val') )
        call s:DebugMsgT( 0, "All Listing: ", s:listing )
        let s:consistent = "NO"
    else
        let s:listing = split(listing_text, '\n\+')
        let s:listing= s:listing[1:]
        let s:consistent = "yes"

        call s:DebugMsgT(0, "Listing:", s:listing)
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
    let sum_shell_error = 0
    for entry in a:lzsd
        let entry[3] = substitute( entry[3], " ", "_", "g" )
        let file_name = entry[1] . "." . entry[2] . "--" . entry[3]

        let cmd = "git -C ".shellescape( s:cur_repo_path ). " rm -f " . shellescape( entry[0] )
        let cmd_output = system( cmd )
        let arr = split( cmd_output, '\n\+' )

        call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )
        let result = result + v:shell_error

        " Message
        call add( delarr, "(err:" . v:shell_error . ") {" . entry[1] . "." . entry[2] . "} " . entry[3] )
    endfor

    if result > 0
        let s:are_errors = "YES"
    end

    " Message
    if len( delarr ) == 1
        call s:AppendMessageT( "Deleted: " . delarr[0] )
    elseif len( delarr ) >= 2
        call map( delarr, '" *>* " . v:val' )
        call s:AppendMessageT( "Deleted: ", delarr )
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
        let old_file_name = entry[0][0]
        let new_file_name = entry[1][1] . "." . entry[1][2] . "--" . entry[1][3]
        let cmd = "git -C " . shellescape( s:cur_repo_path ) . " mv " . shellescape(old_file_name) . " " . shellescape(new_file_name)

        let cmd_output = system( cmd )
        let arr = split( cmd_output, '\n\+' )

        call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr )
        let result = result + v:shell_error

        " Message
        call add( renarr, "(err:" . v:shell_error . ") {" . entry[0][1] . "." . entry[0][2] . "} " . entry[0][3] .
                \ " -> {" . entry[1][1] . "." . entry[1][2] . "} " . entry[1][3] )
    endfor

    if result > 0
        let s:are_errors = "YES"
    end

    " Message
    if len( renarr ) == 1
        if result > 0
            call s:AppendMessageT( "Error: problem during rename: " . renarr[0] )
        else
            call s:AppendMessageT( "Renamed: " . renarr[0] )
        end
    elseif len( renarr ) >= 2
        call map( renarr, '" *>* " . v:val' )
        if result >0
            call s:AppendMessageT( "Error: problems during rename: ", renarr )
        else
            call s:AppendMessageT( "Renamed: ", renarr )
        end
    end

    return result
endfun
" 2}}}
" FUNCTION: IndexChangeSize() {{{2
fun! s:IndexChangeSize()
    if s:index_size == s:index_size_new
        return
    end

    let cmd = "zkiresize -p " . shellescape(s:cur_repo_path) . " -i " . s:cur_index .
                \ " -q -w -n -s " . s:index_size_new . " --desc 'New Zekyll' --section Z"
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
        call s:AppendMessageT( "Error: during index {" . s:cur_index . "} " . msg .  " (from |" . s:index_size .
                               \ "| to |" . s:index_size_new . "| zekylls):", " *>* (err:" . v:shell_error . ") " . error_decode )
    else
        if s:index_size_new > s:index_size
            let msg="Extended"
        else
            let msg="Shrinked"
        end
        call s:AppendMessageT( msg . " index {" . s:cur_index . "} from |" . s:index_size . "| to |" . s:index_size_new . "| zekylls" )
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
        call s:AppendMessageT( "(err:" . v:shell_error . ") Repository reset successfully" )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem occured during repository reset" )
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
        call s:AppendMessageT( "(err:" . v:shell_error . ") Commit ended successfully (Ctrl-G to see Git's output)" )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem during commit. Press Ctrl-G to view Git's output." )
    end
endfun
" 2}}}
" FUNCTION: DoCheckout() {{{2
fun! s:DoCheckout(rev)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " checkout " . shellescape(a:rev)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    
    let pattern="Note:\\|HEAD\\ is\\ now\\|Previous\\ HEAD\\|Switched\\ to\\|Already on\\|error:"
    call filter(arr, 'v:val =~ pattern')

    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Checkout successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with checkout >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoStatus() {{{2
fun! s:DoStatus()
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " status -b --porcelain"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    
    let cmd = "git -C " . shellescape( s:cur_repo_path ) .
            \ " for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(refname:short) - %(objectname:short) - %(contents:subject) - %(authorname) (%(committerdate:relative))'"

    let cmd_output = system( cmd )
    call extend( arr, split( cmd_output, '\n\+' ) )

    if v:shell_error == 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Status successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with status >", arr )
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
        call s:AppendMessageT( "(err:" . v:shell_error . ") Pull " . source . " " . branch . " successful >", arr )
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with pull " . source . " " . branch . " >", arr )
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

    " Get status of what is going to be done
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " status -sb"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " diff origin/" . branch . ".." . branch . " --name-status"
    let cmd_output = system( cmd )
    if len( split( cmd_output, '\n\+' ) ) > 0
        call extend( arr, split( cmd_output, '\n\+' ) )

        let cmd = "git -C " . shellescape( s:cur_repo_path ) . " log --pretty=\"format:%ad %h (%an): %s\" --max-count=3 --date=relative origin/" . branch . ".." . branch
        let cmd_output = system( cmd )
        call extend( arr, split( cmd_output, '\n\+' ) )

        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "Changes to be pushed for branch '" . branch . "': >", arr )
    end

    " Execute the push Git command
    let cmd = ":!echo \"===============================================\" && git -C " . 
            \ shellescape( s:cur_repo_path ) . " push " . shellescape( destination ) . " " . shellescape( branch )
    exec cmd
    let error = v:shell_error

    if error == 0
        call s:AppendMessageT( "(err:" . error . ") Push " . destination . " " . branch . " successful. Use Ctrl-G to see Git's output" )
    else
        call s:AppendMessageT( "(err:" . error . ") Problem with push " . destination . " " . branch . ". Use Ctrl-G to see Git's output" )
    end
endfun
" 2}}}
" FUNCTION: CheckGitState() {{{2
" Will check if there are any unsaved operations
fun! s:CheckGitState()
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " status --porcelain"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    let pattern = '^[MARCDU]\|\ [MAUD]'
    call filter(arr, 'v:val =~ pattern')

    if len( arr ) > 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "Please commit or reset before checking out other rev. The problematic, uncommited files are: >", arr )
        return 0
    else
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "Allowed to perform checkout >", arr )
        return 1
    end
    return 1
endfun
" 2}}}
" FUNCTION: ListAllRevs() {{{2
fun! s:ListAllRevs()
    "
    " Branch
    "

    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " branch --list --no-color"
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )

    if v:shell_error != 0
        call map( arr, '" " . v:val' )
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with branch --list >", arr )
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
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with tag -l >", arr2 )
    end
    call s:DebugMsgT( v:shell_error > 0, " Command [" . v:shell_error . "]: " . cmd, arr2 )

    "
    " Post-processing
    "

    " Find active branch
    let arr1 = []
    let active = ""
    let detached = 0
    for rev in arr
        if rev =~ "^\*.*"
            let rev = substitute( rev, "^\* ", "", "" )
            if rev =~ "(.*)"
                let detached = 1
                let rev = substitute( rev, '(HEAD detached at \(.*\))', '\1', "" )
            end
            let active = rev
        end
        call add( arr1, rev )
    endfor

    " Remove whitespace from all arr1 and arr2 elements
    call map( arr1, 'substitute( v:val, "^ \\+", "", "g" )' )
    call map( arr2, 'substitute( v:val, "^ \\+", "", "g" )' )

    " Make rev list unique
    let all = sort(arr1 + arr2)
    let all = filter(copy(all), 'index(all, v:val, v:key+1)==-1')

    return [ active, detached, all, arr1, arr2 ]
endfun
" 2}}}
" FUNCTION: DoNewBranch() {{{2
fun! s:DoNewBranch(rev)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " checkout -b " . shellescape(a:rev)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "(err:" . v:shell_error . ") Checkout -b successful >", arr )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with checkout -b >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoAddTag() {{{2
fun! s:DoAddTag(rev)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " tag " . shellescape(a:rev)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "(err:" . v:shell_error . ") Tag successful", arr )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with tag >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoDeleteBranch() {{{2
fun! s:DoDeleteBranch(rev)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " branch -d " . shellescape(a:rev)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "(err:" . v:shell_error . ") Branch -d successful >", arr )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with branch -d >", arr )
    end
endfun
" 2}}}
" FUNCTION: DoDeleteTag() {{{2
fun! s:DoDeleteTag(rev)
    let cmd = "git -C " . shellescape( s:cur_repo_path ) . " tag -d " . shellescape(a:rev)
    let cmd_output = system( cmd )
    let arr = split( cmd_output, '\n\+' )
    call map( arr, '" " . v:val' )

    if v:shell_error == 0
        call s:AppendMessageT( "(err:" . v:shell_error . ") Tag -d successful >", arr )
    else
        call s:AppendMessageT( "(err:" . v:shell_error . ") Problem with tag -d >", arr )
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
" FUNCTION: BitsVersion() {{{2
fun! s:BitsVersion()
    " Version 1
    return [ 0, 0 ]
endfun
" 2}}}
" FUNCTION: BitsRev() {{{2
fun! s:BitsRev( rev )
    let bits = []

    let rev = deepcopy( a:rev )

    for lt in split( rev, '\zs' )
        if has_key( s:bits, lt )
            call extend( bits, s:bits[lt] )
        else
            " Avoid double messages
            if s:GenerateCodeWasCalled(1)
                call s:MarkErrorsDuringGeneration()
                call s:AppendMessageT( "Incorrect character in rev name: `" . lt . "'" )
            end
        end
    endfor

    " Rev preamble
    if len( bits ) > 0
        let bits = s:bits['rev'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsFile() {{{2
fun! s:BitsFile( file )
    let bits = []

    let file = deepcopy( a:file )

    for lt in split( file, '\zs' )
        if has_key( s:bits, lt )
            call extend( bits, s:bits[lt] )
        else
            " Avoid double messages
            if s:GenerateCodeWasCalled(1)
                call s:MarkErrorsDuringGeneration()
                call s:AppendMessageT( "Incorrect character in file name: `" . lt . "'" )
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

    for lt in split( repo, '\zs' )
        if has_key( s:bits, lt )
            call extend( bits, s:bits[lt] )
        else
            " Avoid double messages
            if s:GenerateCodeWasCalled(1)
                call s:MarkErrorsDuringGeneration()
                call s:AppendMessageT( "Incorrect character in repo name: `" . lt . "'" )
            end
        end
    endfor

    " Repo preamble
    if len( bits ) > 0
        let bits = s:bits['repo'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsSite() {{{2
fun! s:BitsSite( site )
    let bits = []

    let site = deepcopy( a:site )

    " Github is the default site
    if site == "gh"
        return bits
    end

    if has_key( s:sites, site )
        let lt = s:sites[site]
        call extend( bits, s:bits[lt] )
    else
        " Avoid double messages
        if s:GenerateCodeWasCalled(1)
            call s:MarkErrorsDuringGeneration()
            call s:AppendMessageT( "Incorrect site: `" . site . "'" )
        end
    end

    " Site preamble
    if len( bits ) > 0
        let bits = s:bits['site'] + bits
    end

    return bits
endfun
" 2}}}
" FUNCTION: BitsRemoveIfStartStop() {{{2
" This function removes any SS bits if meta-data is empty
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
    if len( a:long_bits ) < len( a:short_bits )
        return 0
    end
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
" 1}}}
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
    while workingvar !~ "^0*$"
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
" reply - [ bits to skip, { file : "", rev : "", repo : "", wordrev : "", chksum : "", site : "",
"                           unused1 : "", unused2 : "", unused3 : "", error : "" } ]
fun! s:process_meta_data( bits )
    let bits = reverse( deepcopy( a:bits ) )
    let strbits = join( bits, "" )
    let init_len = len( strbits )
    let to_skip = 0

    let decoded = {
      \  "file"     : "",
      \  "rev"      : "",
      \  "repo"     : "",
      \  "wordrev"  : "",
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
            elseif mat == "file" || mat == "rev" || mat == "repo" || mat == "wordrev" || mat == "chksum" || mat == "site"
                let current_selector = mat
            elseif mat == "unused1" || mat == "unused2" || mat == "unused3"
                let current_selector = mat
            else
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
" Also gets meta data: rev, file, repo
" and puts it into return array [ bits,
" meta_data ]
"
fun! s:get_zekyll_bits_for_code( zcode )
    let error = 1
    let bits = []
    let meta_reply = {}

    if a:zcode !~ '^\d\+/[[:space:]]*$' && a:zcode !~ '^\d\+/0*$'
        let bits = s:decode_zcode ( a:zcode )
        if len( bits ) > 0
            let [ to_skip, meta_reply ] = s:process_meta_data( bits )
            " meta_reply contains: { file : "", rev : "", repo : "", wordrev : "", chksum : "", site : "",
            "                        unused1 : "", unused2 : "", unused3 : "", error : "" }
            " to_skip contains: number of final bits that contained the meta data

            if to_skip != -1
                " Skip bits that were processed as meta data
                let bits = bits[ 0 : -1*to_skip-1 ]
                let error = 0
            end

            " Two last bits here are version
            let bits = bits[ 0 : -3 ]
        end
    else
        " Empty Zcode, signal no error, return empty data structures
        let error = 0
    end

    return [ error, bits, meta_reply ]
endfun
" 2}}
" 1}}}
" 1}}}
" ------------------------------------------------------------------------------

let s:sites = {
\ "gh" : "1",
\ "bb" : "2",
\ "gl" : "3",
\ }

let s:rsites = {
\ "1" : "gh",
\ "2" : "bb",
\ "3" : "gl",
\ }

let s:bits = {
\ "ss"         :  [ 1,0,1,0,0,0 ],
\ "file"       :  [ 1,0,0,1,1,1 ],
\ "rev"        :  [ 1,0,1,1,1,0 ],
\ "repo"       :  [ 1,0,1,1,1,1 ],
\ "wordrev"    :  [ 1,0,1,1,0,0 ],
\ "chksum"     :  [ 1,0,1,1,0,1 ],
\ "site"       :  [ 1,0,0,0,1,0 ],
\ "unused1"    :  [ 1,0,0,0,1,1 ],
\ "unused2"    :  [ 1,0,0,0,0,0 ],
\ "unused3"    :  [ 1,1,0,0,1,1,0 ],
\ "b"          :  [ 1,1,0,0,0,1 ],
\ "a"          :  [ 1,1,0,0,0,0 ],
\ "9"          :  [ 1,0,1,0,1,1 ],
\ "8"          :  [ 1,0,1,0,1,0 ],
\ "."          :  [ 1,0,1,0,0,1 ],
\ "/"          :  [ 1,0,0,1,1,0 ],
\ "_"          :  [ 1,0,0,1,0,1 ],
\ "-"          :  [ 1,0,0,1,0,0 ],
\ "~"          :  [ 1,0,0,0,0,1 ],
\ "x"          :  [ 0,1,1,1,1,1 ],
\ "w"          :  [ 0,1,1,1,1,0 ],
\ "z"          :  [ 0,1,1,1,0,1 ],
\ "y"          :  [ 0,1,1,1,0,0 ],
\ "t"          :  [ 0,1,1,0,1,1 ],
\ "s"          :  [ 0,1,1,0,1,0 ],
\ "v"          :  [ 0,1,1,0,0,1 ],
\ "u"          :  [ 0,1,1,0,0,0 ],
\ "5"          :  [ 0,1,0,1,1,1 ],
\ "4"          :  [ 0,1,0,1,1,0 ],
\ "7"          :  [ 0,1,0,1,0,1 ],
\ "6"          :  [ 0,1,0,1,0,0 ],
\ "1"          :  [ 0,1,0,0,1,1 ],
\ "0"          :  [ 0,1,0,0,1,0 ],
\ "3"          :  [ 0,1,0,0,0,1 ],
\ "2"          :  [ 0,1,0,0,0,0 ],
\ "h"          :  [ 0,0,1,1,1,1 ],
\ "g"          :  [ 0,0,1,1,1,0 ],
\ "j"          :  [ 0,0,1,1,0,1 ],
\ "i"          :  [ 0,0,1,1,0,0 ],
\ "d"          :  [ 0,0,1,0,1,1 ],
\ "c"          :  [ 0,0,1,0,1,0 ],
\ "f"          :  [ 0,0,1,0,0,1 ],
\ "e"          :  [ 0,0,1,0,0,0 ],
\ "p"          :  [ 0,0,0,1,1,1 ],
\ "o"          :  [ 0,0,0,1,1,0 ],
\ "r"          :  [ 0,0,0,1,0,1 ],
\ "q"          :  [ 0,0,0,1,0,0 ],
\ "l"          :  [ 0,0,0,0,1,1 ],
\ "k"          :  [ 0,0,0,0,1,0 ],
\ "n"          :  [ 0,0,0,0,0,1 ],
\ "m"          :  [ 0,0,0,0,0,0 ],
\ "J"          :  [ 1,1,1,1,1,1,1 ],
\ "I"          :  [ 1,1,1,1,1,1,0 ],
\ "L"          :  [ 1,1,1,1,1,0,1 ],
\ "K"          :  [ 1,1,1,1,1,0,0 ],
\ "F"          :  [ 1,1,1,1,0,1,1 ],
\ "E"          :  [ 1,1,1,1,0,1,0 ],
\ "H"          :  [ 1,1,1,1,0,0,1 ],
\ "G"          :  [ 1,1,1,1,0,0,0 ],
\ "R"          :  [ 1,1,1,0,1,1,1 ],
\ "Q"          :  [ 1,1,1,0,1,1,0 ],
\ "T"          :  [ 1,1,1,0,1,0,1 ],
\ "S"          :  [ 1,1,1,0,1,0,0 ],
\ "N"          :  [ 1,1,1,0,0,1,1 ],
\ "M"          :  [ 1,1,1,0,0,1,0 ],
\ "P"          :  [ 1,1,1,0,0,0,1 ],
\ "O"          :  [ 1,1,1,0,0,0,0 ],
\ "Z"          :  [ 1,1,0,1,1,1,1 ],
\ "Y"          :  [ 1,1,0,1,1,1,0 ],
\ " "          :  [ 1,1,0,1,1,0,1 ],
\ "A"          :  [ 1,1,0,1,1,0,0 ],
\ "V"          :  [ 1,1,0,1,0,1,1 ],
\ "U"          :  [ 1,1,0,1,0,1,0 ],
\ "X"          :  [ 1,1,0,1,0,0,1 ],
\ "W"          :  [ 1,1,0,1,0,0,0 ],
\ "B"          :  [ 1,1,0,0,1,1,1 ],
\ "D"          :  [ 1,1,0,0,1,0,1 ],
\ "C"          :  [ 1,1,0,0,1,0,0 ],
\ }

let s:codes={
\ "ss"         :  "101000",
\ "file"       :  "100111",
\ "rev"        :  "101110",
\ "repo"       :  "101111",
\ "wordrev"    :  "101100",
\ "chksum"     :  "101101",
\ "site"       :  "100010",
\ "unused1"    :  "100011",
\ "unused2"    :  "100000",
\ "unused3"    :  "1100110",
\ "b"          :  "110001",
\ "a"          :  "110000",
\ "9"          :  "101011",
\ "8"          :  "101010",
\ "."          :  "101001",
\ "/"          :  "100110",
\ "_"          :  "100101",
\ "-"          :  "100100",
\ "~"          :  "100001",
\ "x"          :  "011111",
\ "w"          :  "011110",
\ "z"          :  "011101",
\ "y"          :  "011100",
\ "t"          :  "011011",
\ "s"          :  "011010",
\ "v"          :  "011001",
\ "u"          :  "011000",
\ "5"          :  "010111",
\ "4"          :  "010110",
\ "7"          :  "010101",
\ "6"          :  "010100",
\ "1"          :  "010011",
\ "0"          :  "010010",
\ "3"          :  "010001",
\ "2"          :  "010000",
\ "h"          :  "001111",
\ "g"          :  "001110",
\ "j"          :  "001101",
\ "i"          :  "001100",
\ "d"          :  "001011",
\ "c"          :  "001010",
\ "f"          :  "001001",
\ "e"          :  "001000",
\ "p"          :  "000111",
\ "o"          :  "000110",
\ "r"          :  "000101",
\ "q"          :  "000100",
\ "l"          :  "000011",
\ "k"          :  "000010",
\ "n"          :  "000001",
\ "m"          :  "000000",
\ "J"          :  "1111111",
\ "I"          :  "1111110",
\ "L"          :  "1111101",
\ "K"          :  "1111100",
\ "F"          :  "1111011",
\ "E"          :  "1111010",
\ "H"          :  "1111001",
\ "G"          :  "1111000",
\ "R"          :  "1110111",
\ "Q"          :  "1110110",
\ "T"          :  "1110101",
\ "S"          :  "1110100",
\ "N"          :  "1110011",
\ "M"          :  "1110010",
\ "P"          :  "1110001",
\ "O"          :  "1110000",
\ "Z"          :  "1101111",
\ "Y"          :  "1101110",
\ " "          :  "1101101",
\ "A"          :  "1101100",
\ "V"          :  "1101011",
\ "U"          :  "1101010",
\ "X"          :  "1101001",
\ "W"          :  "1101000",
\ "B"          :  "1100111",
\ "D"          :  "1100101",
\ "C"          :  "1100100",
\ }

" Reverse map of Huffman codes
let s:rcodes = {
\  "101000"    :   "ss",
\  "100111"    :   "file",
\  "101110"    :   "rev",
\  "101111"    :   "repo",
\  "101100"    :   "wordrev",
\  "101101"    :   "chksum",
\  "100010"    :   "site",
\  "100011"    :   "unused1",
\  "100000"    :   "unused2",
\  "1100110"    :  "unused3",
\  "110001"    :   "b",
\  "110000"    :   "a",
\  "101011"    :   "9",
\  "101010"    :   "8",
\  "101001"    :   ".",
\  "100110"    :   "/",
\  "100101"    :   "_",
\  "100100"    :   "-",
\  "100001"    :   "~",
\  "011111"    :   "x",
\  "011110"    :   "w",
\  "011101"    :   "z",
\  "011100"    :   "y",
\  "011011"    :   "t",
\  "011010"    :   "s",
\  "011001"    :   "v",
\  "011000"    :   "u",
\  "010111"    :   "5",
\  "010110"    :   "4",
\  "010101"    :   "7",
\  "010100"    :   "6",
\  "010011"    :   "1",
\  "010010"    :   "0",
\  "010001"    :   "3",
\  "010000"    :   "2",
\  "001111"    :   "h",
\  "001110"    :   "g",
\  "001101"    :   "j",
\  "001100"    :   "i",
\  "001011"    :   "d",
\  "001010"    :   "c",
\  "001001"    :   "f",
\  "001000"    :   "e",
\  "000111"    :   "p",
\  "000110"    :   "o",
\  "000101"    :   "r",
\  "000100"    :   "q",
\  "000011"    :   "l",
\  "000010"    :   "k",
\  "000001"    :   "n",
\  "000000"    :   "m",
\  "1111111"    :  "J",
\  "1111110"    :  "I",
\  "1111101"    :  "L",
\  "1111100"    :  "K",
\  "1111011"    :  "F",
\  "1111010"    :  "E",
\  "1111001"    :  "H",
\  "1111000"    :  "G",
\  "1110111"    :  "R",
\  "1110110"    :  "Q",
\  "1110101"    :  "T",
\  "1110100"    :  "S",
\  "1110011"    :  "N",
\  "1110010"    :  "M",
\  "1110001"    :  "P",
\  "1110000"    :  "O",
\  "1101111"    :  "Z",
\  "1101110"    :  "Y",
\  "1101101"    :  " ",
\  "1101100"    :  "A",
\  "1101011"    :  "V",
\  "1101010"    :  "U",
\  "1101001"    :  "X",
\  "1101000"    :  "W",
\  "1100111"    :  "B",
\  "1100101"    :  "D",
\  "1100100"    :  "C",
\           }

let &cpo=s:keepcpo
unlet s:keepcpo

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"        File browsing using vim-dirvish code, which is GPL licensed
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Dirvish {{{

" Plugin

command! -bar -nargs=? -complete=dir ZMDirvish call <SID>ZMDirvish_open(<q-args>)
command! -bar -nargs=? -complete=dir ZMLoad call <SID>ZMLoad(<q-args>)

function! s:isdir(dir)
    return !empty(a:dir) && (isdirectory(a:dir) ||
                \ (!empty($SYSTEMDRIVE) && isdirectory('/'.tolower($SYSTEMDRIVE[0]).a:dir)))
endfunction

" Syntax

let s:sep = exists('+shellslash') && !&shellslash ? '\\' : '\/'

" Autoload

let s:sep = exists('+shellslash') && !&shellslash ? '\' : '/'
let s:noswapfile = (2 == exists(':noswapfile')) ? 'noswapfile' : ''
let s:noau       = 'silent noautocmd keepjumps'

function! s:msg_error(msg) abort
    redraw | echohl WarningMsg | echomsg a:msg | echohl None
endfunction

" Normalize slashes for safe use of fnameescape(), isdirectory(). Vim bug #541.
function! s:sl(path) abort
    return tr(a:path, '\', '/')
endfunction

function! s:normalize_dir(dir) abort
    let dir = s:sl(a:dir)
    if !isdirectory(dir)
        "cygwin/MSYS fallback for paths that lack a drive letter.
        let dir = empty($SYSTEMDRIVE) ? dir : '/'.tolower($SYSTEMDRIVE[0]).(dir)
        if !isdirectory(dir)
            call s:msg_error("invalid directory: '".a:dir."'")
            return ''
        endif
    endif
    " Collapse slashes (except UNC-style \\foo\bar).
    let dir = dir[0] . substitute(dir[1:], '/\+', '/', 'g')
    " Always end with separator.
    return (dir[-1:] ==# '/') ? dir : dir.'/'
endfunction

function! s:parent_dir(dir) abort
    let mod = isdirectory(s:sl(a:dir)) ? ':p:h:h' : ':p:h'
    return s:normalize_dir(fnamemodify(a:dir, mod))
endfunction

if v:version > 703
    function! s:globlist(pat) abort
        return glob(a:pat, 1, 1)
    endfunction
else "Vim 7.3 glob() cannot handle filenames containing newlines.
    function! s:globlist(pat) abort
        return split(glob(a:pat, 1), "\n")
    endfunction
endif

function! s:list_dir(dir) abort
    " Escape for glob().
    let dir_esc = substitute(a:dir,'\V[','[[]','g')
    let paths = s:globlist(dir_esc.'*')
    "Append dot-prefixed files. glob() cannot do both in 1 pass.
    let paths = paths + s:globlist(dir_esc.'.[^.]*')

    if get(g:, 'zekyll_relative_paths', 0)
                \ && a:dir != s:parent_dir(getcwd()) "avoid blank CWD
        return sort(map(paths, "fnamemodify(v:val, ':p:.')"))
    else
        return sort(map(paths, "fnamemodify(v:val, ':p')"))
    endif
endfunction

function! s:buf_init() abort
    augroup zmdirvish_buflocal
        autocmd! * <buffer>
        autocmd BufEnter,WinEnter <buffer> call <SID>on_bufenter()

        " BufUnload is fired for :bwipeout/:bdelete/:bunload, _even_ if
        " 'nobuflisted'. BufDelete is _not_ fired if 'nobuflisted'.
        " NOTE: For 'nohidden' we cannot reliably handle :bdelete like this.
        if &hidden
            autocmd BufUnload <buffer> call s:on_bufclosed()
        endif
    augroup END

    setlocal buftype=nofile noswapfile
endfunction

function! s:on_bufenter() abort
    " Ensure w:zmdirvish for window splits, `:b <nr>`, etc.
    let w:zmdirvish = extend(get(w:, 'zmdirvish', {}), b:zmdirvish, 'keep')

    if empty(getline(1)) && 1 == line('$')
        ZMDirvish %
        return
    endif
    if 0 == &l:cole
        call <sid>win_init()
    endif
endfunction

function! s:save_state(d) abort
    " Remember previous ('original') buffer.
    let a:d.prevbuf = s:buf_isvalid(bufnr('%')) || !exists('w:zmdirvish')
                \ ? 0+bufnr('%') : w:zmdirvish.prevbuf
    if !s:buf_isvalid(a:d.prevbuf)
        "If reached via :edit/:buffer/etc. we cannot get the (former) altbuf.
        let a:d.prevbuf = exists('b:zmdirvish') && s:buf_isvalid(b:zmdirvish.prevbuf)
                    \ ? b:zmdirvish.prevbuf : bufnr('#')
    endif

    " Remember alternate buffer.
    let a:d.altbuf = s:buf_isvalid(bufnr('#')) || !exists('w:zmdirvish')
                \ ? 0+bufnr('#') : w:zmdirvish.altbuf
    if exists('b:zmdirvish') && (a:d.altbuf == a:d.prevbuf || !s:buf_isvalid(a:d.altbuf))
        let a:d.altbuf = b:zmdirvish.altbuf
    endif

    " Save window-local settings.
    let w:zmdirvish = extend(get(w:, 'zmdirvish', {}), a:d, 'force')
    let [w:zmdirvish._w_wrap, w:zmdirvish._w_cul] = [&l:wrap, &l:cul]
    if has('conceal') && !exists('b:zmdirvish')
        let [w:zmdirvish._w_cocu, w:zmdirvish._w_cole] = [&l:concealcursor, &l:conceallevel]
    endif
endfunction

function! s:win_init() abort
    let w:zmdirvish = get(w:, 'zmdirvish', copy(b:zmdirvish))
    setlocal nowrap cursorline

    if has('conceal')
        setlocal concealcursor=nvc conceallevel=3
    endif
endfunction

function! s:on_bufclosed() abort
    call s:restore_winlocal_settings()
endfunction

function! s:buf_close() abort
    let d = get(w:, 'zmdirvish', {})
    if empty(d)
        return
    endif

    let [altbuf, prevbuf] = [get(d, 'altbuf', 0), get(d, 'prevbuf', 0)]
    let found_alt = s:try_visit(altbuf)
    if !s:try_visit(prevbuf) && !found_alt
                \ && prevbuf != bufnr('%') && altbuf != bufnr('%')
        bdelete
    endif
endfunction

function! s:restore_winlocal_settings() abort
    if !exists('w:zmdirvish') " can happen during VimLeave, etc.
        return
    endif
    if has('conceal') && has_key(w:zmdirvish, '_w_cocu')
        let [&l:cocu, &l:cole] = [w:zmdirvish._w_cocu, w:zmdirvish._w_cole]
    endif
endfunction

function! s:open_selected(split_cmd, bg, line1, line2) abort
    let curbuf = bufnr('%')
    let [curtab, curwin, wincount] = [tabpagenr(), winnr(), winnr('$')]
    let splitcmd = a:split_cmd

    let paths = getline(a:line1, a:line2)
    for path in paths
        let path = s:sl(path)
        if !isdirectory(path) && !filereadable(path)
            call s:msg_error("invalid (or access denied): ".path)
            continue
        endif

        if isdirectory(path)
            if splitcmd ==# "ZMLoad"
                exe 'ZMLoad' fnameescape(path)
            else
                exe (splitcmd ==# 'edit' ? '' : splitcmd.'|') 'ZMDirvish' fnameescape(path)
            end
        else
            exe splitcmd fnameescape(path)
        endif

        " return to previous window after _each_ split, otherwise we get lost.
        if a:bg && splitcmd =~# 'sp' && winnr('$') > wincount
            wincmd p
        endif
    endfor

    if a:bg "return to zmdirvish buffer
        if a:split_cmd ==# 'tabedit'
            exe 'tabnext' curtab '|' curwin.'wincmd w'
        elseif a:split_cmd ==# 'edit'
            execute 'silent keepalt keepjumps buffer' curbuf
        endif
    elseif !exists('b:zmdirvish') && exists('w:zmdirvish')
        call s:set_altbuf(w:zmdirvish.prevbuf)
    endif
endfunction

function! s:set_altbuf(bnr) abort
    let curbuf = bufnr('%')
    call s:try_visit(a:bnr)
    let noau = bufloaded(curbuf) ? 'noau' : ''
    " Return to the current buffer.
    execute 'silent keepjumps' noau s:noswapfile 'buffer' curbuf
endfunction

function! s:try_visit(bnr) abort
    if a:bnr != bufnr('%') && bufexists(a:bnr)
                \ && empty(getbufvar(a:bnr, 'zmdirvish'))
        " If _previous_ buffer is _not_ loaded (because of 'nohidden'), we must
        " allow autocmds (else no syntax highlighting; #13).
        let noau = bufloaded(a:bnr) ? 'noau' : ''
        execute 'silent keepjumps' noau s:noswapfile 'buffer' a:bnr
        return 1
    endif
    return 0
endfunction

function! s:tab_win_do(tnr, cmd, bname) abort
    exe s:noau 'tabnext' a:tnr
    for wnr in range(1, tabpagewinnr(a:tnr, '$'))
        if a:bname ==# bufname(winbufnr(wnr))
            exe s:noau wnr.'wincmd w'
            exe a:cmd
        endif
    endfor
endfunction

" Performs `cmd` in all windows showing `bname`.
function! s:bufwin_do(cmd, bname) abort
    let [curtab, curwin, curwinalt] = [tabpagenr(), winnr(), winnr('#')]
    for tnr in range(1, tabpagenr('$'))
        let [origwin, origwinalt] = [tabpagewinnr(tnr), tabpagewinnr(tnr, '#')]
        for bnr in tabpagebuflist(tnr)
            if a:bname ==# bufname(bnr) " tab has at least 1 matching window
                call s:tab_win_do(tnr, a:cmd, a:bname)
                exe s:noau origwinalt.'wincmd w|' s:noau origwin.'wincmd w'
                break
            endif
        endfor
    endfor
    exe s:noau 'tabnext '.curtab
    exe s:noau curwinalt.'wincmd w|' s:noau curwin.'wincmd w'
endfunction

function! s:buf_render(dir, lastpath) abort
    let bname = bufname('%')
    let isnew = empty(getline(1))

    if !isdirectory(s:sl(bname))
        echoerr 'fatal: buffer name is not a directory:' bufname('%')
        return
    endif

    if !isnew
        call s:bufwin_do('let w:zmdirvish["_view"] = winsaveview()', bname)
    endif

    if v:version > 704 || v:version == 704 && has("patch73")
        setlocal undolevels=-1
    endif
    silent keepmarks keepjumps %delete _
    call setline( 1, 'a/A/Ctrl-a – accept dir, - – parent dir, q – quit, o/i – (split) enter file or dir' )
    call setline( 2, '----------------------------------------------------------------------------------' )
    silent keepmarks keepjumps call setline(3, s:list_dir(a:dir))
    if v:version > 704 || v:version == 704 && has("patch73")
        setlocal undolevels<
    endif

    if !isnew
        call s:bufwin_do('call winrestview(w:zmdirvish["_view"])', bname)
    endif

    if !empty(a:lastpath)
        keepjumps call search('\V\^'.escape(a:lastpath, '\').'\$', 'cw')
    endif
endfunction

function! s:do_open(d, reload) abort
    let d = a:d
    let bnr = bufnr('^' . d._dir . '$')

    let dirname_without_sep = substitute(d._dir, '[\\/]\+$', '', 'g')
    let bnr_nonnormalized = bufnr('^'.dirname_without_sep.'$')

    " Vim tends to name the buffer using its reduced path.
    " Examples (Win32 gvim 7.4.618):
    "     ~\AppData\Local\Temp\
    "     ~\AppData\Local\Temp
    "     AppData\Local\Temp\
    "     AppData\Local\Temp
    " Try to find an existing normalized-path name before creating a new one.
    for pat in [':~:.', ':~']
        if -1 != bnr
            break
        endif
        let modified_dirname = fnamemodify(d._dir, pat)
        let modified_dirname_without_sep = substitute(modified_dirname, '[\\/]\+$', '', 'g')
        let bnr = bufnr('^'.modified_dirname.'$')
        if -1 == bnr_nonnormalized
            let bnr_nonnormalized = bufnr('^'.modified_dirname_without_sep.'$')
        endif
    endfor

    if -1 == bnr
        execute 'silent noau keepjumps' s:noswapfile 'edit' fnameescape(d._dir)
    else
        execute 'silent noau keepjumps' s:noswapfile 'buffer' bnr
    endif

    "If the directory is relative to CWD, :edit refuses to create a buffer
    "with the expanded name (it may be _relative_ instead); this will cause
    "problems when the user navigates. Use :file to force the expanded path.
    if bnr_nonnormalized == bufnr('#') || s:sl(bufname('%')) !=# d._dir
        if s:sl(bufname('%')) !=# d._dir
            execute 'silent noau keepjumps '.s:noswapfile.' file ' . fnameescape(d._dir)
        endif

        if bufnr('#') != bufnr('%') && isdirectory(s:sl(bufname('#'))) "Yes, (# == %) is possible.
            bwipeout # "Kill it with fire, it is useless.
        endif
    endif

    if s:sl(bufname('%')) !=# d._dir  "We have a bug or Vim has a regression.
        echohl WarningMsg | echo 'expected buffer name: "'.d._dir.'" (actual: "'.bufname('%').'")' | echohl None
        return
    endif

    if &buflisted
        setlocal nobuflisted
    endif

    call s:set_altbuf(d.prevbuf) "in case of :bd, :read#, etc.

    let b:zmdirvish = exists('b:zmdirvish') ? extend(b:zmdirvish, d, 'force') : d

    call s:buf_init()
    call s:win_init()
    if a:reload || s:should_reload()
        call s:buf_render(b:zmdirvish._dir, get(b:zmdirvish, 'lastpath', ''))
    endif

    " Setup mappings
    nnoremap <buffer><silent> <Plug>(zmdirvish_up) :<C-U>exe "ZMDirvish %:h".repeat(":h",v:count1)<CR>
    if !hasmapto('<Plug>(zmdirvish_up)', 'n')
        execute 'nmap '.s:nowait.'<buffer> - <Plug>(zmdirvish_up)'
    endif

    nnoremap <silent> <Plug>(zmdirvish_quit) :<C-U>call <SID>buf_close()<CR>
    if !hasmapto('<Plug>(zmdirvish_quit)', 'n')
        execute 'nmap '.s:nowait.'<buffer> q <Plug>(zmdirvish_quit)'
    endif

    execute 'nnoremap '.s:nowait.'<buffer><silent> i    :<C-U>.call <SID>ZMDirvish_open("edit", 0)<CR>'
    execute 'nnoremap '.s:nowait.'<buffer><silent> <CR> :<C-U>.call <SID>ZMDirvish_open("edit", 0)<CR>'
    execute 'nnoremap '.s:nowait.'<buffer><silent> o    :<C-U>.call <SID>ZMDirvish_open("split", 1)<CR>'
    execute 'nnoremap '.s:nowait.'<buffer><silent> <2-LeftMouse> :<C-U>.call <SID>ZMDirvish_open("edit", 0)<CR>'

    execute 'nnoremap '.s:nowait.'<buffer><silent> a :<C-U>.call <SID>ZMDirvish_open("ZMLoad", 0)<CR>'
    execute 'nnoremap '.s:nowait.'<buffer><silent> A :<C-U>.call <SID>ZMDirvish_open("ZMLoad", 0)<CR>'
    execute 'nnoremap '.s:nowait.'<buffer><silent> <C-A> :<C-U>.call <SID>ZMDirvish_open("ZMLoad", 0)<CR>'

    nnoremap <buffer><silent> R :ZMDirvish %<CR>

    " Buffer-local / and ? mappings to skip the concealed path fragment.
    nnoremap <buffer> / /\ze[^\/]*[\/]\=$<Home>
    nnoremap <buffer> ? ?\ze[^\/]*[\/]\=$<Home>

    " Blocking mappings
    nmap <buffer> <silent> v <Nop>
    nmap <buffer> <silent> D <Nop>
    nmap <buffer> <silent> y <Nop>
    nmap <buffer> <silent> Y <Nop>

    " Setup syntax highlighting
    exe 'syntax match ZMDirvishPathHead ''\v.*'.s:sep.'\ze[^'.s:sep.']+'.s:sep.'?$'''
    exe 'syntax match ZMDirvishPathTail ''\v[^'.s:sep.']+'.s:sep.'$'''
    exe 'syntax match ZMDirvishMenu1     ''a/A/Ctrl-a.*'''
    exe 'syntax match ZMDirvishMenu2     ''---\+'''
    highlight! link ZMDirvishPathTail Directory
    highlight! link ZMDirvishMenu1 Title
    highlight! link ZMDirvishMenu2 Directory

endfunction

function! s:should_reload() abort
    if line('$') < 1000 || '' ==# glob(getline('$'),1)
        return 1
    endif
    redraw | echo 'too many files; showing cached listing'
    return 0
endfunction

function! s:buf_isvalid(bnr) abort
    return bufexists(a:bnr) && !isdirectory(s:sl(bufname(a:bnr)))
endfunction

function! s:ZMDirvish_open(...) range abort
    if &autochdir
        call s:msg_error("'autochdir' is not supported")
        return
    endif
    if !&hidden && &modified
        call s:msg_error("E37: No write since last change")
        return
    endif

    if a:0 > 1
        if line(".") > 2
            call s:open_selected(a:1, a:2, a:firstline, a:lastline)
        end
        return
    endif

    let d = {}
    let from_path = fnamemodify(bufname('%'), ':p')
    let to_path   = fnamemodify(s:sl(a:1), ':p')
    "                                       ^resolves to CWD if a:1 is empty

    let d._dir = filereadable(to_path) ? fnamemodify(to_path, ':p:h') : to_path
    let d._dir = s:normalize_dir(d._dir)
    if '' ==# d._dir " s:normalize_dir() already showed error.
        return
    endif

    let reloading = exists('b:zmdirvish') && d._dir ==# b:zmdirvish._dir

    if reloading
        let d.lastpath = ''         " Do not place cursor when reloading.
    elseif d._dir ==# s:parent_dir(from_path)
        let d.lastpath = from_path  " Save lastpath when navigating _up_.
    endif

    call s:save_state(d)
    call s:do_open(d, reloading)
endfunction

function! s:ZMLoad(...) abort
    if a:0 == 0
        execute ":ZMDirvish"
    end

    let path = a:1
    if isdirectory( path )
        let s:cur_repo_path = path
    else
        if filereadable(path)
            let path = fnamemodify(path, ':p:h')
            let s:cur_repo_path = path
        else
            let path = substitute( path, '/[^/]\+$', "", "" )
            let s:cur_repo_path = path
        end

    end

    let s:cur_repo = s:PathToRepo( s:cur_repo_path )
    set lz
    call <SID>StartZekyll()
    set nolz
endfunction

" }}}
