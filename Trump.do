//GENERATING DATASET WITH AS MANY OBSERVATIONS AS POSSIBLE
//gathering new data. Note: to gather new data you need an access key to Twitter's
//API. Use twitter2stata as well as twitter_access.do
twitter2stata tweets "@realDonaldTrump", clear
gen num_tweet = _n
save trump_00, replace //data downloaded today (11 June 2019)
//preparing data downloaded earlier, stored in excel, for merge
cd C:\Users\jaredmw2\Downloads
import excel "trumptweets.xlsx", clear
rename L tweet_text
rename B tweet_created_at
save trump_merge_01
//merging old and new data
use trump_00, clear
merge 1:1 tweet_text using trump_merge_01.dta
drop _merge
save trump_02, replace //merged data

//PREPARING DATASET FOR ANALYSIS
//dropping unneeded variables
drop tweet_current_user_retweet_id
drop tweet_entities_hashtags tweet_entities_user_mentions tweet_favorited ///
	tweet_in_reply_account_id tweet_in_reply_screen_name 
drop tweet_in_reply_tweet_id tweet_language
drop tweet_latitude tweet_longitude tweet_place tweet_possibly_sensitive ///
	tweet_source tweet_withheld_in_countries user_account_timestamp user_display_name ///
	user_description user_follower_count user_id user_geo_enabled user_friend_count ///
	user_url user_utc_offset user_verified user_withheld_in_countries
drop tweet_quoted_status_id tweet_retweeted tweet_truncated user_contributors_enabled ///
	user_favorite_count user_following_request_sent user_is_translator user_language ///
	user_list_count user_location user_protected user_screen_name user_timezone
drop user_status_count
drop num_tweet

//generating lowercase tweet text
gen l_text = strlower(tweet_text)

//dropping retweets
drop if tweet_is_a_retweet == 1
drop tweet_is_a_retweet
gen tweet_is_a_retweet = 1 if strpos(l_text, "rt @")
drop if tweet_is_a_retweet == 1
drop tweet_is_a_retweet

//generating weighted popularity score
sum tweet_favorite_count
sum retweet_count
egen m_fav_count = mean(tweet_favorite_count)
egen m_retweet_count = mean(retweet_count)
gen weighted_retweets = retweet_count*m_fav_count/(m_fav_count+m_retweet_count)
gen weighted_favorites = tweet_favorite_count*m_retweet_count/(m_fav_count+m_retweet_count)
sum weighted_retweets weighted_favorites //ensure means are the same
gen popularity_score = weighted_retweets+weighted_favorites
drop weighted_retweets weighted_favorites
drop m_fav_count m_retweet_count

//generating dependent variables
gen america = 1 if strpos(l_text, "merica")
gen exclamation = 1 if strpos(l_text, "!")
gen celebration = 1 if strpos(l_text, "celebra")
gen link = 1 if strpos(l_text, "https:" "http:")
gen great = 1 if strpos(l_text, "great")
gen russia = 1 if strpos(l_text, "russia")
gen democrats = 1 if strpos(l_text, "dems" "democrats")
gen republican = 1 if strpos(l_text, "republican")
gen apology = 1 if strpos(l_text, "apolog")
gen mention = 1 if strpos(l_text, "@")
gen korea = 1 if strpos(l_text, "korea")
gen china = 1 if strpos(l_text, "china")
gen economy = 1 if strpos(l_text, "economy")
gen we = 1 if strpos(l_text, " we ")
gen wall = 1 if strpos(l_text, " wall ")
gen trade = 1 if strpos(l_text, "trade")
gen selfrefer = 1 if strpos(l_text, "i " " me ")
gen biden = 1 if strpos(l_text, "joe" "biden")
gen president = 1 if strpos(l_text, "president")
gen fakenews = 1 if strpos(l_text, "fake news")
gen media = 1 if strpos(l_text, "media")
gen trump = 1 if strpos(l_text, "trump")
gen border = 1 if strpos(l_text, "border")
gen thank = 1 if strpos(l_text, "thank")
gen new = 1 if strpos(l_text, "new")
gen good = 1 if strpos(l_text, "good")
gen bad = 1 if strpos(l_text, "bad")
gen people = 1 if strpos(l_text, "people")
gen maga = 1 if strpos(l_text, "maga")
//replacing missing values with a 0
recode america exclamation celebration link great russia democrats republican ///
	apology mention korea china economy we wall trade selfrefer biden president ///
	fakenews media trump border thank new good bad people maga (missing = 0)
//saving dataset
save trump_03, replace

//DATA ANALYSIS
//preliminary analysis, no regressions
	//correlations
corr popularity_score tweet_favorite_count retweet_count america exclamation ///
	celebration link great russia democrats republican ///
	apology mention korea china economy we wall trade selfrefer biden president ///
	fakenews media trump border thank new good bad people maga
	//bar graphs
gr bar popularity_score, by(great)
graph save Graph "C:\Users\jaredmw2\Documents\great.gph"
gr bar popularity_score, by(link)
graph save Graph "C:\Users\jaredmw2\Documents\link.gph"
gr bar popularity_score, by(exclamation)
graph save Graph "C:\Users\jaredmw2\Documents\exclamation.gph"
gr bar popularity_score, by(media)
graph save Graph "C:\Users\jaredmw2\Documents\media.gph"
	//summary statistics
ssc install outreg2
outreg2 using summary_statistics.doc, sum(log) keep(popularity_score ///
	tweet_favorite_count retweet_count america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga russia democrats korea trade new fakenews)


//some preliminary regressions with all newly generated variables
regress retweet_count america exclamation celebration link great russia democrats republican ///
	apology mention korea china economy we wall trade selfrefer biden president ///
	fakenews media trump border thank new good bad people maga
regress tweet_favorite_count america exclamation celebration link great russia democrats republican ///
	apology mention korea china economy we wall trade selfrefer biden president ///
	fakenews media trump border thank new good bad people maga
regress popularity_score america exclamation celebration link great russia democrats republican ///
	apology mention korea china economy we wall trade selfrefer biden president ///
	fakenews media trump border thank new good bad people maga

//regression on popularity score with only variables that seem relevant
regress popularity_score america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga russia democrats korea trade biden fakenews new good

//regression on popularity score with only variables that are definitely relevant
regress popularity_score america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga

//regressions with variables included in analysis in the final paper
regress tweet_favorite_count america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga russia democrats korea trade new fakenews
outreg2 using regression_output.doc, replace ctitle(Tweet Favorite Count) ///
	title(Impact of Linguistic Devices on Likes and Retweets)
regress retweet_count america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga russia democrats korea trade new fakenews
outreg2 using regression_output.doc, append ctitle(Retweet Count)
regress popularity_score america exclamation link great  ///
	mention china wall selfrefer president ///
	media people maga russia democrats korea trade new fakenews
outreg2 using regression_output.doc, append ctitle(Popularity Score)
