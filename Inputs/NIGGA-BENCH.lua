local _G = _G
return (function(...)
  local_G.print("Performance Benchmark")
  local Iterations = 1000000
  local_G.print("Iterations: " .. Iterations)
  local_G.print("CLOSURE TEST.")
  local Start = local_G.os.clock()
  local TStart = Start
  local fun = function()
    if false then
      local_G.print("Start")
    end
  end
  for Idx = 1, Iterations do
    fun()
  end
  local_G.print("Time:", local_G.os.clock() - Start .. "s")
  local_G.print("SETTABLE TEST.")
  local T = {}
  local toStr = local_G.tostring
  local strt = "Start "
  local g = toStr(local_G.Idx)
  Start = local_G.os.clock()
  for Idx = 1, Iterations do
    T[g] = strt .. g
  end
  local_G.print("Time:", local_G.os.clock() - Start .. "s")
  local_G.print("GETTABLE TEST.")
  Start = local_G.os.clock()
  for Idx = 1, Iterations do
    T[1] = T[Idx]
  end
  local_G.print("Time:", local_G.os.clock() - Start .. "s")
  local_G.print("Total Time:", local_G.os.clock() - TStart .. "s")
end)(...)
