let g:seed = 0

function! SeedRNG(seed)
    let g:seed = a:seed % 509
endfunction

" TODO: Try to configure the cursor so it is not displayed. For terminal vim I
" believe the terminal itself would have to be configured from within vim. Or
" perhaps we could create highlighting to just conceal the cursor altogether?
" Looking at sneak.vim it seems that he has to do something to prevent that
" from happening so logically I should be able to make it happen.
" TODO: Consider using randomness from the system to generate random numbers:
" http://stackoverflow.com/questions/20430493/how-to-generate-random-numbers-in-the-buffer
" http://stackoverflow.com/questions/3062746/special-simple-random-number-generator
function! Rand()
    let a = 35
    let c = 1
    let m = 509
    let g:seed = (a * g:seed + c) % m
    return g:seed
endfunction

function! Snake()
    call ClearBuffer()
    call GameLoop()
    call QuitGame()
endfunction

function! GameLoop()
    let height = &lines - 1
    let width = &columns
    let snake_body = [[1, 1]]
    let cur_dir = [1, 0]
    let food_pos = GenerateFoodPos(snake_body, height, width)
    call DrawBoard(height, width, snake_body, food_pos)
    while 1
        let input = GetInput()
        if input ==? 'q'
            break
        endif
        let [snake_body, cur_dir, food_pos] = UpdateSnake(input, snake_body, cur_dir, food_pos, height, width)
        if snake_body ==# [[0, 0]]
            break
        endif
        call DrawBoard(height, width, snake_body, food_pos)
        sleep 50ms
    endwhile
endfunction

function! GameOver(height, width, snake_body)
    let head_pos = a:snake_body[0]
    if index(Tail(a:snake_body), head_pos) != -1 || head_pos[0] < 1 || head_pos[1] < 1 || head_pos[0] > a:height || head_pos[1] > a:width
        return 1
    endif
    return 0
endfunction

function! Tail(lst)
    let new_lst = deepcopy(a:lst)
    call remove(new_lst, 0)
    return new_lst
endfunction

function! GetNewDir(input, cur_dir)
    let new_dir = a:cur_dir
    if a:input ==# 'h'
        let new_dir = [0, -1]
    elseif a:input ==# 'j'
        let new_dir = [1, 0]
    elseif a:input ==# 'k'
        let new_dir = [-1, 0]
    elseif a:input ==# 'l'
        let new_dir = [0, 1]
    endif
    " Prevent the user from moving in the opposite direction
    if AddVector(new_dir, a:cur_dir) ==# [0, 0]
        return a:cur_dir
    else
        return new_dir
    endif
endfunction

function! UpdateSnake(input, snake_body, cur_dir, food_pos, height, width)
    let new_dir = GetNewDir(a:input, a:cur_dir)

    let new_snake_body = a:snake_body
    if GameOver(a:height, a:width, a:snake_body)
        return [[[0, 0]], [0, 0], [0, 0]]
    endif
    let new_food_pos = a:food_pos
    let should_gen_food = 0
    if new_snake_body[0] == a:food_pos
        call add(new_snake_body, [0, 0])
        let should_gen_food = 1
    endif
    let i = len(new_snake_body)-1
    while i > 0
        let new_snake_body[i] = new_snake_body[i-1]
        let i = i - 1
    endwhile
    let new_snake_body[0] = AddVector(new_snake_body[0], new_dir)
    if should_gen_food
        let new_food_pos = GenerateFoodPos(new_food_pos, a:height, a:width)
    endif

    return [new_snake_body, new_dir, new_food_pos]
endfunction

function! GetInput()
    let c = getchar(0)
    if c == 0
        return ''
    else
        return nr2char(c)
    endif
endfunction

function! ClearBoard(height, width)
    let spaces = repeat(' ', a:width)
    for y in range(1, a:height)
        call setline(y, spaces)
    endfor
endfunction

function! DrawChar(char_to_draw, pos)
    call cursor(a:pos)
    execute "normal r".a:char_to_draw
endfunction

function! DrawBoard(height, width, snake_body, food_pos)
    let char_to_draw = '#'
    call ClearBoard(a:height, a:width)
    for s in a:snake_body
        call DrawChar(char_to_draw, s)
    endfor
    call DrawChar(char_to_draw, a:food_pos)
    redraw
endfunction

" TODO: Should we put the code in here which detects if it is or is not
" possible to generate more food? Or somewhere else? Remember, when you can't
" generate anymore food then you've won.
" TODO: Improve this code in the future. I feel this is kind of brute force
" right now (i.e just keep generating until it works). We could build a list
" of available places for food and then randomly generate an index into that
" list.
function! GenerateFoodPos(snake_body, height, width)
    let pos = GenRandomPos(a:height, a:width)
    while 1
        if index(a:snake_body, pos) == -1
            return pos
        endif
        let pos = GenRandomPos(a:height, a:width)
    endwhile
endfunction

function! GenRandomPos(height, width)
    let y = Rand() % a:height + 1
    let x = Rand() % a:width + 1
    return [y, x]
endfunction

function! AddVector(v1, v2)
    let v3 = []
    let len1 = len(a:v1)-1
    let len2 = len(a:v2)-1
    for i in range(0, len1 < len2 ? len1 : len2)
        call add(v3, a:v1[i] + a:v2[i])
    endfor
    return v3
endfunction

function! QuitGame()
    let &laststatus = g:save_laststatus
    let &showtabline = g:save_showtabline
    bdelete!
endfunction

function! ClearBuffer()
    " Open up a blank buffer
    -tabedit
    " Maximize screen space
    setlocal nonumber
    setlocal nocursorline
    setlocal nocursorcolumn
    setlocal nowrap
    let g:save_laststatus = &laststatus
    let g:save_showtabline = &showtabline
    set laststatus=0
    set showtabline=0
    " Generally, the screen will be filled with spaces as filler characters,
    " but we might want to draw a single colored square. Doing this lets us
    " draw that square using the tab character.
    setlocal noexpandtab
    setlocal tabstop=1
endfunction

