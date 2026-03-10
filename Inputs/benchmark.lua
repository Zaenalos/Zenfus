local static = {
	Iterations = 1e6,
	print = print,
	os = os,
	tostring = tostring
}
return (function(...)
		local _ENV = static
        print("Performance Benchmark")
        local Iterations = (500000 * 2)
        print("Iterations: " .. (Iterations))

        print("CLOSURE TEST.")
        local Start = os.clock()
        local TStart = Start
        local fun = (function()
            if not true then
                print("Start")
            end
        end)
        for Idx = 1, Iterations do
            fun()
        end
        print("Time:", os.clock() - Start .. "s")

        print("SETTABLE TEST.")
        local T = {}
        local toStr = tostring
        local strt = "Start "
        local g = toStr(Idx)
        Start = os.clock()
        for Idx = 1, Iterations do
            T[g] = strt .. g
        end

        print("Time:", os.clock() - Start .. "s")

        print("GETTABLE TEST.")
        Start = os.clock()
        for Idx = 1, Iterations do
            T[1] = T[(Idx)]
        end

        print("Time:", os.clock() - Start .. "s")
        print("Total Time:", os.clock() - TStart .. "s")
end)(...);