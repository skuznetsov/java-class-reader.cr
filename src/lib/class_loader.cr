require "zip"
require "./class_reader"
# require "./constant_pool_reader"

module Java
    class ClassLoader
        getter :classes
        getter :classRegistry
        getter :jars

        record JarFilesInUse, fileName : String, inUse : Bool do
            def fileName=(value)
                @fileName = value
            end

            def inUse=(value)
                @inUse = value
            end
        end

        def initialize (constantPoolOnly)
            @paths = [ __DIR__ ]
            @classRegistry = {} of String => Int32
            @classes = {} of String => ConstantPoolReader
            @jars = [] of JarFilesInUse
            @constantPoolOnly = !!constantPoolOnly
        end

        def logWarning (logEntry)
            logEntry = "#{Time.local}: #{logEntry}"
            puts logEntry if ENV["DEBUG"]?
        end

        def addPath (path)
            if !@paths.index(path)
                @paths << path
            end
        end
        
        def addClasspath (path)
            self.addPath(path)
        end
        
        def markJarInUse (className)
            if @classRegistry[className]
                jarIndex = @classRegistry[className]?
                if jarIndex
                    @jars[jarIndex].inUse = true
                end
            end
        end
    
        def getJarNameByClassName (className)
            if @classRegistry[className]
                jarIndex = @classRegistry[className]?
                if jarIndex
                    return @jars[jarIndex].fileName
                else
                    return nil
                end
            end
            return nil
        end
    
        def loadClassBytes (bytes)
            # classObject = this.constantPoolOnly ? ConstantPoolReader.new(bytes) : ClassReader.new(bytes)
            classObject = ConstantPoolReader.new(bytes)
            classObject.read()
            logWarning(classObject.to_s)
            @classes[classObject.getClassName()] = classObject
            classObject
        end
    
        def loadClassFromJar (className)
            classData = @classes[className];
            if classData
                return classData
            end
    
            if className =~ /^javax?\/|^\[/
                return nil
            end
    
            jarIndex = @classRegistry[className]?
            if jarIndex == nil
                # TODO: Add to separate structure to output in formatted way for further analysis
                self.logWarning("WARNING: Class '#{className}' is not found in the CLASSPATH.")
                return nil
            end

            classPath = @jars[jarIndex].fileName
            unless classPath
                unless className =~ /^javax?/
                    # puts("Class #{className} cannot be found in the paths defined in the CLASSPATH. Please add the path and try again.");
                end
                return nil
            end
    
            classData = nil
            if File.exists?(classPath)
                if classPath.ends_with?(".jar")
                    bytecode = ""

                    Zip::File.open(classPath) do |file|
                        entry = file["#{className}.class"]
                        entry.open do |io|
                            bytecode = io.gets_to_end
                        end
                    end
                else
                    classData = File.read(classPath)
                end
    
                self.loadClassBytes(classData);    
            else
                nil
            end
        end
    
        def loadClassFile (fileName)
            bytes = File.read(fileName)
            ca = self.loadClassBytes(bytes)
            unless @constantPoolOnly
                classes = ca.getExternalClasses()
                classes && classes.each do |className|
                    unless @classes[className]
                        self.getClass(className, true)
                    end
                end
            end
            return ca
        end
    
        def indexJarFile (fileName)
            @jars.each do |jarFile|
                if jarFile.fileName == fileName
                    self.logWarning("WARNING! Jar file '#{fileName}' was already added.")
                    return
                end
            end
            @jars << JarFilesInUse.new(fileName, false)
            jarIndex = @jars.size - 1
            Zip::File.open(fileName) do |zip|
                zipEntries = zip.entries            
                zipEntries && zipEntries.each do |zipEntry|
                    if zipEntry.file?
                        if zipEntry.filename.ends_with? ".class"
                            className = zipEntry.filename.chomp(".class")
                            if @classRegistry[className]?
                                jarFile = @jars[@classRegistry[className]].fileName
                                self.logWarning("#{fileName} -> WARNING! Jar file '#{className}' was already defined in #{jarFile}.")
                            else
                                @classRegistry[className] = jarIndex
                            end
                        end
                    end
                end 
            end
        end

        def loadAllFromJarFile (fileName)
            @jars.each do |jarFile|
                if jarFile.fileName == fileName
                    jarFile.inUse = true
                else
                    @jars << JarFilesInUse.new(fileName, true)
                end
            end
            Zip::File.open(fileName) do |zip|
                zipEntries = zip.entries            
                zipEntries && zipEntries.each do |zipEntry|
                    if zipEntry.file?
                        if zipEntry.filename.ends_with? ".class"
                            bytecode = zipEntry.open {|io| io.gets_to_end}
                            self.loadClassBytes(bytecode)
                        end
                    end
                end
            end
        end

        def isSimpleArray (className)
            return className.starts_with?('[') && !className.match(/^\[+L/)
        end
    
        def getClass(className, doNotThrow)
    
            return nil if self.isSimpleArray className
                
            className = className.gsub(/^\[*L|;$/, "")
            ca = @classes[className]
            
            return ca if ca

            @paths && @paths.each do |path|
                fileName = "#{path}/#{className}.class"
                if File.exists? fileName
                    return self.loadClassFile fileName
                end
            end
    
            classData = self.loadClassFromJar className
                
            return classData if classData
        end

        def loadClassFiles(dirName)
            self.addPath(dirName);
            files = Dir.glob("#{dirName.chomp("/")}/*")
            files.each do |fileName|
                if fileName.file?
                    if fileName.ends_with? ".class"
                        self.loadClassFile(fileName)
                    end
                elsif Dir.exists? fileName
                    self.loadClassFiles(fileName)
                end
            end
        end
        
        def indexJarFiles(dirName)
            self.addPath(dirName)
            files = Dir.glob("#{dirName.chomp("/")}/*")
            files.each do |filePath|
                if Dir.exists? filePath
                    self.indexJarFiles(filePath)
                elsif File.exists? filePath
                    if filePath.ends_with? ".jar"
                        self.indexJarFile(filePath)
                    end
                end
            end
        end
    end
end