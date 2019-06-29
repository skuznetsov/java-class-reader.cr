require "./code_reader"
require "./constant_pool"
require "./constants"

module Java
    class ConstantPoolReader
        include Java::Constants

        getter minorVersion : UInt16 = 0
        getter majorVersion : UInt16 = 0
        getter accessFlags : UInt16 = 0
        getter thisClass : UInt16 = 0
        getter superClass : UInt16 = 0

        def initialize (rawData)
            @reader = Java::CodeReader.new(rawData)
            @constantPool = Java::ConstantPool.new(nil)
        end

        def getClassName()
            cp = @constantPool
            classTag = cp[@thisClass].as(ClassTag)
            idx = classTag.nameIndex
            utfTag = cp[idx].as(Utf8Tag)
            return utfTag.string
        end

        def getFriendlyClassName(className)
            name = className || self.getClassName()
            name = name.gsub('/', '.')
            return name
        end

        def getSuperClassName()
            cp = @constantPool
            return cp[cp[@superClass].nameIndex].string
        end

        def getConstantPool()
            return @constantPool
        end

        def getExternalClasses()
            cp = @constantPool
            results = [] of String

            cp && cp.buffer.each_with_index do |cp_entry, idx|
                break if !cp_entry # Long and double have double constant pool entries

                if cp_entry.is_a? ClassTag && idx != @thisClass
                    results << cp_entry.className
                end
            end

            return results
        end

        def read()
            magic = @reader.readUInt.to_s.hexbytes
            @minorVersion = @reader.readUShort
            @majorVersion = @reader.readUShort

            constantPoolCount = @reader.readUShort
            idx = 1
            while idx < constantPoolCount
                idx += 1
                tagCode = @reader.readByte
                case tagCode
                    when CONSTANT_Class
                        tag = ClassTag.new @constantPool
                        tag.nameIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_Utf8
                        tag = Utf8Tag.new @constantPool
                        length = @reader.readUShort
                        tag.string = @reader.readString length
                        @constantPool.addTag tag

                    when CONSTANT_NameAndType
                        tag = NameAndTypeTag.new @constantPool
                        tag.nameIndex = @reader.readUShort
                        tag.signatureIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_String
                        tag = StringTag.new @constantPool
                        tag.stringIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_Float
                        tag = FloatTag.new @constantPool
                        tag.float = @reader.readFloat
                        @constantPool.addTag tag

                    when CONSTANT_Integer
                        tag = IntegerTag.new @constantPool
                        tag.integer = @reader.readInt
                        @constantPool.addTag tag

                    when CONSTANT_Double
                        tag = DoubleTag.new @constantPool
                        tag.double = @reader.readDouble
                        @constantPool.addTag tag
                        idx += 1
                        @constantPool.addTag nil

                    when CONSTANT_Long
                        tag = LongTag.new @constantPool
                        tag.long = @reader.readLong
                        @constantPool.addTag tag
                        idx += 1
                        @constantPool.addTag nil

                    when CONSTANT_Fieldref
                        tag = FieldRefTag.new @constantPool
                        tag.classIndex = @reader.readUShort
                        tag.nameAndTypeIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_Methodref
                        tag = MethodRefTag.new @constantPool
                        tag.classIndex = @reader.readUShort
                        tag.nameAndTypeIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_InterfaceMethodref
                        tag = InterfaceMethodRefTag.new @constantPool
                        tag.classIndex = @reader.readUShort
                        tag.nameAndTypeIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_MethodHandle
                        tag = MethodHandleTag.new @constantPool
                        tag.referenceKind = @reader.readByte
                        tag.referenceIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_MethodType
                        tag = MethodTypeTag.new @constantPool
                        tag.descriptorIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_InvokeDynamic
                        tag = InvokeDynamicTag.new @constantPool
                        tag.bootstrapMethodAttributeIndex = @reader.readUShort
                        tag.nameAndTypeIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_Module
                        tag = ModuleTag.new @constantPool
                        tag.moduleNameIndex = @reader.readUShort
                        @constantPool.addTag tag

                    when CONSTANT_Package
                        tag = PackageTag.new @constantPool
                        tag.packageNameIndex = @reader.readUShort
                        @constantPool.addTag tag
                    else
                        raise Exception.new "Unknown constant tag"
                end                    
            end
            @accessFlags = @reader.readUShort
            @thisClass = @reader.readUShort
            @superClass = @reader.readUShort
        end

        def to_s
            result = ""
            @constantPool.buffer.each do |tag|
                unless tag.is_a?(NilTag)
                    result += "#{tag.tagName}: #{tag.to_s}\n"
                end
            end
            result
        end
    end
end