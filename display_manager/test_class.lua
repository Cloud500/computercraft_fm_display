local MyClass = {}


function MyClass.__init__(baseClass, data)
    self = {}
    self.data = data or "original"

    --self = { data = data }
    setmetatable(self, { __index = MyClass })
    return self
end

setmetatable(MyClass, { __call = MyClass.__init__ })

function MyClass:printData()
    print(self.data)
end

function MyClass:do_things(data)
    print(self.data .. " " .. data)
end

return MyClass