/// Module: template
module template::template;

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

// === Errors ===
const ENotYourTurn: u64 = 0;
const EInvalidPos: u64 = 1;
const EAlreadySettleDown: u64 = 2;
// Use PascalCase for errors, start with an E and be descriptive.
// ex: const ENameHasMaxLengthOf64Chars: u64 = 0;
// https://docs.sui.io/concepts/sui-move-concepts/conventions#errors

// === Structs ===
public struct Game has key {
    id: UID,
    
    player1: ID,
    player2: ID,

    next_player: ID,
    board: vector<vector<Option<ID>>>,
    winner: Option<ID>,
}

public struct PlayerCap has key {
    id: UID,
}

// * Describe the properties of your structs.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#struct-property-comments
// * Do not use 'potato' in the name of structs. The lack of abilities define it as a potato pattern.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#potato-structs

// === Public-Mutative Functions ===
// * Name the functions that create data structures as `public fun empty`.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#empty-function
//
// * Name the functions that create objects as `pub fun new`.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#new-function
//
// * Library modules that share objects should provide two functions:
// one to create the object `public fun new(ctx:&mut TxContext): Object`
// and another to share it `public fun share(profile: Profile)`.
// It allows the caller to access its UID and run custom functionality before sharing it.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#new-function
//
// * Name the functions that return a reference as `<PROPERTY-NAME>_mut`, replacing with
// <PROPERTY-NAME\> the actual name of the property.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#reference-functions
//
// * Provide functions to delete objects. Destroy empty objects with the `public fun destroy_empty`
// Use the `public fun drop` for objects that have types that can be dropped.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#destroy-functions
//
// * CRUD functions names
// `add`, `new`, `drop`, `empty`, `remove`, `destroy_empty`, `to_object_name`, `from_object_name`, `property_name_mut`
// https://docs.sui.io/concepts/sui-move-concepts/conventions#crud-functions-names

fun init(_ctx: &mut TxContext) {}

// === Public-View Functions ===
public fun complete(self: &Game): bool {
    self.winner.is_some()
}
// * Name the functions that return a reference as <<PROPERTY-NAME>, replacing with
// <PROPERTY-NAME\> the actual name of the property.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#reference-functions
//
// * Keep your functions pure to maintain composability. Do not use `transfer::transfer` or
// `transfer::public_transfer` inside core functions.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#pure-functions
//
// * CRUD functions names
// `exists_`, `contains`, `property_name`
// https://docs.sui.io/concepts/sui-move-concepts/conventions#crud-functions-names

// === Admin Functions ===
// * In admin-gated functions, the first parameter should be the capability. It helps the autocomplete with user types.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#admin-capability
//
// * To maintain composability, use capabilities instead of addresses for access control.
// https://docs.sui.io/concepts/sui-move-concepts/conventions#access-control
// === Public-Package Functions ===
public entry fun make_game_challenge(
    to: address,
    ctx: &mut TxContext,
) {
    let first_player = PlayerCap {
        id: object::new(ctx),
    };
    let second_player = PlayerCap {
        id: object::new(ctx),
    };

    let board = vector[
        vector[option::none<ID>(), option::none<ID>(), option::none<ID>()],
        vector[option::none<ID>(), option::none<ID>(), option::none<ID>()],
        vector[option::none<ID>(), option::none<ID>(), option::none<ID>()]
    ];

    transfer::share_object( Game {
        id: object::new(ctx),
        player1: object::id(&first_player),
        player2: object::id(&second_player),
        next_player: object::id(&first_player),
        board: board,
        winner: option::none<ID>(),
    });

    transfer::transfer(first_player, to);
    transfer::transfer(second_player, tx_context::sender(ctx));
}

public entry fun next(game: &mut Game, player: &PlayerCap, pos: u64) {
    assert!(game.next_player == object::id(player), ENotYourTurn);
    assert!(game.winner.is_none(), EAlreadySettleDown);
    assert!(pos > 0 && pos <= 9, EInvalidPos);
    
    let row = (pos - 1 / 3) % 3;
    let col = pos - 1 % 3;

    if (object::id(player) == game.player1) {
        game.next_player = game.player2;
    } else {
        game.next_player = game.player1;
    };

    if(game.board[row][col].is_none()) {
        let row_vec = vector::borrow_mut(&mut game.board, row);
        let cell = vector::borrow_mut(row_vec, col);
        *cell = option::some(object::id(player));
    } else {
        abort EInvalidPos
    };

    game.settle_down(pos);
}


// === Private Functions ===
fun settle_down(self: &mut Game, pos: u64) {
    let row = (pos - 1 / 3) % 3;
    let col = pos - 1 % 3;

    let current_player = self.board[row][col];
    if (current_player.is_some()) {
        if (self.board[row][(col + 1) % 3] == current_player && self.board[row][(col + 2) % 3] == current_player) {
            self.winner = current_player;
        } else if (self.board[(row + 1) % 3][col] == current_player && self.board[(row + 2) % 3][col] == current_player) {
            self.winner = current_player;
        } else if (self.board[(row + 1) % 3][(col + 1) % 3] == current_player && self.board[(row + 2) % 3][(col + 2) % 3] == current_player) {
            self.winner = current_player;
        } else if (self.board[(row + 1) % 3][(col + 2) % 3] == current_player && self.board[(row + 2) % 3][(col + 1) % 3] == current_player) {
            self.winner = current_player;
        } else {
            self.winner = option::none<ID>();
        };
    } else {
        self.winner = option::none<ID>();
    };
}

// === Test Functions ===
// The setup function can use in the test packages, it is current practice
#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
