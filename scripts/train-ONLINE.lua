-- package.path=arg[0]:get_path() .. "modules/?.lua" .. ";/home/experimentos/HERRAMIENTAS/LUA_MODULES/share/;" .. package.path

april_print_script_header(arg)

hidden_layers = {}
columns = {}

cmd_opt_parser = cmdOpt{
  program_name = string.basename(arg[0]),
  argument_description = "",
  main_description = "Trains a model for indoor temperature forecasting",
  {
    index_name="data",
    description="Load data files (a comma separated list)",
    long="data",
    argument="yes",
    mode="always",
    filter=function(value) return value:tokenize(",") end,
    default_value="/home/experimentos/CORPORA/SML2010/NEW-DATA-1.T15.txt,/home/experimentos/CORPORA/SML2010/NEW-DATA-2.T15.txt",
  },
  {
    index_name="col",
    description="Column with data, the first is the forecasted column, several -c 'POS:WSIZE:MEAN:STDDEV:[diff | abs]' options are allowed",
    short="c",
    argument="yes",
    mode="always",
    filter=function(value)
      local t = value:tokenize(":")
      for i=1,4 do t[i]=tonumber(t[i]) end
      return t
    end,
    action=function(value)
      table.insert(columns, value)
    end,
  },
  {
    index_name="hsize",
    description="Future horizon size",
    long="hsize",
    argument="yes",
    mode="always",
    filter=tonumber,
  },
  {
    index_name="layer",
    description="Adds a hidden layer",
    long="layer",
    argument="yes",
    action=function(value)
      print("# Adding layer " .. value)
      table.insert(hidden_layers,
		   {
		     size = tonumber(value:match("^(.*):.*$")),
		     actf = value:match("^.*:(.*)$"),
		   })
    end,
  },
  {
    index_name="learning_rate",
    description="Learning rate",
    long="lr",
    argument="yes",
    mode="always",
    filter=tonumber,
    default_value=0.2,
  },
  {
    index_name="momentum",
    description="Momentum",
    long="mt",
    argument="yes",
    mode="always",
    filter=tonumber,
    default_value=0.2,
  },
  {
    index_name="weight_decay",
    description="Weight decay",
    long="wd",
    argument="yes",
    mode="always",
    filter=tonumber,
    default_value=1e-04,
  },
  {
    index_name="seed",
    description="Random seed",
    long="seed",
    argument="yes",
    mode="always",
    default_value=825725,
    filter=tonumber,
  },
  {
    index_name="best",
    description="Best filename",
    long="best",
    argument="yes",
  },
  {
    description = "shows this help message",
    short = "h",
    long = "help",
    argument = "no",
    action = function (argument) 
      print(cmd_opt_parser:generate_help()) 
      os.exit(1)
    end    
  }
}

local optargs = cmd_opt_parser:parse_args()
if type(optargs) == "string" then error(optargs) end
table.unpack_on(optargs, _G) -- this generates global variables from optargs

local weights_random = random(seed)
local input_size     = iterator(ipairs(columns)):select(2):field(2):reduce(math.add(),0) + 24

local mlp = ann.components.stack()
local input = input_size
for i=1,#hidden_layers do
  mlp:push(ann.components.hyperplane{
	     input  = input,
	     output = hidden_layers[i].size,
	     --
	     dot_product_weights = "w" .. i,
	     bias_weights        = "b" .. i,
				    })
  mlp:push(ann.components.actf[hidden_layers[i].actf]())
  input = hidden_layers[i].size
end
mlp:push(ann.components.hyperplane{
	   input = input,
	   output = hsize,
	   --
	   dot_product_weights = "w" .. #hidden_layers+1,
	   bias_weights        = "b" .. #hidden_layers+1,
				  })
mlp:push(ann.components.actf.linear())

local trainer = trainable.supervised_trainer(mlp, ann.loss.mse(), 1)
trainer:build()
trainer:randomize_weights{
  random     = weights_random,
  inf        = -0.1,
  sup        =  0.1,
  use_fanin  = true,
  use_fanout = true,
}

--
trainer:set_option("learning_rate", learning_rate)
trainer:set_option("momentum",      momentum)
trainer:set_option("weight_decay",  weight_decay)
--
trainer:set_layerwise_option("b.*", "weight_decay", 0)

printf("# ANN topology: %d inputs %s %d linear\n",
       trainer:get_input_size(),
       iterator(ipairs(hidden_layers)):
       map(function(k,v) return v.size,v.actf end):
       concat(" "),
       trainer:get_output_size())

----------------------
-- ONLINE ALGORITHM --
----------------------

local TARGET_POS = columns[1][1]
local MAX_WSIZE  = iterator(ipairs(columns)):select(2):field(2):reduce(math.max,0)

for _,filename in ipairs(data) do
  print("# PROCESSING ", filename)
  local pos            = 0
  local outputs        = matrix.col_major(MAX_WSIZE+hsize, hsize):zeros()
  local buffer         = matrix.col_major(MAX_WSIZE+hsize, #columns):zeros()
  local raw_buffer     = matrix.col_major(MAX_WSIZE+hsize, #columns):zeros()
  
  -- Move up the data of a matrix
  function move_data(m)
    local slice = m("2:",":"):clone()
    m({1,buffer:dim(1)-1}, ":"):copy(slice)
  end
  
  -- Updates the buffer with a new line of data
  function update_buffer(buf,d)
    local dest = pos+1
    if pos >= buf:dim(1) then move_data(buf) dest=pos end
    for i=1,#d do buf:set(dest, i, d[i]) end
  end

  -- Computes a line of data
  function compute_data(t)
    local raw = {}
    local d   = {}
    for i=1,#columns do
      local p,wsize,mean,stddev,mode = table.unpack(columns[i])
      local v = tonumber(t[p])
      table.insert(raw, v)
      if mode == "diff" then
	if pos > 0 then v = v - raw_buffer:get(pos,i) else v = 0 end
      elseif mode ~= "abs" then error("Incorrect column mode")
      end
      table.insert(d, (v - mean) / stddev)
    end
    update_buffer(raw_buffer, raw)
    return d
  end
  
  -- Computes the ANN input form the given position and for the given hour
  function compute_input(pos, hour)
    local input = matrix.col_major(1,trainer:get_input_size())
    -- hour
    input({1,1},{1,24}):zeros():set(1, hour+1, 1)
    -- columns
    local p = 24
    for i=1,#columns do
      local _,wsize,mean,stddev,mode = table.unpack(columns[i])
      local w = input({1,1},{p+1,p+wsize})
      w:copy( buffer:
	      select(2,i):
	      slice({pos-wsize+1},{wsize}):
	      clone():
	      rewrap(1,wsize) )
      p = p + wsize
    end
    return input
  end

  -- Computes the ANN output target
  function compute_target(buf)
    local target = matrix.col_major(1,trainer:get_output_size())
    target:copy( buf:
		 select(2,1):
		 slice({buf:dim(1)-hsize+1},{hsize}):
		 clone():
		 rewrap(1,hsize) )
    return target
  end
  
  -- Output reconstruction
  function reconstruct_output(pos,out)
    local p,wsize,mean,stddev,mode = table.unpack(columns[1])
    out = out*stddev + mean
    if mode == "diff" then
      local aux = raw_buffer:
      select(2,1):
      slice({pos-wsize+1},{wsize}):
      get(wsize)
      local acc = aux
      out:map(function(x)
		x   = x + acc
		acc = x
		return x
	      end)
    end
    return out
  end

  -- Computes every line of the current data filename
  for line in io.uncommented_lines(filename) do
    collectgarbage("collect")
    local t    = line:tokenize()
    local hour = tonumber(t[2]:match("(.+)%:.+"))
    update_buffer( buffer, compute_data(t) )
    if pos < MAX_WSIZE + hsize then pos = pos + 1 end
    --
    if pos >= MAX_WSIZE + hsize then
      -- It is ready to train with following pair of tokens
      local input  = compute_input(pos-hsize+1, hour)
      local target = compute_target(buffer)
      target_raw = compute_target(raw_buffer)
      
      -- First, computes loss with the data forecasted hsize quarters ago
      
      -- Show the output/target pair
      out_raw = outputs({MAX_WSIZE+1,MAX_WSIZE+1},":")
      print("OUTPUT: ", table.concat(out_raw:toTable(), " "))
      print("TARGET: ", table.concat(target_raw:toTable(), " "))
      -- Compute the loss
      local mae = ann.loss.mae():compute_loss(out_raw:contiguous(),
					      target_raw:contiguous())
      local mse = ann.loss.mse():compute_loss(out_raw:contiguous(),
					      target_raw:contiguous())
      printf("ERRORS: \t  MAE= %.4f    MSE= %.4f    RMSE= %.4f\n",
	     mae, mse, math.sqrt(mse/hsize))
      
      -- Finally, train using the pair of tokens
      trainer:train_step( input:contiguous(), target:contiguous() )
    end
    
    if pos >= MAX_WSIZE then
      -- It is ready to produce a forward
      local input = compute_input(pos, hour)
      local out   = trainer:calculate( input:contiguous() )
      out = reconstruct_output(pos,out)
      print("FORECAST: ", table.concat(out:toTable(), " "))
      update_buffer(outputs,out:toTable())
    end
    
  end
end

if best then trainer:save(best) end
