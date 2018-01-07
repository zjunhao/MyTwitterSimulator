defmodule Twitter.Server do 
    use GenServer
    ### Usernames are case sensitive, so mentioned(@) too
    ### Hashtags are not case sensitive

    ################################### client side #####################################
    def start_link() do
        GenServer.start_link(__MODULE__,[], name: :twitterServer)
    end

    def get_states() do
        GenServer.call(:twitterServer,:get_states)
    end

    def register_account(username,password) do
        GenServer.call(:twitterServer,{:register,username,password})
    end

    def log_in(username,password) do 
        GenServer.call(:twitterServer,{:log_in,username,password})
    end

    def subscribe(cookie,subscriber) do
        username = cookie[:username]
        GenServer.call(:twitterServer,{:subscribe,username,subscriber})
    end

    def send_tweets(cookie,content) do
        username = cookie[:username]
        GenServer.call(:twitterServer,{:send_tweets,username,content})
    end

    # retweet_content is what you retweet, tuple contains every info about the original tweet you retweet
    # tweet_content is what you said about the retweet, which appears above the retweet, it's a string
    def send_retweets(cookie,tweet_content,retweet_content) do
        username = cookie[:username]
        GenServer.call(:twitterServer,{:send_retweets,username,tweet_content,retweet_content})
    end

    def get_tweets_from_subscriber(_cookie,subscriber) do
        GenServer.call(:twitterServer,{:query_subscriber,subscriber})
    end

    # hashtag: string
    def get_tweets_from_hashtag(_cookie,hashtag) do
        hashtag_preprocess = hashtag |> String.downcase() #  "###UF # football" => "###uf # football"
        hashtag_list = Regex.scan(~r/#(\s*[0-9a-zA-Z]+)/, hashtag_preprocess) |> Enum.map(fn x -> Enum.at(x,1)|>String.replace(" ","") end)  # "###uf # football" => ["uf","football"]
        GenServer.call(:twitterServer,{:query_hashtag,hashtag_list})
    end

    def get_tweets_from_mentioned(_cookie,mentioned) do
        mentioned_list = Regex.scan(~r/@(\s*[0-9a-zA-Z]+)/, mentioned) |> Enum.map(fn x -> Enum.at(x,1) |> String.replace(" ","") end) # "@user1 @@ USer2 3" => ["user1","USer2"]
        GenServer.call(:twitterServer,{:query_mentioned,mentioned_list})
    end
    
    #################################### server side ######################################
    def init(_states) do
        users = %{} #  %{ "username1" => ["password","subscribes","followers","tweetstoragepid1"], "username2" => ["password","subscribes","followers","tweetstoragepid2"]}
        tweets = [] #  [{id1,author1,content,time,hashtag(all in lower case),mentioned,retweeted_status},{id2,author2,content,time,hashtag(all lower case),mentioned,retweeted_status}]
        {:ok, [users,tweets]}
    end

    def handle_call(:get_states,_from,states) do
        {:reply,states,states}
    end

    def handle_call({:register,username,password},_from,states) do 
        [users,tweets] = states
        # if username already exists, return failure
        if Map.has_key?(users, username) do  
            {:reply,{"Err: Username already exists"},states}
        # if username not already exists, register it
        else                  
            # start a new process for this user, used for receiving all tweets the user should receive (sent from server), no matter user is online or offline
            tweetstoragepid = Twitter.ClientDataStorage.start()           
            {:reply,{"Success: User registered"},[Map.put(users,username,[password,"","",tweetstoragepid]),tweets]}
        end
    end

    def handle_call({:log_in,username,password},_from,states) do
        [users,_tweets] = states
        # if username does not exists
        unless Map.has_key?(users, username) do
            {:reply,{"Err: Username does not exist",nil},states}
        else 
            # if password incorrect
            if users[username] |> Enum.at(0) != password do
                {:reply,{"Err: Password incorrect",nil},states}
            # if username and password correct
            else 
                tweetstorage_pid = users[username] |> Enum.at(3)
                {:reply,{"Success: User logged in",%{username: username,tweetstorage_pid: tweetstorage_pid}},states}
            end 
        end
    end

    def handle_call({:subscribe,username,subscriber},_from,states) do 
        [users,tweets] = states
        # if user subscribes to himself
        if username === subscriber do
            {:reply,{"Err: Cannot subscribe to yourself"},states}
        else 
            # if subscriber does not exist
            unless Map.has_key?(users, subscriber) do 
                {:reply,{"Err: Subscriber does not exist"},states}
            else 
                subscriber_list = users[username] |> Enum.at(1) |> String.split("$$") |> List.delete("")
                # subscriber already been subscribed by this user
                if Enum.member?(subscriber_list,subscriber)  do 
                    {:reply,{"Err: Subscriber already been subscribed"},states}
                # All checks passed, update this new subscriber to user's subscriber list, and update subscriber his follower list
                else 
                    # update current user's following list
                    new_users1 = 
                        Map.get_and_update!(users, username, fn cur_value1 ->  #cur_value: [password,suscribes,followers,tweetstorage_pid]
                        [password1,suscribes1,followers1,tweetstorage_pid1] = cur_value1
                        new_value1 = [password1,subscriber<>"$$"<>suscribes1,followers1,tweetstorage_pid1]
                        {cur_value1,new_value1}
                    end) |> elem(1)
                    # update subscribed user's follower list
                    new_users2 = 
                    Map.get_and_update!(new_users1, subscriber, fn cur_value2 ->  #cur_value: [password,suscribes,followers,tweetstorage_pid]
                        [password2,suscribes2,followers2,tweetstorage_pid2] = cur_value2
                        new_value2 = [password2,suscribes2,username<>"$$"<>followers2,tweetstorage_pid2]
                        {cur_value2,new_value2}
                    end) |> elem(1)
                    # send all tweets by subscriber to user's twitter data storage
                    user_ds_pid = users[username] |> Enum.at(3)
                    sbs_tweets = tweets |> Enum.filter(fn tweet-> elem(tweet,1)===subscriber end) # all tweets sent from susbscriber in the past (before user subscribes subscriber)
                    Twitter.ClientDataStorage.push_and_sort(user_ds_pid,sbs_tweets)
                    {:reply,{"Success: succeed to subscribe"},[new_users2,tweets]}
                end
            end
        end 
    end

    # Each tweets stored in form {id,author,content,time,#filed,@field,retweeted_status}
    def handle_call({:send_tweets,username,content},_from,states) do
        # get id based on time
        id        = :os.system_time(:microsecond)
        # get time when sending tweet
        time      = :os.system_time(:microsecond)-18000000000 |> DateTime.from_unix(:microsecond) |> elem(1) #18,000,000,000 = 5 hours, which is eastern time zone
        # parse hashtag field; Results will be "hello @User1 @USER2 #Abc, #dEf" => ["abc","def"]
        hashtag   = Regex.scan(~r/#([0-9a-zA-Z]+)/, content) |> Enum.map(fn x -> Enum.at(x,1) |> String.downcase() end)
        # parse mentioned field; Results will be "hello @User1 @USER2 #Abc, #dEf" => ["User1","USER2"]
        mentioned = Regex.scan(~r/@([0-9a-zA-Z]+)/, content) |> Enum.map(fn x -> Enum.at(x,1) end)
        # retweets field is empty, because it is not a retweet
        retweeted_status = {}
        # form new tweet
        new_tweet = {id,username,content,time,hashtag,mentioned,retweeted_status}
        # send new tweet to user's twitter data storage and all his followers
        [users,tweets] = states
        recipients_list = [username] ++ (users[username] |> Enum.at(2) |> String.split("$$") |> List.delete(""))   # recipient = current user + current user's all followers
        Enum.each(recipients_list, fn recipient -> 
            users[recipient] |> Enum.at(3) |> Twitter.ClientDataStorage.push_notification_tweets([new_tweet])
        end)
        # save new tweet
        {:reply,{"Success: succeed to send tweet"},[users,[new_tweet|tweets]]}
    end

    def handle_call({:send_retweets,username,content,retweet},_from,states) do
        # get id based on time
        id        = :os.system_time(:microsecond)
        # get time when sending tweet
        time      = :os.system_time(:microsecond)-18000000000 |> DateTime.from_unix(:microsecond) |> elem(1) #18,000,000,000 = 5 hours, which is eastern time zone
        # parse hashtag field; Results will be "hello @User1 @USER2 #Abc, #dEf" => ["abc","def"]
        hashtag   = Regex.scan(~r/#([0-9a-zA-Z]+)/, content) |> Enum.map(fn x -> Enum.at(x,1) |> String.downcase() end)
        # parse mentioned field; Results will be "hello @User1 @USER2 #Abc, #dEf" => ["User1","USER2"]
        mentioned = Regex.scan(~r/@([0-9a-zA-Z]+)/, content) |> Enum.map(fn x -> Enum.at(x,1) end)
        # retweets field 
        retweeted_status = retweet
        # form new tweet
        new_tweet = {id,username,content,time,hashtag,mentioned,retweeted_status}
        # send new retweet to user's twitter data storage and all followers
        [users,tweets] = states
        recipients_list = [username] ++ (users[username] |> Enum.at(2) |> String.split("$$") |> List.delete(""))
        Enum.each(recipients_list, fn recipient -> 
            users[recipient] |> Enum.at(3) |> Twitter.ClientDataStorage.push_notification_tweets([new_tweet])
        end)
        # save the retweet
        {:reply,{"Success: succeed to send retweet"},[users,[new_tweet|tweets]]}
    end

    def handle_call({:query_subscriber,subscriber},_from,states) do
        [users,tweets] = states
        unless Map.has_key?(users, subscriber) do
            {:reply,{"Err: subscriber you try to query does not exist",nil},states}
        else
            queryresult = tweets |>  Enum.filter(fn tweet-> elem(tweet,1)===subscriber end)
            if length(queryresult) === 0 do
                {:reply,{"Success: subscriber does not have any tweet",queryresult},states}
            else
                {:reply,{"Success: succeed to get tweets by subscriber",queryresult},states}
            end
        end
    end

    def handle_call({:query_hashtag,hashtag_list},_from,states) do
        if hashtag_list === [] do
            {:reply,{"Err: Fail to get tweets using hashtag, input for query not valid",nil},states}
        else
            [_users,tweets] = states
            queryresult = tweets |> Enum.filter(fn tweet-> MapSet.subset?(MapSet.new(hashtag_list), MapSet.new(elem(tweet,4))) end)
            if length(queryresult) ===  0 do
                {:reply,{"Success: no result under current hashtag",queryresult},states}
            else
                {:reply,{"Success: succeed to find tweets under current hashtag",queryresult},states}
            end
        end
    end

    def handle_call({:query_mentioned,mentioned_list},_from,states) do
        if mentioned_list === [] do
            {:reply,{"Err: Fail to get tweets using mentioned, input for query not valid",nil},states}
        else
            [_users,tweets] = states
            queryresult = tweets |> Enum.filter(fn tweet-> MapSet.subset?(MapSet.new(mentioned_list), MapSet.new(elem(tweet,5))) end)
            if length(queryresult) ===  0 do
                {:reply,{"Success: no result under current mentioning",queryresult},states}
            else
                {:reply,{"Success: succeed to find tweets under current mentioning",queryresult},states}
            end
        end
    end
end