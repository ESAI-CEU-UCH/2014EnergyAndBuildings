filename=arg[1]
field=tonumber(arg[2] or 1)
value=arg[3] or "0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.8;0.9;1.0;1.5;2.0"

N=0
dict = {}
list = iterator(ipairs(string.tokenize(value, " ,;:\t\n"))):
select(2):map(tonumber):table()

iterator(io.lines(arg[1])):call('tokenize'):field(field):map(tonumber):
map(function(mae)
      N=N+1
      for _,w in ipairs(list) do if mae < w then coroutine.yield(w) end end
    end):
apply(function(w) dict[w] = (dict[w] or 0) + 1 end)

str = iterator(ipairs(list)):select(2):
map(function(w) return w,string.format("%.6f",(dict[w] or 0)/N) end):
concat(" ")

print(str)
