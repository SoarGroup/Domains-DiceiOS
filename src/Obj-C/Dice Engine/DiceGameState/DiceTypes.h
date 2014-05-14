typedef enum PlayerStatus {
    Lost = 0,
    Won = 1,
    Playing = 2
} PlayerStatus;

typedef enum ActionType {
    ACTION_ACCEPT = 0,
    ACTION_BID = 1,
    ACTION_PUSH = 2,
    ACTION_CHALLENGE_BID = 3,
    ACTION_CHALLENGE_PASS = 4,
    ACTION_EXACT = 5,
    ACTION_PASS = 6,
    ACTION_ILLEGAL = 7,
    ACTION_QUIT = 8
} ActionType;
