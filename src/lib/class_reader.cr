module Java

    struct StringPos
        property currentPos
        property newPos

        def initialize(pos = 0, newPos = -1)
            @currentPos = pos
            @newPos = newPos
        end
    end

    struct SignatureParams
        @returnType = ""
        @parameterTypes = [] of String

        def returnType
            @returnType
        end

        def returnType=(value)
            @returnType = value
        end

        def parameterTypes
            @parameterTypes
        end

        def parameterTypes=(value)
            @parameterTypes = value
        end

        def initialize(returnType = "", parameterTypes = nil)
            @returnType = ret
            @parameterTypes = parameterTypes
        end
    end

    class ClassReader extend ConstantPoolReader
        def initialize(raw_data)
            super(raw_data)
        end

        def decodeDescriptorType(descriptor)
            codeToString = { 'B' => "byte", 'C' => "char", 'D' => "double", 'F' => "float", 'I' => "int",
                            'J' => "long", 'L' => "class", 'S' => "short", 'V' => "void", 'Z' => "boolean", '[' => "array"}

            signature = codeToString[descriptor[0]]
            return signature
        end

        def decodeAccessFlags(accessFlags)
            result = ""

            if (accessFlags & ACCESS_FLAGS.ACC_PUBLIC)
                result += "public "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_PRIVATE)
                result += "private "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_PROTECTED)
                result += "protected "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_STATIC)
                result += "static "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_FINAL)
                result += "final "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_SYNCHRONIZED)
                result += "synchronized "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_VOLATILE)
                result += "volatile "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_TRANSIENT)
                result += "transient "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_NATIVE)
                result += "native "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_INTERFACE)
                result += "interface "
            end

            if (accessFlags & ACCESS_FLAGS.ACC_ABSTRACT)
                result += "abstract "
            end

            return result
        end

        def decodeSignatureComponent(descriptor, pos)
            codeToString = { 'B' => "byte", 'C' => "char", 'D' => "double", 'F' => "float", 'I' => "int",
                            'J' => "long", 'S' => "short", 'V' => "void", 'Z' => "boolean"}
            result = ""

            case descriptor[pos] 
            when 'L'
                endPos = descriptor[pos.currentPos..-1] =~ /;/
                endPos = endPos == 0 ? descriptor.size : endPos + pos.currentPos
                result = descriptor[(pos.currentPos + 1)..endPos].gsub(/\//,".")
                pos.newPos = endPos
            when '['
                pos.currentPos += 1
                result = "#{self.decodeSignatureComponent(descriptor, pos)}[]"
            else
                result = codeToString[descriptor[pos]]
            end

            return result
        end

        def decodeSignature(descriptor)
            result = SignatureParams.new
            returnType = [] of String
            parameterTypes = [] of String
            resultArray = returnType

            (pos .. descriptor.length).each do
                case descriptor[pos]
                when '(' then resultArray = parameterTypes
                when ')' then resultArray = returnType
                else
                    posStruct = StringPos.new(pos, -1)
                    resultArray << self.decodeSignatureComponent(descriptor, posStruct)
                    if posStruct.newPos > -1
                        pos = posStruct.newPos
                    end
                end
            end

            result.returnType = resultArray[0]
            if parameterTypes.size > 0
                result.parameterTypes = parameterTypes
            end

            return result
        end

        def createFieldSignature(name, descriptor, accessType)
            "#{this.decodeAccessFlags(accessType)}#{this.decodeSignatureComponent(descriptor, StringPos.new(0, 0))} #{name};"
        end

        def createMethodSignature(name, descriptor, accessType)
            signatureParts = this.decodeSignature(descriptor)
            params = signatureParts && signatureParts.parameterTypes ? signatureParts.parameterTypes.join(", ") : ""
            return "#{this.decodeAccessFlags(accessType)}#{signatureParts.returnType} #{name}(#{params});"
        end

        def getFieldDescriptor(field)
            cp = @constantPool
            name = cp[field.nameIndex].as(Utf8Tag).string
            descriptor = cp[field.descriptorIndex].as(Utf8Tag).string
            return {accessFlagsString: this.decodeAccessFlags(field.accessFlags), name: name, descriptor: descriptor, type: this.decodeDescriptorType(descriptor), signature: this.decodeSignature(descriptor).returnType, accessFlags: field.accessFlags, text: this.createFieldSignature(name, descriptor, field.accessFlags)}
        end

        def getMethodCode(method)
            code =  nil
            method.attributes.each do |attr|
                if attr && attr.info && attr.info.code
                    code = attr.info.code
                end
            end

            return code
        end

        def getMethodDescriptor(method)
            cp = @constantPool
            name = cp[method.nameIndex].as(Utf8Tag).string
            descriptor = cp[method.signatureIndex].as(Utf8Tag).string
            return {
                accessFlagsString: this.decodeAccessFlags(method.accessFlags),
                name: name,
                descriptor: descriptor,
                signature: self.decodeSignature(descriptor),
                accessFlags: method.accessFlags,
                shortText: self.createMethodSignature(name, descriptor, method.accessFlags),
                longText: self.createMethodSignature("#{this.getFriendlyClassName()}.#{name}", descriptor, method.accessFlags)
            }
        end

        def getMethodAttributeByName (method, attributeName)
        end

        def getAnnotationValue(reader)
            tag = reader.readByte().as(Char)
            elementValue = { tag: tag }

            case (tag)
            when '['
                elementValue.values = [] of String
                numValues = reader.readUShort()
                (0...numValues).each do
                    elementValue.values.push(self.getAnnotationValue(reader))
                end
            when '@'
                elementValue.annotationValue = self.getAnnotation(reader)
            when 'c'
                elementValue.classInfoIndex = reader.readUShort()
            when 'e'
                typeNameIndex = reader.readUShort()
                constNameIndex = reader.readUShort()
                elementValue.enumConstValue = { typeNameIndex: typeNameIndex, constNameIndex: constNameIndex }
                break;
            when 'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z', 's'
                elementValue.constValueIndex = reader.readUShort()
            else
                puts("elementValue tag [#{tag}] is not defined")
            end

            return elementValue
        end

        def getAnnotation(reader)
            _annotation = {elementValuePairs: [] of String, typeIndex: 0}
            _annotation.typeIndex = reader.readUShort()
            numElementValuePairs = reader.readUShort()
            (0...numElementValuePairs).each do
                elementNameIndex = reader.readUShort()
                value = self.getAnnotationValue(reader)
                _annotation["elementValuePairs"] << { elementNameIndex: elementNameIndex, value: value }
            end
            return _annotation
        end

        def getAnnotations(reader)
            numAnnotations = reader.readUShort()
            annotations = [] of String
            (0...numAnnotations).each do
                annotations << self.getAnnotation(reader)
            end

            return annotations
        end

        def readAttributes(attributeNameIndex, bytes)

            reader = CodeReader.new(bytes)
            attribute = { attributeNameIndex: attributeNameIndex };


            item = @constantPool[attributeNameIndex]
            attribute.type = item.tag

            case item.tag
            when Constants.CONSTANT_Long, Constants.CONSTANT_Float, Constants.CONSTANT_Double, Constants.CONSTANT_Integer, Constants.CONSTANT_String
                attribute.type = Constants.ATTRIBUTE_ConstantValue
                attribute.constantValueIndex = reader.readUShort()
                return attribute
            when Constants.CONSTANT_Utf8
                case item.string
                    when Constants.ATTRIBUTE_Code
                        attribute["maxStack"] = reader.readUShort()
                        attribute["maxLocals"] = reader.readUShort()
                        codeLength = reader.readUInt()
                        attribute["code"] = reader.readBytes(codeLength)

                        exceptionTableLength = reader.readUShort()
                        attribute.exceptionTable = [] of Hash(String, String)
                        (0...exceptionTableLength).each do
                            startPC = reader.readUShort()
                            endPC = reader.readUShort()
                            handlerPC = reader.readUShort()
                            catchType = reader.readUShort()
                            attribute.exceptionTable << { startPC: startPC, endPC: endPC, handlerPC: handlerPC, catchType: catchType }
                        end

                        attributesCount = reader.readUShort()
                        attribute.attributes = [] of Hash(String, String)
                        (0...attributesCount).each do
                            attributeNameIndex = reader.readUShort()
                            attributeLength = reader.readUInt()
                            info = reader.readBytes(attributeLength)
                            attribute.attributes << { attributeNameIndex: attributeNameIndex, attributeLength: attributeLength, info: info }
                        end
                        return attribute;

                    when Constants.ATTRIBUTE_SourceFile
                        attribute.sourceFileIndex = reader.readUShort()
                        return attribute;

                    when Constants.ATTRIBUTE_Exceptions
                        numberOfExceptions = reader.readUShort()
                        attribute.exceptionIndexTable = [] of UShort;
                        (0...numberOfExceptions).each do
                            attribute.exceptionIndexTable << reader.readUShort()
                        end
                        return attribute

                    when Constants.ATTRIBUTE_InnerClasses
                        numberOfClasses = reader.readUShort()
                        attribute.classes = [] of Hash(String, String)
                        (0...numberOfClasses).each do
                            inner = Hash(String, String).new
                            inner.inner_classInfoIndex = reader.readUShort()
                            inner.outer_classInfoIndex = reader.readUShort()
                            inner.innerNameIndex = reader.readUShort()
                            inner.innerClassAccessFlags = reader.readUShort()
                            attribute.classes << inner
                        end
                        return attribute

                    when Constants.ATTRIBUTE_MethodParameters
                        parametersCount = reader.readByte()
                        attribute.parameters = [] of Hash(String, String)
                        (0...parametersCount).each do
                            parameterNameIndex = reader.readUShort()
                            parameterAccessFlags = reader.readUShort()
                            attribute.parameters << { parameterNameIndex: parameterNameIndex, parameterAccessFlags: parameterAccessFlags }
                        end
                        return attribute

                    when Constants.ATTRIBUTE_Signature
                        attribute.signatureIndex = reader.readUShort()
                        return attribute

                    when Constants.ATTRIBUTE_BootstrapMethods
                        numBootstrapMethods = reader.readByte()
                        attribute.bootstrap_methods = [] of Hash(String, String)
                        (0...numBootstrapMethods).each do
                            bootstrapMethodRef = reader.readUShort()
                            numBootstrapArguments = reader.readUShort()
                            bootstrapArguments = [] of UShort
                            (0...numBootstrapArguments).each do
                                bootstrapArgument = reader.readUShort()
                                bootstrapArguments.push(bootstrapArgument)
                            end
                            attribute.bootstrapMethods << { bootstrapMethodRef, bootstrapArguments }
                        end
                        return attribute
                        
                    when Constants.ATTRIBUTE_RuntimeVisibleAnnotations,
                    Constants.ATTRIBUTE_RuntimeInvisibleAnnotations
                        attribute.annotations = this.getAnnotations(reader)
                        return attribute
                    when Constants.ATTRIBUTE_RuntimeVisibleParameterAnnotations,
                         Constats.ATTRIBUTE_RuntimeInvisibleParameterAnnotations
                        numParameters = reader.readByte()
                        attribute.parameterAnnotations = [] of Hash(String, String)
                        (0...numParameters).each do
                            attribute.parameterAnnotations << this.getAnnotations(reader)
                        end
                        return attribute
                when Constants.ATTRIBUTE_Deprecated,
                when Constants.ATTRIBUTE_Synthetic
                        return attribute

                when Constants.ATTRIBUTE_EnclosingMethod
                        attribute.classIndex = reader.readUShort()
                        attribute.methodIndex = reader.readUShort()
                        return attribute
                when Constants.ATTRIBUTE_AnnotationDefault
                        attribute.defaultValue = this.getAnnotationValue(reader)
                        return attribute;
                else
                    console.log("This attribute type is not supported yet. [" + JSON.stringify(item) + "]");
                end
            else
                console.log("This attribute type is not supported yet. [" + JSON.stringify(item) + "]");
            end
        end

        def read()
            super.read()

            @interfaces = [] of UShort
            interfacesCount = this.reader.readUShort()
            (0...interfacesCount).each do
                index = this.reader.readUShort()
                if index != 0
                    this.interfaces << index
                end
            end

            @fields = [] of Object
            fieldsCount = @reader.readUShort()
            (0...fieldsCount).each do
                accessFlags = @reader.readUShort()
                nameIndex = @reader.readUShort()
                descriptorIndex = @reader.readUShort()
                attributesCount = @reader.readUShort()
                fieldInfo = {
                    accessFlags: accessFlags,
                    nameIndex: nameIndex,
                    descriptorIndex: descriptorIndex,
                    attributesCount: attributesCount,
                    attributes: []
                }
                (0...attributesCount).each do
                    attributeNameIndex = this.reader.readUShort()
                    attributeLength = this.reader.readUInt()
                    info = this.reader.readBytes(attributeLength)
                    fieldInfo.attributes << { attributeNameIndex: attributeNameIndex, attributeLength: attributeLength, info: info }
                end
                this.fields << fieldInfo
            end

            this.methods = []
            methodsCount = this.reader.readUShort()
            (0...methodsCount).each do
                accessFlags = this.reader.readUShort()
                nameIndex = this.reader.readUShort()
                signatureIndex = this.reader.readUShort()
                attributesCount = this.reader.readUShort()
                methodInfo = {
                    accessFlags: accessFlags,
                    nameIndex: nameIndex,
                    signatureIndex: signatureIndex,
                    attributesCount: attributesCount,
                    attributes: []
                }
                (0...attributesCount).each do
                    attributeNameIndex = this.reader.readUShort()
                    attributeLength = this.reader.readUInt()
                    info = this.readAttributes(attributeNameIndex, this.reader.readBytes(attributeLength))
                    attribute = {
                        attributeNameIndex: attributeNameIndex,
                        attributeLength: attributeLength,
                        info: info
                    }
                    methodInfo.attributes << attribute
                end

                this.methods << methodInfo
            end

            this.attributes = []
            attributesCount = this.reader.readUShort()
            (0...attributesCount).each do
                attributeNameIndex = this.reader.readUShort()
                attributeLength = this.reader.readUInt()
                info = this.readAttributes(attributeNameIndex, this.reader.readBytes(attributeLength))
                attribute = {
                    attributeNameIndex: attributeNameIndex,
                    attributeLength: attributeLength,
                    info: info
                }
                this.attributes << attribute
            end
        end
    end
end