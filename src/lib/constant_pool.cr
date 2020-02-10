require "./utils"
require "./constant_pool_reader"
require "./constants"

module Java
    class BaseTag
        property tag : Constants::Constant = Constants::Constant::None
    end

    class ClassTag < BaseTag
        getter constantPool : ConstantPool
        property className : Bytes = Bytes.empty
        property nameIndex : UInt16 = 0

        def className
            tag = @constantPool[self.nameIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def to_s (io : IO) : Nil
            io << str(self.className)
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Class
        end
    end

    class FieldRefTag < BaseTag
        getter constantPool : ConstantPool
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def text
            "#{str(self.fieldType)} #{str(self.className)}##{str(self.fieldName)}"
        end

        def className
            tag = @constantPool[self.classIndex].as?(ClassTag)
            return Bytes.empty unless tag
            tag.className.not_nil!
        end

        def fieldName
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.name.not_nil!
        end

        def fieldType
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.type.not_nil!
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Fieldref
        end
    end

    class MethodRefTag < BaseTag
        getter constantPool : ConstantPool
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def text
            "#{str(self.methodType)} #{str(self.className)}##{str(self.methodName)}"
        end

        def className
            tag = @constantPool[self.classIndex].as?(ClassTag)
            return Bytes.empty unless tag
            tag.className.not_nil!
        end

        def methodName
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.name.not_nil!
        end

        def methodType
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.type.not_nil!
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Methodref
        end
    end

    class InterfaceMethodRefTag < BaseTag
        getter constantPool : ConstantPool
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def text
            "#{str(self.interfaceMethodType)} #{str(self.className)}##{str(self.interfaceMethodName)}"
        end

        def className
            tag = @constantPool[self.classIndex].as?(ClassTag)
            return Bytes.empty unless tag
            tag.className.not_nil!
        end
        def interfaceMethodName
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.name.not_nil!
        end

        def interfaceMethodType
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.type.not_nil!
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::InterfaceMethodref
        end
    end

    class StringTag < BaseTag
        getter constantPool : ConstantPool
        property stringIndex : UInt16 = 0

        def value
            tag = @constantPool[self.stringIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def to_s (io : IO) : Nil
            io << String.new(self.value)
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::String
        end
    end

    class IntegerTag < BaseTag
        getter constantPool : ConstantPool
        property integer : Int32 = 0

        def value
            self.integer
        end

        def to_s (io : IO) : Nil
            io << self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Integer
        end
    end

    class FloatTag < BaseTag
        getter constantPool : ConstantPool
        property float : Float32 = 0.0

        def value
            self.float
        end

        def to_s (io : IO) : Nil
            io << self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Float
        end
    end

    class LongTag < BaseTag
        getter constantPool : ConstantPool
        property long : Int64 = 0

        def value
            self.long
        end

        def to_s (io : IO) : Nil
            io << self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Long
        end
    end

    class DoubleTag < BaseTag
        getter constantPool : ConstantPool
        property double : Float64 = 0.0

        def value
            self.double
        end

        def to_s (io : IO) : Nil
            io << self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Double
        end
    end

    class NameAndTypeTag < BaseTag
        getter constantPool : ConstantPool
        property nameIndex : UInt16 = 0
        property signatureIndex : UInt16 = 0

        def name 
            tag = @constantPool[self.nameIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def type
            tag = @constantPool[self.nameIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def text
            "#{str(self.name)}:#{str(self.type)}"
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::NameAndType
        end
    end

    class Utf8Tag < BaseTag
        getter constantPool : ConstantPool
        property string : Bytes? = Bytes.empty

        def text
            str(self.string)
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Utf8
        end
    end

    class MethodHandleTag < BaseTag
        getter constantPool : ConstantPool
        property referenceKind : UInt8? = nil
        property referenceIndex : UInt16? = nil
        @kind = ["", "getField", "getStatic", "putField", "putStatic", "invokeVirtual", 
                 "invokeStatic", "invokeSpecial", "newInvokeSpecial", "invokeInterface"]

        def kind
            @kind[self.referenceKind || 0]? || ""
        end

        def reference
            return nil if (self.referenceIndex || 0) > @constantPool.size
            case @constantPool[self.referenceIndex]
                when FieldRefTag
                    tag = @constantPool[referenceIndex].as(FieldRefTag)
                    tag && tag.text
                when MethodRefTag
                    tag = @constantPool[referenceIndex].as(MethodRefTag)
                    tag && tag.text
                when InterfaceMethodRefTag
                    tag = @constantPool[referenceIndex].as(InterfaceMethodRefTag)
                    tag && tag.text
                else
                    nil
            end
        end

        def text
            "#{self.kind} #{self.reference}"
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::MethodHandle
        end
    end

    class MethodTypeTag < BaseTag
        getter constantPool : ConstantPool
        property descriptorIndex : UInt16 = 0

        def descriptor
            tag = @constantPool[self.descriptorIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def text
            str(self.descriptor)
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::MethodType
        end
    end

    class InvokeDynamicTag < BaseTag
        getter constantPool : ConstantPool
        property bootstrapMethodAttributeIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def name 
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.name.not_nil!
        end

        def type
            tag = @constantPool[self.nameAndTypeIndex].as?(NameAndTypeTag)
            return Bytes.empty unless tag
            tag.type.not_nil!
        end

        def text
            "bootstrap: #{self.bootstrapMethodAttributeIndex} -> #{str(self.name)} -> #{str(self.type)}"
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::InvokeDynamic
        end
    end

    class ModuleTag < BaseTag
        getter constantPool : ConstantPool
        property moduleNameIndex : UInt16 = 0

        def name
            tag = @constantPool[self.moduleNameIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def text
            str(self.name)
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Module
        end
    end

    class PackageTag < BaseTag
        getter constantPool : ConstantPool
        property packageNameIndex : UInt16 = 0

        def name
            tag = @constantPool[self.packageNameIndex].as?(Utf8Tag)
            return Bytes.empty unless tag
            tag.string.not_nil!
        end

        def text
            str(self.name)
        end

        def to_s (io : IO) : Nil
            io << self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::Constant::Package
        end
    end

    class NilTag < BaseTag
    end

    class ConstantPool
        include Java::Constants
        @ca : Java::ConstantPoolReader?
        @cp : Array(BaseTag)

        def initialize (ca = nil)
            @ca = ca
            @cp = [] of BaseTag
            @cp << NilTag.new
        end

        def length
            @cp ? @cp.size : 0
        end

        def size
            self.length
        end

        def buffer
            @cp
        end

        def each_tag
            buffer.each_with_index do |tag, index|
                yield(tag, index) unless tag.is_a? NilTag
            end
        end

        def addTag(tagData)
            if tagData.nil?
                @cp << NilTag.new
            else
                @cp << tagData
            end
        end

        def getValue(idx)
            idx ||= 0
            if idx < 0 || idx >= @cp.size
                raise Exception.new "ConstantPool: Access outside of the boundaries"
            end
            return @cp[idx]
        end

        def [] (idx)
            return self.getValue(idx)
        end
    end
end

