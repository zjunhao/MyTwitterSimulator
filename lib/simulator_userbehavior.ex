defmodule UserBehavior do


  ########################## functions to fill the user behavior form #############################
  # userbehavior form builds a blueprint of behavior for each user
  # userbehavior_form = [user1,user2,...,usern]
  # user1 = [[accounts user1 follows(in integer, starts from 1 not 0)],number of followers user1 has, number of tweets user1 will send, number of retweets user1 will send,number of current user(1 in this case)]
  def get_userbehavior_form(n,s,a,b) do
    c = calculate_C_in_zipf(n,s,0)
    fill_userbehavior_form_field2345(n,s,c,a,b) |> fill_userbehavior_form_field1(n,n)
  end

  defp fill_userbehavior_form_field2345(n,s,c,a,b) do
    Enum.reduce(Enum.to_list(1..n) |> Enum.reverse,[],fn (x,acc) -> 
      followernum = calculate_follower_number(x,n,s,c)
      tweetsnum   = (a * followernum + b) |> round
      retweetsnum = 1
      [[[],followernum,tweetsnum,retweetsnum,x]|acc]
    end)
  end

  defp fill_userbehavior_form_field1(behaviorform,_n,cur) when cur === 0, do: behaviorform
  defp fill_userbehavior_form_field1(behaviorform,n,cur) do
    follower_num = Enum.at(behaviorform,cur-1) |> Enum.at(1)
    if follower_num === 0 do
      fill_userbehavior_form_field1(behaviorform,n,cur-1)
    else
      new_behavior_form = let_follower_follow_cur(behaviorform,n,cur,follower_num) 
      fill_userbehavior_form_field1(new_behavior_form,n,cur-1)
    end
  end

  ######################### help functions for filling the form ##############################
  # Calculate parameter c using n and s in zipf distribution, calculate_C_in_zipf(n,s,0), the third param should be zero when call this function
  defp calculate_C_in_zipf(n,_s,sum) when n===0 do
    1/sum
  end
  defp calculate_C_in_zipf(n,s,sum) when n>0 do
    sum = sum + :math.pow(1/n,s)
    calculate_C_in_zipf(n-1,s,sum)
  end

  # Calculate how many users subscribe to current account;
  # n,s,c: params from zipf distribution; rank: users rank according to how many followers it has 
  defp calculate_follower_number(rank,n,s,c) do
    prb = c/:math.pow(rank,s) # probability of this user being followed (calculated using zipf distribution)
    n*prb |> Float.floor() |> round() # number of followers this user have according to probability calculated above
  end

  # let usernums in follower_num(Ranges from 1 to n) add cur in their following list
  defp let_follower_follow_cur(behaviorform,n,cur,follower_num) do
    follower_list = Enum.to_list(1..n)--[cur] |> Enum.take_random(follower_num)
    # let each user in follower list subscribes cur
    Enum.reduce(follower_list,behaviorform, fn (x,acc) -> 
      [subscribelist,followers,tweets,retweets,usernum] = Enum.at(acc,x-1)
      acc = List.delete_at(acc,x-1)
      List.insert_at(acc,x-1,[[cur|subscribelist],followers,tweets,retweets,usernum])
    end)
  end

end