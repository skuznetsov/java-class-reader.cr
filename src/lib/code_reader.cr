module Java
    class CodeReader
        
        def pc
            return @reader.pos
        end

        def pc= (value)
            @reader.pos = value
        end

        def initialize (code)
            if code.nil? 
                @reader = IO::Memory.new("")
            else
                @reader = IO::Memory.new(code)
            end
        end

        def eof
            return @reader.pos >= @reader.size
        end

        def readByte
            value = @reader.read_byte
            return value
        end
        
        def readUShort
            value = @reader.read_bytes(UInt16, IO::ByteFormat::BigEndian)
            return value
        end

        def readShort
            value = @reader.read_bytes(Int16, IO::ByteFormat::BigEndian)
            return value
        end

        def readInt
            value = @reader.read_bytes(Int32, IO::ByteFormat::BigEndian)
            return value
        end

        def readUInt
            value = @reader.read_bytes(UInt32, IO::ByteFormat::BigEndian)
            return value
        end
        
        def readLong
            value = @reader.read_bytes(Int64, IO::ByteFormat::BigEndian)
            return value
        end
        
        def readULong
            value = @reader.read_bytes(UInt64, IO::ByteFormat::BigEndian)
            return value
        end

        def readFloat
            value = @reader.read_bytes(Float32, IO::ByteFormat::BigEndian)
            return value
        end
        
        def readDouble
            value = @reader.read_bytes(Float64, IO::ByteFormat::BigEndian)
            return value
        end
        
        def readBytes(length)
            slice = Bytes.new(length)
            value = @reader.read(slice)
            return slice.to_s
        end

        def readString(length)
            slice = Bytes.new(length)
            value = @reader.read_utf8(slice)
            return String.new(slice)
        end
    end
end