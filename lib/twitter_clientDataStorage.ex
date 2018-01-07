defmodule Twitter.ClientDataStorage do
    # Each user spawns a ClientDataStorage(CDS) process, to simulate local cache 
    # Whenever server have update tweets about this user, server send that updates to CDS process, no matter user is online or offline
    # When user logged in, get tweet live(which is all contents in this process) automatically
    # Or whenever user wants to get the newest version of tweet live, call get_tweetlive(cookie) in this module
    def start do
        spawn(fn -> tweetstorage([]) end)
    end

    # Respond to client request, return tweets live back to corresponding client 
    def get_tweetlive(cookie) do
        data_storage_pid = cookie[:tweetstorage_pid]
        send data_storage_pid,{:get_tweets,self()}
        receive do
            {:twitter_live,tweets} -> tweets
        end
    end

    # Respond to server request, add new tweet pushed from server to this client's tweet live
    # form of new tweet should be list, say [tweet1,tweet2]
    def push_notification_tweets(data_storage_pid,newtweet) do
        send data_storage_pid,{:add_tweet,newtweet}
    end
    
    # Used for subscribe function, add new tweets in list and then sort all tweets in data storage according to send time
    # form of new tweet should be list, say [tweet1,tweet2]
    def push_and_sort(data_storage_pid,newtweet) do
        send data_storage_pid,{:add_and_sort,newtweet}
    end

    # Simulating local caching of tweet live for each user
    # server sends new tweets to local cache once tweets related to this user are updated
    # Client gets its tweet live by just fetching data from their only local caching
    defp tweetstorage(cur_client_tweets) do
        updated_client_tweets = receive do

            {:get_tweets,userpid} -> 
                send userpid,{:twitter_live,cur_client_tweets}
                cur_client_tweets

            {:add_tweet,newtweet} -> 
                unless is_list(newtweet) do
                    IO.puts "CLIENTDATASTORAGE > Err: Fail to receive tweet, tweet sent from server are not of type list"
                    cur_client_tweets
                else 
                    newtweet ++ cur_client_tweets
                end 

            {:add_and_sort,newtweet} ->
                unless is_list(newtweet) do
                    IO.puts "CLIENTDATASTORAGE > Err: Fail to receive tweet, tweet sent from server are not of type list"
                    cur_client_tweets
                else
                    newtweet ++ cur_client_tweets |> Enum.sort_by(fn tweet -> -elem(tweet,0)end)
                end

            invalid_request       ->
                IO.puts "CLIENTDATASTORAGE > Invalid request: #{inspect invalid_request}"
        end
        tweetstorage(updated_client_tweets)
    end

end