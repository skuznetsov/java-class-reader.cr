require "./lib/class_loader"

loader = Java::ClassLoader.new(true)
#loader.loadAllFromJarFile("data/rt.jar")
loader.indexJarFiles("data/")
loader.jars.each do |jarEntry|
     loader.loadAllFromJarFile(jarEntry.fileName)
end
#p loader.classes.first_value