defmodule Twitterclone do
  ### Simulator that spawns multiple clients and do various twitter operations via server 
  
  def main(args) do
    {n,s,a,b} = Twitter.Parseargs.parse_args(args)
    behavior_form = UserBehavior.get_userbehavior_form(n,s,a,b)

    # Spawn Twitter Server
    Twitter.Server.start_link()
    # Simulate multiple users
    {time,_} = :timer.tc(fn-> 
          SimulatedUser.hatch_users(Enum.reverse(behavior_form),length(behavior_form),self())
          {follow,tweets,retweets,register,login} = loop(n,0,0,0,0,0)  
          IO.puts "\nAll users finish their tasks, simulation finished"
          IO.puts "Total subscribing requests server handled: #{follow}"
          IO.puts "Total send_tweet requests server handled: #{tweets}"
          IO.puts "Total send_retweet requests server handled: #{retweets}"
          IO.puts "Total register requests server handled: #{register}"
          IO.puts "Total login requests server handled: #{login}"
          IO.puts "Total requests handled by server: #{follow+tweets+retweets+register+login}"
    end)
    IO.puts "Total time taken for these requests: #{time/1000000}s"
    
  end

  defp loop(n,follow,tweets,retweets,register,login) when n === 0, do: {follow,tweets,retweets,register,login}
  defp loop(n,follow,tweets,retweets,register,login) do
    receive do
      {:jobFinished,statistic_of_behavior} -> 
          {following_num,tweets_num,retweets_num,register_time,log_in_times} = statistic_of_behavior
          loop(n-1,follow+following_num,tweets+tweets_num,retweets+retweets_num,register+register_time,login+log_in_times) 
      _  -> 
          loop(n,follow,tweets,retweets,register,login)
    end
  end

end