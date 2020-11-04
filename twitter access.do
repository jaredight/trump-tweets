local consumer_key "***"
local consumer_secret "KP***"
local access_token "11****6V"
local access_token_secret "kP***Km"

twitter2stata setaccess "`consumer_key'" "`consumer_secret'" ///
     "`access_token'" "`access_token_secret'"
twitter2stata searchtweets "star wars", numtweets(10)
list user_screen_name user_follower_count user_friend_count, abbreviate(20)
