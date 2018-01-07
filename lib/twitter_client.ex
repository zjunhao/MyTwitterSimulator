defmodule Twitter.Client do

    # username case sensitive
    # Datatype: username=>string, password=>string
    def register_account(username,password) do
        unless (is_bitstring(username) and is_bitstring(password)) do
            IO.puts "CLIENT > Err: Fail to register account, input format not correct (should be string)"   
        else 
            result = Twitter.Server.register_account(username,password)
            IO.puts "CLIENT > #{elem(result,0)}"
        end
    end

    # Ussage: {cookie,tweets_live} = Twitter.Client.log_in(username,password)
    # Datatype: username=>string, password=>string 
    # Return: if logged in successfully, return {%{username: username,tweetstorage_pid: pid},[tweet1,tweet2,...]}, else return {nil,nil}
    def log_in(username,password) do
        unless (is_bitstring(username) and is_bitstring(password)) do
            IO.puts "CLIENT > Err: Fail to login, input format not correct (username and password should be string)"   
            {nil,nil}  # return nil rather than  {cookie,tweetslive}
        else
            result = Twitter.Server.log_in(username,password)  # result in form {"Err/Success:blahblah",cookie}
            cookie = elem(result,1) 
            if cookie === nil do # if login fails due to username doesn't exist or password incorrect ...
                IO.puts "CLIENT > #{elem(result,0)}"
                {nil,nil}
            else # login successfully
                {cookie,refresh_tweetlive(cookie)}
            end
        end
    end

    # Datatype: cookie=>return value of log_in, subscriber=>string 
    # Once subscribing succeeds, all past tweets sent from subscriber are sent into current users local twitter data storage, and all tweets in that ds are sorted once according to time 
    def subscribe(cookie,subscriber) do
        if cookie === nil do  # user not log in
            IO.puts "CLIENT > Err: Fail to subscribe, user not logged in"
        else
            unless is_bitstring(subscriber) do
                IO.puts "CLIENT > Err: Fail to subscribe, input format not correct (subscriber should be string)"
            else
                result = Twitter.Server.subscribe(cookie,subscriber)
                IO.puts "CLIENT > #{elem(result,0)}"
            end
        end
    end

    # Datatype: cookie=>return value of log_in, content=>string 
    def send_tweet(cookie,content) do 
        if cookie === nil do  # user not log in
            IO.puts "CLIENT > Err: Fail to send tweet, user not logged in"
        else
            unless is_bitstring(content) do 
                IO.puts "CLIENT > Err: Fail to send tweet, input format incorrect (tweet content should be string)"
            else 
                result = Twitter.Server.send_tweets(cookie,content)
                IO.puts "CLIENT > #{elem(result,0)}"
            end
        end
    end

    # Datatype: cookie=>return value of log_in, content=>string, retweetcontent=>tweet tuple you received in your tweet live, can check normal format of tweet tuple from twitter_server.ex 
    def send_retweet(cookie,content,retweetcontent) do
        if cookie === nil do  # user not log in
            IO.puts "CLIENT > Err: Fail to send retweet, user not logged in"
        else 
            unless is_bitstring(content) and is_tuple(retweetcontent) do # check if type of content and retweet correct
                IO.puts "CLIENT > Err: Fail to send retweet, either content(should be string) or retweetcontent(should be tuple) are not in right type"
            else 
                result = Twitter.Server.send_retweets(cookie,content,retweetcontent)
                IO.puts "CLIENT > #{elem(result,0)}"
            end
        end
    end

    # Datatype: cookie=>return value of log_in, subscriber=>string 
    # Return: List of tweet tuple
    def get_tweets_from_subscriber(cookie,subscriber) do
        if cookie === nil do
            IO.puts "CLIENT > Err: Fail to get subscribed tweets, user not logged in"
        else
            unless is_bitstring(subscriber) do
                IO.puts "CLIENT > Err: Fail to get subscribed tweets, input format incorrect (subscriber should be string)"
            else
                # result in form {"Success: blahblahblah",[tweet1,tweet2,tweet3,...]}
                result = Twitter.Server.get_tweets_from_subscriber(cookie,subscriber)
                IO.puts "CLIENT > #{elem(result,0)}"
                elem(result,1)
            end
        end
    end
    
    # Datatype: cookie=>return value of log_in, hashtag=>string with hashtag simbol, case insensitive
    # hashtag example: "#UF#Football", equals to "#Uf # football", equals to "##uf #  FOOTBALL", which means tweets have both #uf and #football
    # Return: List of tweet tuple
    # Hashtag not case sensitive
    def get_tweets_from_hashtag(cookie,hashtag) do
        if cookie === nil do
            IO.puts "CLIENT > Err: Fail to get tweets from #, user not logged in"
        else
            unless is_bitstring(hashtag) do
                IO.puts "CLIENT > Err: Fail to get tweets from #, input query should be string"
            else
                # result in form {"Success: blahblahblah",[tweet1,tweet2,tweet3,...]}
                result = Twitter.Server.get_tweets_from_hashtag(cookie,hashtag)
                IO.puts "CLIENT > #{elem(result,0)}"
                elem(result,1)
            end
        end
    end
    
    # Datatype: cookie=>return value of log_in, mentioned=>string with @ simbol, case sensitive
    # example: "@UF@Football", equals to "@UF @ Football", equals to "@UF @ Football redundancyWontBeRead" which means tweets mentions both @UF and @Football
    # Return: List of tweet tuple
    # Mentioned case sensitive
    def get_tweets_from_mentioned(cookie,mentioned) do
        if cookie === nil do
            IO.puts "CLIENT > Err: Fail to get tweets from @, user not logged in"
        else
            unless is_bitstring(mentioned) do
                IO.puts "CLIENT > Err: Fail to get tweets from @, input query should be string"
            else
                # result in form {"Success: blahblahblah",[tweet1,tweet2,tweet3,...]}
                result = Twitter.Server.get_tweets_from_mentioned(cookie,mentioned)
                IO.puts "CLIENT > #{elem(result,0)}"
                elem(result,1)
            end
        end
    end

    # get tweet live from local twitter data storage
    # Datatype: cookie=>return value of log_in
    # Return: List of tweet tuple
    def refresh_tweetlive(cookie) do
        Twitter.ClientDataStorage.get_tweetlive(cookie)
    end
end