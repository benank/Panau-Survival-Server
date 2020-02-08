function xor(a,b)
    return bit32.bxor(a, b)
  end
  function toBits(num)
      local t={}
      while num>0 do
          rest=math.fmod(num,2)
          t[#t+1]=rest
          num=(num-rest)/2
      end
      local bits = {}
      local lpad = 8 - #t
      if lpad > 0 then
          for c = 1,lpad do table.insert(bits,0) end
      end
      for i = #t,1,-1 do table.insert(bits,t[i]) end
      return table.concat(bits)
  end
  function toDec(bits)
      local bmap = {128,64,32,16,8,4,2,1}
      local bitt = {}
      for c in bits:gmatch(".") do table.insert(bitt,c) end
      local result = 0
      for i = 1,#bitt do
          if bitt[i] == "1" then result = result + bmap[i] end
      end
      return result
  end
  function SCRYPT(str)
      str = tostring(str)
      local ciphert = {}
      for c in cipher:gmatch(".") do table.insert(ciphert,c) end
      local block = {}
      for ch in str:gmatch(".") do
          local c = toBits(string.byte(ch))
          table.insert(block,c)
      end
      for i = 1,#block do
          local bitt = {}
          local bit = block[i]
          for c in bit:gmatch(".") do table.insert(bitt,c) end
          local result = {}
          for i = 1,8,1 do
              table.insert(result,xor(ciphert[i],bitt[i]))
          end
          block[i] = string.char(toDec(table.concat(result)))
      end
      return table.concat(block)
  end
  function SCRYPTVec(str)
      local ciphert = {}
      local vec = {}
      local vtype = 1
      local vect = 0
      for c in cipher:gmatch(".") do table.insert(ciphert,c) end
      local block = {}
      for ch in str:gmatch(".") do
          local c = toBits(string.byte(ch))
          table.insert(block,c)
      end
      for i = 1,#block do
          local bitt = {}
          local bit = block[i]
          for c in bit:gmatch(".") do table.insert(bitt,c) end
          local result = {}
          for i = 1,8,1 do
              table.insert(result,xor(ciphert[i],bitt[i]))
          end
          block[i] = string.char(toDec(table.concat(result)))
      end
      local raw = table.concat(block)
      for i in string.gmatch(raw, "%,") do vtype = vtype + 1 end
      for i = 1,vtype do
          vec[i] = tonumber(string.match(raw, '%-?%d+'))
          raw = string.gsub(raw, '%d+', "", 1)
          raw = string.gsub(raw, '%,', "", 1)
          raw = string.gsub(raw, '%d+', "", 1)
      end
      if vtype == 2 then
          vect = Vector2(vec[1], vec[2])
      elseif vtype == 3 then
          vect = Vector3(vec[1], vec[2], vec[3])
      end
      return vect
  end
  class 'CiBase' 
  function CiBase:__init()
  if LocalPlayer:GetValue("SecCGlobal") ~= nil then
      cipher = LocalPlayer:GetValue("SecCGlobal")
  else
      cipher = ""
      for i = 1, 8 do
          local r = math.random(0, 1)
          cipher = cipher .. tostring(r)
      end
      LocalPlayer:SetValue("SecCGlobal", cipher)
  end
  end
  cisec = CiBase()