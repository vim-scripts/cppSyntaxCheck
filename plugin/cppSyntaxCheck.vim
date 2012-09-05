" ======================================================================================
" File         : cppSpellCheck.vim
" Author       : Yang Fengjia
" Last Change  : 09/03/2012 | 14:15:04 PM | Monday,September
" Description  : A cpp language spell check script
" ======================================================================================

"g++
if(!exists("g:include_path"))
  let g:include_path=' '
endif
if(!exists("g:compile_flag"))
  let g:compile_flag=' '
endif
if(!exists("g:cpp_compiler"))
  let g:cpp_compiler='g++ -Wall '
endif
if(!exists("g:enable_warning"))
  let g:enable_warning=0
endif

sign define GCCError text=>> texthl=Error
sign define GCCWarning text=>> texthl=Todo
let g:error_list = {}
let g:warning_list = {}
let g:is_showing_msg = 0
let g:buffe_name=''

function! s:ShowErrC()
  call s:ClearErr()

  let b:error_list={}
  let buf_name=bufname("%")
  let dir_tree=split(buf_name, '/')
  let file_name=dir_tree[len(dir_tree)-1]
  let include_path=substitute(g:include_path, ':', " -I", "g")

  "show error
  let compile_cmd=g:cpp_compiler . ' -o .tmpobject -c ' . buf_name . ' ' . g:compile_flag . ' ' . include_path . ' 2>&1 '  . '|grep error|grep ' . file_name
  let compile_result=system(compile_cmd)
  let line_list=split(compile_result, '\n')

  for error_str in line_list
    let tmp_split=split(error_str,':')
    if len(tmp_split) < 3
      continue
    endif
    let item={}
    let item["lnum"]=tmp_split[1]
    let item["text"] = tmp_split[len(tmp_split)-2] . ":" . tmp_split[len(tmp_split)-1]
    let b:error_list[item.lnum]=item
    let g:error_list[buf_name]=b:error_list
  endfor

  "show warning
  if g:enable_warning!=0
    let b:warning_list={}
    let compile_cmd=g:cpp_compiler . ' -o .tmpobject -c ' . buf_name . ' ' . g:compile_flag . ' ' . include_path . ' 2>&1 '  . '|grep warning|grep ' . file_name
    let compile_result=system(compile_cmd)
    let line_list=split(compile_result, '\n')
    for warning_str in line_list
      let tmp_split=split(warning_str,':')
      if len(tmp_split) < 3
        continue
      endif
      let item={}
      let item["lnum"]=tmp_split[1]
      let item["text"] = tmp_split[len(tmp_split)-2] . ":" . tmp_split[len(tmp_split)-1]
      let b:warning_list[item.lnum]=item
      let g:warning_list[buf_name]=b:warning_list
    endfor
  endif
  call s:SignErrWarn()

  "remove file created
  let rm_cmd='rm .tmpobject'
  call system(rm_cmd)

endfunction

function! ShowCompile()
  let buf_name=bufname("%")
  let dir_tree=split(buf_name, '/')
  let file_name=dir_tree[len(dir_tree)-1]
  let include_path=substitute(g:include_path, ':', " -I", "g")
  let compile_cmd=g:cpp_compiler . ' -o .tmpobject -c ' . buf_name . ' ' . g:compile_flag . ' ' . include_path
  echo compile_cmd
  let compile_result=system(compile_cmd)
  echo compile_result
endfunction

"Clear the dictionary of error
function! s:ClearErr()
  let buf_name=bufname("%")
  sign unplace *
  let b:error_list={}
  let b:warning_list={}
  let g:error_list[buf_name]=b:error_list
  let g:warning_list[buf_name]=b:warning_list
  if g:is_showing_msg
    echo
    let g:is_showing_msg = 0
  endif
endfunction

function! s:SignErrWarn()
  sign unplace *
  let b:next_sign_id=1
  let buf_name=bufname("%")
  if has_key(g:error_list, buf_name)
    let b:error_list=get(g:error_list, buf_name)
  else
    let b:error_list={}
  endif
  if has_key(g:warning_list, buf_name)
    let b:warning_list=get(g:warning_list, buf_name)
  else
    let b:warning_list={}
  endif
  for error_key in keys(b:error_list)
    let item=b:error_list[error_key]
    execute "sign place"  b:next_sign_id "line=" . item.lnum "name=GCCError " "file=" . expand("%:p")
    let b:next_sign_id+=1
  endfor
  for warning_key in keys(b:warning_list)
    let item=b:warning_list[warning_key]
    execute "sign place"  b:next_sign_id "line=" . item.lnum "name=GCCWarning " "file=" . expand("%:p")
    let b:next_sign_id+=1
  endfor
endfunction

"Show syntax error
function! s:ShowErrMsg()
  let buf_name=bufname("%")
  if buf_name!=g:buffe_name
    call s:SignErrWarn()
    if has_key(g:error_list, buf_name)
      let b:error_list=get(g:error_list, buf_name)
    else
      let b:error_list={}
    endif
    if has_key(g:warning_list, buf_name)
      let b:warning_list=get(g:warning_list, buf_name)
    else
      let b:warning_list={}
    endif
    let g:buffe_name=buf_name
  endif
  let pos=getpos(".")
  if has_key(b:error_list, pos[1])
    let item = get(b:error_list, pos[1])
    echo item.text
    let g:is_showing_msg = 1
  else
    if g:is_showing_msg
      echo
      let g:is_showing_msg = 0
    endif
  endif
  if has_key(b:warning_list, pos[1])
    let item = get(b:warning_list, pos[1])
    echo item.text
    let g:is_showing_msg = 1
  else
    if g:is_showing_msg
      echo
      let g:is_showing_msg = 0
    endif
  endif
endfunction

autocmd BufWritePost *.cpp,*.c,*.h,*.cpp,*.cc call s:ShowErrC()
autocmd CursorHold *.cpp,*.h,*.c,*.hpp,*.cc call s:ShowErrMsg()
autocmd CursorMoved *.cpp,*.h,*.c,*.hpp,*.cc call s:ShowErrMsg()
