require "./constant_pool_reader"
require "./constants"

module Java
    class BaseTag
        getter tagName : String = ""
    end

    class ClassTag < BaseTag
        getter constantPool : ConstantPool
        getter tagName : String = "Class"
        property className : String = ""
        property nameIndex : UInt16 = 0

        def className
            if @constantPool
                stringTag = @constantPool[self.nameIndex].as(Utf8Tag)
                return stringTag ? stringTag.string : ""
            else
                return ""
            end
        end

        def to_s
            self.className
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Class
        end
    end

    class FieldRefTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "FieldRef"
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0
        def text
            "#{self.fieldType} #{self.className}##{self.fieldName}"
        end

        def className
            tag = @constantPool[self.classIndex].as(ClassTag)
            tag ? tag.className : ""
        end

        def fieldName
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.name : ""
        end

        def fieldType
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.type : ""
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Fieldref
        end
    end

    class MethodRefTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "MethodRef"
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def text
            "#{self.methodType} #{self.className}##{self.methodName}"
        end

        def className
            if self.classIndex.nil? 
                ""
            else
                tag = @constantPool[self.classIndex].as(ClassTag)
                tag ? tag.className : ""
            end
        end

        def methodName
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.name : ""
        end

        def methodType
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.type : ""
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Methodref
        end
    end

    class InterfaceMethodRefTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "InterfaceMethodRef"
        property classIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def text
            "#{self.interfaceMethodType} #{self.className}##{self.interfaceMethodName}"
        end

        def className
            tag = @constantPool[self.classIndex].as(ClassTag)
            tag ? tag.className : ""
        end
        def interfaceMethodName
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.name : ""
        end

        def interfaceMethodType
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.type : ""
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_InterfaceMethodref
        end
    end

    class StringTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "String"
        property stringIndex : UInt16 = 0

        def value
            tag = @constantPool[self.stringIndex].as(Utf8Tag)
            tag ? tag.string : ""
        end

        def to_s
            self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_String
        end
    end

    class IntegerTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Integer"
        property integer : Int32 = 0

        def value
            self.integer.to_s
        end

        def to_s
            self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Integer
        end
    end

    class FloatTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Float"
        property float : Float32 = 0.0

        def value
            self.float.to_s
        end

        def to_s
            self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Float
        end
    end

    class LongTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Long"
        property long : Int64 = 0

        def value
            self.long.to_s
        end

        def to_s
            self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Long
        end
    end

    class DoubleTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Double"
        property double : Float64 = 0.0

        def value
            self.double.to_s
        end

        def to_s
            self.value
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Double
        end
    end

    class NameAndTypeTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "NameAndType"
        property nameIndex : UInt16 = 0
        property signatureIndex : UInt16 = 0

        def name 
            stringTag = @constantPool[self.nameIndex].as(Utf8Tag)
            stringTag ? stringTag.string : ""
        end

        def type
            stringTag = @constantPool[self.nameIndex].as(Utf8Tag)
            stringTag ? stringTag.string : ""
        end

        def text
            "#{self.name}:#{self.type}"
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_NameAndType
        end
    end

    class Utf8Tag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Utf8"
        property string : String = ""

        def to_s
            self.string
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Utf8
        end
    end

    class MethodHandleTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "MethodHandle"
        property referenceKind : UInt8? = nil
        property referenceIndex : UInt16? = nil
        @kind = ["", "getField", "getStatic", "putField", "putStatic", "invokeVirtual", 
                 "invokeStatic", "invokeSpecial", "newInvokeSpecial", "invokeInterface"]

        def kind
            self.referenceKind ? @kind[self.referenceKind || 0]? : ""
        end

        def reference
            case @constantPool[self.referenceIndex].class
                when FieldRefTag
                    tag = @constantPool[referenceIndex].as(FieldRefTag)
                    tag ? tag.text : ""
                when MethodRefTag
                    tag = @constantPool[referenceIndex].as(MethodRefTag)
                    tag ? tag.text : ""
                when InterfaceMethodRefTag
                    tag = @constantPool[referenceIndex].as(InterfaceMethodRefTag)
                    tag ? tag.text : ""
            end
        end

        def text
            "#{self.kind} #{self.reference}"
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_MethodHandle
        end
    end

    class MethodTypeTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "MethodType"
        property descriptorIndex : UInt16 = 0

        def descriptor
            stringTag = @constantPool[self.descriptorIndex].as(Utf8Tag)
            stringTag ? stringTag.string : ""
        end

        def text
            self.descriptor
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_MethodType
        end
    end

    class InvokeDynamicTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "InvokeDynamic"
        property bootstrapMethodAttributeIndex : UInt16 = 0
        property nameAndTypeIndex : UInt16 = 0

        def name 
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.name : ""
        end

        def type
            tag = @constantPool[self.nameAndTypeIndex].as(NameAndTypeTag)
            tag ? tag.type : ""
        end

        def text
            "bootstrap: #{self.bootstrapMethodAttributeIndex} -> #{self.name} -> #{self.type}"
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_InvokeDynamic
        end
    end

    class ModuleTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Module"
        property moduleNameIndex : UInt16 = 0

        def name
            stringTag = @constantPool[self.moduleNameIndex].as(Utf8Tag)
            stringTag ? stringTag.string : ""
        end

        def text
            self.name
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Module
        end
    end

    class PackageTag < BaseTag
        getter constantPool : ConstantPool
        property tagName : String = "Package"
        property packageNameIndex : UInt16 = 0

        def name
            stringTag = @constantPool[self.packageNameIndex].as(Utf8Tag)
            stringTag ? stringTag.string : ""
        end

        def text
            self.name
        end

        def to_s
            self.text
        end

        def initialize(cp)
            @constantPool = cp
            @tag = Java::Constants::CONSTANT_Package
        end
    end

    class NilTag < BaseTag
    end

    class ConstantPool
        include Java::Constants
        @ca : Java::ConstantPoolReader?
        @cp : Array(BaseTag)

        def initialize (ca)
            @ca = ca
            @cp = [] of BaseTag
            @cp << NilTag.new
        end

        def length
            return @cp.size
        end

        def buffer
            return @cp
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

