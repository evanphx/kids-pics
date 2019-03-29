--[[
	uploadFile(folder, file name, access token)
	Attempts to upload a file to dropbox!
--]]

lastupload = ""

local function uploadFile(file_path, file)
	--get the size of the file
	local filesize = lfs.attributes(file_path,"size")
	if filesize ~= nil then
		print("Uploading "..file_path.." size: "..filesize)
	else
		print("Failed to find "..file_path.."... something wen't wrong!")
		return
	end

	--Upload!
	b, c, h = fa.request{
		url = "http://10.0.1.102:24001/upload",
		method = "POST",
		headers = {
      ["Content-Length"] = filesize,
      ["Content-Type"] = "application/octet-stream",
      ["Camera-File"] = file,
    },
		body = "<!--WLANSDFILE-->",
		bufsize = 1460*10,
		file=file_path
	}

	print(c)
	print(b)

  return c
end

local function waitWlanConnect()
    while 1 do
        local res = fa.ReadStatusReg()
        local a = string.sub(res, 13, 16)
        a = tonumber(a, 16)
        if (bit32.extract(a, 15) == 1) then
            print("connect")
            break
        end
        if (bit32.extract(a, 0) == 1) then
            print("mode Bridge")
            break
        end
        if (bit32.extract(a, 12) == 1) then
            print("mode AP")
            break
        end
        sleep(2000)
    end
end

local function readConfig(file_name)
  for line in io.lines(file_name) do
    local s, e, cap = line:find("=")
    if (s ~= 1 or cap ~= "") then
      local key = line:sub(1, s - 1)
      local val = line:sub(e + 1)
      if (key == "lastupload") then
        lastupload = val
      end
    end
  end
end


local function writeConfig(cfg_name, _file)
  local wFile = io.open(cfg_name, "w")
  if (wFile == nil) then return end

  wFile:write("lastupload=".._file.."\n")
  io.close(wFile)
end


local function getInfo()
  readConfig("/lastupload.cfg")
end

rootDir = "/DCIM/101NIKON"

local function autoUpload()
  local lastPhoto = 0
  if (#lastupload > 0) then
    lastPhoto = tonumber(lastupload:sub(5,8))
  end

  for aFile in lfs.dir(rootDir) do
    local filePath = rootDir.."/"..aFile
    if (lfs.attributes(filePath, "mode") ~= "file") then
      goto continue
    end

    local photoNum = tonumber(aFile:sub(5, 8))
    print("considering "..filePath.. " num="..aFile:sub(5,8).." last="..lastupload:sub(5,8))
    if (lastPhoto >= photoNum ) then
      goto continue
    else
      lastPhoto = photoNum
    end

    print(filePath)

    local c = uploadFile(filePath, aFile)
    if c == 200 then
      --                        print(aFile, mod_date)
      writeConfig("/lastupload.cfg", aFile)
    end

    ::continue::
  end
  --            print(aDirectory..":end")
  lastPhoto = 0
end

print("Attempting 2...")

-- Main script
--waitWlanConnect()
getInfo()

print("autoUpload...")
autoUpload()
