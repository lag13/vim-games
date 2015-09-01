" TODO: Make a game like the chrome dinosaur game.
if exists("g:loaded_games") || &cp || v:version < 700
    finish
endif
let g:loaded_games = 1

let g:game_default_games = {
            \ 'snake':     'snake#snake',
            \ }

command! -nargs=* -complete=customlist,util#filterGameList Game call util#runGame(<f-args>)

