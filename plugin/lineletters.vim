if exists('g:loaded_lineletters')
  finish
endif
let g:loaded_lineletters = 1

" Create the list of symbols to be used for the signs by combining the
" main chars with the prefix chars; characters that are included in both
" lists will automatically be excluded from main chars.
" Example:
"   main_chars = ['a', 'b', 'c']
"   prefix_chars = [';', 'b']
" Returns: ['a', 'c', ';a', ';b', ';c', 'ba', 'bb', 'bc']
function! s:symbols(main_chars, prefix_chars)
  let l:symbols = filter(
        \ copy(a:main_chars),
        \ {idx, val -> index(a:prefix_chars, val) == -1})
  for c in a:prefix_chars
    let l:symbols += map(copy(a:main_chars), {i, v -> c . v})
  endfor
  return l:symbols
endfunction

" Settings
let g:lineletters_settings = get(g:, 'lineletters_settings', {})
let s:group = 'LineLetters'
let s:priority = 100
" a -> z
let s:main_chars =
      \ get(g:lineletters_settings,
      \ 'main_chars', map(range(97, 97 + 25), 'nr2char(v:val)'))
let s:highlight_group =
      \ get(g:lineletters_settings,
      \ 'highlight_group', 'LineNr')
let s:after_jump_do =
      \ get(g:lineletters_settings,
      \ 'after_jump_do', '^')
let s:prefix_chars =
      \ get(g:lineletters_settings,
      \ 'prefix_chars', [',', 'j', 'f'])
let s:signs = s:symbols(s:main_chars, s:prefix_chars)

" Get all unfolded lines between 'w0' and 'w$'
function! s:get_visible_lines()
  let l:visible = []
  for l in range(line('w0'), line('w$'))
    let l:fc = foldclosed(l)
    if l:fc == -1 || index(l:visible, l:fc) == -1
      call add(l:visible, l)
    endif
  endfor

  return l:visible
endfunction

" Example:
"   {'name': 'LineLetterss', 'texthl': 'LineNr', 'text': ' s'}
function! s:define_signs()
  for i in s:signs
    call sign_define(s:group . i,
          \ {'text': len(i) == 1 ? ' ' . i : i,
          \'texthl': s:highlight_group})
  endfor
endfunction

" Place signs on the visible lines in the current window
function! s:place_sings()
  let l:counter = 0
  for i in s:get_visible_lines()[0: len(s:signs) - 1]
    call sign_place(i, s:group,
          \ s:group . s:signs[counter], expand('%'),
          \ {'lnum': i, 'priority': s:priority})
    let l:counter += 1
  endfor
endfunction

function! s:go_to_sign()
  let l:signs = sign_getplaced(
        \ expand('%'),
        \ { 'group': s:group })[0]['signs']
  let l:first_char = nr2char(getchar())

  try
    if index(s:prefix_chars, l:first_char) == -1
      let l:sign = s:group . l:first_char
    else
      let l:second_char = nr2char(getchar())
      let l:sign = s:group . l:first_char . l:second_char
    endif

    let l:line = filter(l:signs, { idx, val -> val['name'] == l:sign })
    exec 'normal! ' l:line[0]['id'] . 'gg' . s:after_jump_do

  " E684: list index out of range
  catch /E684/
  endtry
endfunction

function! s:line_letters()
  call s:place_sings()
  redraw
  call s:go_to_sign()
  call sign_unplace(s:group)
endfunction

call s:define_signs()

nnoremap <silent> <Plug>LineLetters :call <SID>line_letters()<CR>
