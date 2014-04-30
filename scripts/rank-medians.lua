-- INPUT: a list of files with stats (median at 4 column)
local col   = 1
local data  = {}
for i=1,#arg do data[i] = matrix.fromTabFilename(arg[i])(':',col) end
for i=2,#arg do assert(data[1]:size() == data[i]:size()) end
local data = matrix.join(2, table.unpack(data))

local CONF = 0.99
local REP  = 10000
local N    = data:dim(1)-100
local rnd  = random(1234)
local resampling = stats.bootstrap_resampling{
  population_size = N,
  repetitions     = REP,
  sampling        = function() return data:select(1,rnd:randInt(101,N)) end,
  initial         = function() return {} end,
  reducer         = function(acc,row)
    local argmin = select(2,row:min())
    acc[argmin] = (acc[argmin] or 0) + 1
    return acc
  end,
  postprocess = function(acc)
    return iterator(ipairs(acc)):select(2):map(math.mul(1/N)):table()
  end,
  verbose = true,
}

-- change the shape of the data
local data = {}
for j=1,#arg do
  data[j] = data[j] or {}
  for i=1,REP do table.insert(data[j], resampling[i][j]) end
  table.sort(data[j])
end

for i=1,#arg do
  local a,b = stats.confidence_interval(data[i], CONF)
  printf("[%.3f, %.3f] => %.3f +- %.3f\n", a, b, (a+b)/2, (a-b)/2)
end
