defmodule SimulatedUser do

    ##############################################
    # hatch n users to execute SimulatedUser.goUser
    # godpid is used when this user finish all his job assigned, it will tell godpid(mainprocess)
    # n must be length of behavior_form!!!
    def hatch_users(_behavior_form,n,_godpid) when n === 0, do: nil
    def hatch_users(behavior_form,n,godpid) do
      spawn(SimulatedUser,:goUser,[[godpid|Enum.at(behavior_form,n-1)]])
      hatch_users(behavior_form,n-1,godpid)
    end

    ###############################################
    # users behave 
    def goUser(behaviorform) do
        # parse blueprint
        [godpid,following_list,following_num,tweets_num,retweets_num,usernum] = behaviorform
        # Register account
        Twitter.Client.register_account("user"<>Integer.to_string(usernum),"a123")
        halt(1000) # wait for all users to finish their registration, so subscribe will not subscribe to user not registered yet
        # Log in
        {cookie,_tweets_live} = Twitter.Client.log_in("user"<>Integer.to_string(usernum),"a123")
        # Subscribe all subscribers in following_list
        subscribeusers(cookie,following_list)
        _tweets_live = Twitter.Client.refresh_tweetlive(cookie)
        # Send tweets
        send_tweets(cookie,tweets_num)
        # Log out
        _cookie = nil
        halt(1000)
        # Log back in
        {cookie,tweets_live} = Twitter.Client.log_in("user"<>Integer.to_string(usernum),"a123")
        # Send retweets
        send_retweets(cookie,tweets_live,retweets_num)
        # Log out
        _cookie = nil
        halt(1000)
        # Log back in
        {_cookie,tweets_live} = Twitter.Client.log_in("user"<>Integer.to_string(usernum),"a123")
        IO.puts "CLIENT > user#{usernum}'s tweet live after done all its work: #{inspect(tweets_live)}"
        # telling main process the requests it sends
        register_time = 1
        log_in_times = 3
        send godpid,{:jobFinished,{following_num,tweets_num,retweets_num,register_time,log_in_times}}
        # after finish assigned job, just login and log out, waiting for all other processes(users) to finish their job so that program can finish and exit
        # login_logout_login(usernum)
    end

    ##############################################
    # users' single behaviors

    def subscribeusers(_cookie,following_list) when length(following_list) === 0, do: nil
    def subscribeusers(cookie,following_list) do
        [head|tails] = following_list
        Twitter.Client.subscribe(cookie,"user"<>Integer.to_string(head))
        subscribeusers(cookie,tails)
    end

    def send_tweets(_cookie,tweets_num) when tweets_num === 0, do: nil
    def send_tweets(cookie,tweets_num) do
        Twitter.Client.send_tweet(cookie,get_random_string(10))
        send_tweets(cookie,tweets_num-1)
    end

    def send_retweets(_cookie,_tweets_live,retweets_num) when retweets_num === 0, do: nil
    def send_retweets(cookie,tweets_live,retweets_num) do
        idx_of_retweet = Enum.random(0..length(tweets_live)-1)
        Twitter.Client.send_retweet(cookie,get_random_string(10),Enum.at(tweets_live,idx_of_retweet))
        tweets_live = Twitter.Client.refresh_tweetlive(cookie)
        send_retweets(cookie,tweets_live,retweets_num-1)
    end

    def get_random_string(strlength) do
        list = String.split("abcdefghijklmnopqrstuvwxyz     1234567890#@","") |> List.delete("")
        Enum.take_random(list,strlength) |> List.to_string()
    end

    def halt(time) when time === 0, do: nil
    def halt(time) do
        halt(time-1)
    end

    def login_logout_login(usernum) do
        {_cookie,_tweetslive} = Twitter.Client.log_in("user"<>Integer.to_string(usernum),"a123")
        halt(1000)
        _cookie = nil
        halt(5000)
        login_logout_login(usernum)
    end
end