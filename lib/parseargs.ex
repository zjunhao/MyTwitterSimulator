defmodule Twitter.Parseargs do 
    
    def parse_args(args) do
      unless length(args) == 4 do
        IO.puts "Ussage: ./twittersimulator n s a b"
        IO.puts "n: number of users you want to simulate; n must be positive integer" 
        IO.puts "s: param of zipf distribution; should be positive; example values(1,2,3,...)"
        IO.puts "a,b: params to control number of tweets each user sent, which is a*number_of_followers+b; a,b must be positive" 
        raise ArgumentError, message: "Your input arguments are not in correct form"
      else
        {n,_} = Enum.at(args,0) |> Integer.parse() 
        {s,_} = Enum.at(args,1) |> Integer.parse() 
        {a,_} = Enum.at(args,2) |> Integer.parse() 
        {b,_} = Enum.at(args,3) |> Integer.parse() 
        {n,s,a,b}
      end
    end
   
  
  end