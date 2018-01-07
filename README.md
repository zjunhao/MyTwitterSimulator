# MyTwitterSimulator
Build a twitter engine and simulate thousands of users interact with that engine

**What does this program do:**

   It starts a twitter server first;
   then calculate "behavior" for each user, which includes who it should subscribe to, how many tweets and retweets it should send at the end (content of tweets and comments on retweets are generated randomly);
   then spawns processes simulating users and telling these processes the "behavior" mentioned above
   
   On receiving the "behavior", each process first register an account, and then make subscribe, then send tweets and retweets, all according to "behavior"
   
   Notice that followers number of each user obeys zipf distribution, controlled by n and s. (user1 has the highest rank, has most of the followers and send largest number of tweets; usern has the lowest rank, has 0 follower and send smallest number of tweets)
   You can verify this by calling UserBehavior.get_userbehavior_form(n,s,a,b) 
   which returns [user1,user2,...,usern] -> user1 = [[accounts user1 follows],number of followers user1 has, _, _, _ ]
   you'll see the second field (number of followers userX has) of user1, user2, user3, ..., usern obeys zipf distribution

## How to run the simulator?
   a) cd into "twitterclone" folder
   b) mix escript.build
   c) ./twittersimulator n s a b     or      time ./twittersimulator n s a b
   
   Input type:
   n: number of users you want to simulate; n must be positive integer
   s: param of zipf distribution which controls the shape of distribution curve; should be positive; example values(1,2,3,...); P(x) = c/(x^s); followers number of each user obeys zipf distribution
   a,b: params to control number of tweets each user sent, which is a*number_of_followers+b; a,b must be positive

   Result type:
   Result will print out client behavior, like 
   CLIENT > Success: User registered
   CLIENT > Success: succeed to subscribe
   CLIENT > Success: succeed to send tweet
   
   And whenever any process finish all his behavior(finish subscribe and tweets and retweets sent reaches the number specified in "behavior")
   it will refresh its tweet live and print it out on screen

   When all processes finish their "behavior", the simulation system exits, and prints out various kinds of requests server handles in total, and time taken for handling these requests, like the following
   Total subscribing requests server handled: 675
   Total send_tweet requests server handled: 2000
   Total send_retweet requests server handled: 1000
   Total register requests server handled: 1000
   Total login requests server handled: 3000  
   Total requests handled by server: 7675
   Total time taken for these requests: 0.46439s

   form of tweet live:
   list of tuples, each tuple is a record of tweet, tuple includes:
   {tweetid,createdBy, tweetcontent, timeToCreate, hashtags in tweetcontent, mentions in tweetcontent, retweet}
   Notice that the retweet field contains all information of the original tweet(which means the whole original tweet tuple goes into the retweet field)
   example of tweet live:
   [{1511490133278537, "user2", "tweet from user 2 @twitterDeveloper", #DateTime<2017-11-23 21:22:13.278537Z>, [], ["twitterDeveloper"], {}},
    {1511490095038597, "user1", "HappyThanksGiving #ThanksGiving #holiday @UF", #DateTime<2017-11-23 21:21:35.038597Z>, ["thanksgiving", "holiday"], ["UF"],{}}]

## How to use twitter server seperately?
   If you want to test twitter server seperately, 
   a) iex -S mix
   b) Twitter.Server.start_link()     to start the server engine
   c) Twitter.Client.what_ever_function_you_want    
   you can find functions you can use in file twitter_client.ex, like register_account, log_in...
   ussage of each function is documented above them

   examples:
   iex -S mix

   Twitter.Server.start_link() 

   Twitter.Client.register_account("user1","a123")
   {cookie1,tweetlive1} = Twitter.Client.log_in("user1","a123")
   Twitter.Client.send_tweet(cookie1,"HappyThanksGiving #ThanksGiving #holiday @UF")

   Twitter.Client.register_account("user2","a123")
   {cookie2,tweetlive2} = Twitter.Client.log_in("user2","a123")
   Twitter.Client.send_tweet(cookie2,"tweet from user 2 @twitterDeveloper")

   Twitter.Client.subscribe(cookie1,"user2")
   tweetlive1_new = Twitter.Client.refresh_tweetlive(cookie1)
   Twitter.Client.send_retweet(cookie1,"comment on retweet",Enum.at(tweetlive1_new,0))
   tweetlive1_new = Twitter.Client.refresh_tweetlive(cookie1)
