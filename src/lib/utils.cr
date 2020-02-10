def str(ptr : Bytes?)
    ptr = ptr || Bytes.empty
    result = String.new(ptr)
    return result
end
