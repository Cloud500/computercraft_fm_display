local MyClass = {}


function MyClass.__init__(baseClass, data)
    self = {}
    self.data = data or "original"

    --self = { data = data }
    setmetatable(self, { __index = MyClass })
    return self
end

setmetatable(MyClass, { __call = MyClass.__init__ })


function MyClass:call(data)
    if data then
        print("Object sagt " .. data)
        else
        print("Object sagt " .. self.data)
    end
end

return MyClass