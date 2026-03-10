
do
local count = 0
:: NIGGA ::
if count < 5 then 
	goto ADD
else
	print(count)
	goto OUTSIDE 
end

:: ADD ::
count = count + 1
print("Adding count:", count)
goto NIGGA
end


:: OUTSIDE ::
print("Just got outside")


local x
do
  local y = 12
  goto l1
  ::l2:: x = x + 1; goto l3
  ::l1:: x = y; goto l2
end
::l3:: ::l3_1:: assert(x == 13)


-- long labels
do
  local prog = [[
  do
    local a = 1
    goto l%sa; a = a + 1
   ::l%sa:: a = a + 10
    goto l%sb; a = a + 2
   ::l%sb:: a = a + 20
    return a
  end
  ]]
  local label = string.rep("0123456789", 40)
  prog = string.format(prog, label, label, label, label)
  assert(assert(load(prog))() == 31)
end


-- ok to jump over local dec. to end of block


while true do
  goto l4
  print("Loop here must not execute!")
  goto l1  -- ok to jump over local dec. to end of block
  goto l1  -- multiple uses of same label
  do
  local x = 45
  end 
  ::l1::
end
::l4::  assert(x == 13)

if print then
  goto l1   -- ok to jump over local dec. to end of block
  error("should not be here")
  goto l2   -- ok to jump over local dec. to end of block
  do
  local x
  end 
  ::l1:: ::l2::
else end


local function foo ()
 print("Executing foo")
  local a = {}
  goto l3
  ::l1:: a[#a + 1] = 1; goto l2;
  ::l2:: a[#a + 1] = 2; goto l5;
  ::l3::
  ::l3a:: a[#a + 1] = 3; goto l1;
  ::l4:: a[#a + 1] = 4; goto l6;
  ::l5:: a[#a + 1] = 5; goto l4;
  ::l6:: assert(a[1] == 3 and a[2] == 1 and a[3] == 2 and
              a[4] == 5 and a[5] == 4)
  if not a[6] then a[6] = true; goto l3a end   -- do it twice
end

::l6:: foo()


do   -- bug in 5.2 -> 5.3.2
  local x
  ::L1::
  local y             -- cannot join this SETNIL with previous one
  assert(y == nil)
  y = true
  if x == nil then
    x = 1
    goto L1
  else
    x = x + 1
  end
  assert(x == 2 and y == true)
end

-- bug in 5.3
do
  local first = true
  local a = false
  if true then
    goto LBL
    ::loop::
    a = true
    ::LBL::
    if first then
      first = false
      goto loop
    end
  end
  assert(a)
end

do   -- compiling infinite loops
  goto escape   -- do not run the infinite loops
  ::a:: goto a
  ::b:: goto c
  ::c:: goto b
end
::escape::
--------------------------------------------------------------------------------
-- testing closing of upvalues

local debug = require 'debug'

local function foo ()
  local t = {}
  do
  local i = 1
  local a, b, c, d
  t[1] = function () return a, b, c, d end
  ::lmao1::
  local b
  do
    local c
    t[#t + 1] = function () return a, b, c, d end    -- t[2], t[4], t[6]
    if i > 2 then goto lmao2 end
    do
      local d
      t[#t + 1] = function () return a, b, c, d end   -- t[3], t[5]
      i = i + 1
      local a
      goto lmao1
    end
  end
  end
  ::lmao2:: return t
end

local a = foo()
assert(#a == 6)
print("ASSERTION PASSED")

do
goto l1
print("This is should not print")
goto l1
:: l1::
print("Ended")
end

local function testG (a)
  if a == 1 then
    print("A == 1")
    goto Nigga
    error("should never be here!")
  elseif a == 1.5 then
  	goto Nigga
  	error("Should never be here!")
  	::Nigga:: print("Returning 1.5") return 1.5
  elseif a == 2 then goto l2
  elseif a == 3 then goto l3
  elseif a == 4 then
    goto Nigga  -- go to inside the block
    error("should never be here!")
    ::Nigga:: a = a + 1   -- must go to 'if' end
  else
    goto l4
    ::l4a:: a = a * 2; goto l4b
    error("should never be here!")
    ::l4:: goto l4a
    error("should never be here!")
    ::l4b::
  end
  do print("A val: ", a) return a end
  ::l2:: do return "2" end
  ::l3:: do return "3" end
  ::Nigga:: print("IF end returning a = ", a) return "1"
end

assert(testG(1) == "1", "FAILED TEST G 1")
assert(testG(1.5) == 1.5, "FAILED TEST G 1.5 ")
assert(testG(2) == "2", "FAILED TEST G 2")
assert(testG(3) == "3", "FAILED TEST G 3")
assert(testG(4) == 5, "FAILED TEST G 4")
assert(testG(5) == 10, "FAILED TEST G 5")


--------------------------------------------------------------------------------
local lol = "Hello"
do
local function log(msg)
	print(lol, msg)
end

end 

print'OK'