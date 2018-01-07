defmodule TwittercloneTest do
    use ExUnit.Case
    doctest Twitterclone
  
    test "greets the world" do
      assert Twitterclone.hello() == :world
    end

    Twitter.Server.start_link()

    Twitter.Client.register_account("frank1","a123")
    Twitter.Client.register_account("frank2","a123")
    Twitter.Client.register_account("frank3","a123")
    Twitter.Client.register_account("frank4","a123")
    Twitter.Client.register_account("frank5","a123")
    Twitter.Client.register_account("frank6","a123")

    ### test tweet and retweet
    {cookie_a1,_live} = Twitter.Client.log_in("frank1","a123")
    Twitter.Client.subscribe(cookie_a1,"frank2")

    {cookie_a2,_live} = Twitter.Client.log_in("frank2","a123")
    Twitter.Client.send_tweet(cookie_a2,"Lovely morning @myfriend #goodmood")

    {cookie_a3,_live} = Twitter.Client.log_in("frank3","a123")
    Twitter.Client.subscribe(cookie_a3,"frank1")
    Twitter.Client.send_retweet(cookie_a1,"retweet frank2 from frank1",{"1234","frank2","Lovely morning @myfriend #goodmood","time","goodmood","myfriend",{}})

    IO.puts "tweet live of frank1, #{inspect Twitter.Client.refresh_tweetlive(cookie_a1)}"
    IO.puts "tweet live of frank2, #{inspect Twitter.Client.refresh_tweetlive(cookie_a2)}"
    IO.puts "tweet live of frank3, #{inspect Twitter.Client.refresh_tweetlive(cookie_a3)}"

    ### test subscribe
    {cookie_a1,_live} = Twitter.Client.log_in("frank1","a123")
    {cookie_a2,_live} = Twitter.Client.log_in("frank2","a123")
    {cookie_a3,_live} = Twitter.Client.log_in("frank3","a123")

    Twitter.Client.send_tweet(cookie_a1,"Lovely morning @myfriend #goodmood")
    Twitter.Client.send_tweet(cookie_a2,"Taco bell dinner on a saturday night @theStaff #GreatTheStaff")
    Twitter.Client.send_tweet(cookie_a1,"Jimmy Fellon!")
    
    Twitter.Client.subscribe(cookie_a3,"frank1")
    Twitter.Client.subscribe(cookie_a3,"frank2")


    IO.puts "tweet live of frank1, #{inspect Twitter.Client.refresh_tweetlive(cookie_a1)}"
    IO.puts "tweet live of frank2, #{inspect Twitter.Client.refresh_tweetlive(cookie_a2)}"
    IO.puts "tweet live of frank3, #{inspect Twitter.Client.refresh_tweetlive(cookie_a3)}"

    ###test query using hashtag
    {cookie_a1,_live} = Twitter.Client.log_in("frank1","a123")

    Twitter.Client.send_tweet(cookie_a1,"Lovely morning @myfriend #GoodMood #better")
    Twitter.Client.send_tweet(cookie_a1,"Taco bell dinner on a saturday night #good @theStaff #GreatTheStaff")
    Twitter.Client.send_tweet(cookie_a1,"Jimmy Fellon! #goodMood")

    searchresult = Twitter.Client.get_tweets_from_hashtag(cookie_a1,"####goodmood # better")
    IO.puts "search using ####goodmood # Better #{inspect searchresult}"
    searchresult = Twitter.Client.get_tweets_from_hashtag(cookie_a1,"#GOODMOOD #Better")
    IO.puts "search using #GOODMOOD #Better #{inspect searchresult}"
    searchresult = Twitter.Client.get_tweets_from_hashtag(cookie_a1,"####goodmood # Bet ter")
    IO.puts "search using ####goodmood # Bet ter #{inspect searchresult}"

    ### test query using subscriber
    {cookie_a1,_live} = Twitter.Client.log_in("frank1","a123")
    {cookie_a2,_live} = Twitter.Client.log_in("frank2","a123")
    {cookie_a3,_live} = Twitter.Client.log_in("frank3","a123")
    
    Twitter.Client.send_tweet(cookie_a1,"Lovely morning @myfriend #goodmood #better")
    Twitter.Client.send_tweet(cookie_a1,"Taco bell dinner on a saturday night #good @theStaff #GreatTheStaff")
    Twitter.Client.send_tweet(cookie_a3,"Jimmy Fellon! #goodMood")

    searchresult = Twitter.Client.get_tweets_from_subscriber(cookie_a2,"frank1")

    IO.puts "tweets posted by frank1 #{inspect searchresult}"

    ### test query using mentioned
    {cookie_a1,_live} = Twitter.Client.log_in("frank1","a123")
    {cookie_a2,_live} = Twitter.Client.log_in("frank2","a123")
    {cookie_a3,_live} = Twitter.Client.log_in("frank3","a123")
    
    Twitter.Client.send_tweet(cookie_a1,"Lovely morning @theStaff @myfriend #goodmood #better")
    Twitter.Client.send_tweet(cookie_a1,"Taco bell dinner on a saturday night #good @theStaff @ufacappella #GreatTheStaff")
    Twitter.Client.send_tweet(cookie_a1,"Jimmy Fellon! @THESTAFF  #goodMood")
    Twitter.Client.send_tweet(cookie_a1,"Good good study #goodMood")

    searchresult = Twitter.Client.get_tweets_from_mentioned(cookie_a2,"@theStaff")
    IO.puts "search using @theStaff #{inspect searchresult}"
    searchresult = Twitter.Client.get_tweets_from_mentioned(cookie_a2,"@theStaff@ufacappella")
    IO.puts "search using @theStaff@ufacappella #{inspect searchresult}"
    searchresult = Twitter.Client.get_tweets_from_mentioned(cookie_a3,"@theSTaff")
    IO.puts "search using @theSTaff #{inspect searchresult}"

end
