path = require 'path'
fs = require 'fs'

require 'shelljs/global'

unAMD = (src, reqPath='./') ->
  requires = src.match /define\((\[.*\])[ ,\)]+function[ ]*\((.*)\)/
  exports = src.match /return\s+([^;]*)[;\s]*?\}\);\s*?$/
  src = src.replace /define\(.*?\{/, ''
  src = src.replace /(return\s+.*\s*?\}\);\s*?$|\}\);\s*?$)/, ''
  if requires?
    modules = eval requires[1]
    names = requires[2].split(',').map (s) -> s.trim()
    req = ''
    for i in [0...modules.length]
      req += "var #{ names[i] } = " if names[i]?.length > 0
      req += "require('#{ reqPath }#{ modules[i] }');\n"
    src = "#{ req }\n#{ src }\n"
  if exports?
    src += "\nmodule.exports = #{ exports[1] };"
  return src

findFiles = (location) ->
  find(location).filter (file) -> !fs.statSync(file).isDirectory()

work_dir = path.resolve __dirname, './../'
modernizr_dir = path.join work_dir, './node_modules/modernizr'
lib_dir = path.join work_dir, './lib'
tests_dir = path.join work_dir, './test'

# cleanup
if test '-d', lib_dir
  rm '-rf', "#{ lib_dir }/*"
  
if test '-d', tests_dir
  rm '-rf', "#{ tests_dir }/*"

# copy modernizr source
cd modernizr_dir
cp '-r', './src/*', "#{ lib_dir }/"
cp '-r', './feature-detects/*', "#{ tests_dir }/"

# replace asynchronous defines with require and exports
cd lib_dir
for file in findFiles '.'
  src = cat file
  unAMD(src).to file

cd tests_dir
for file in findFiles '.'
  src = cat file
  depth = file.split('/').length
  libPath = './'
  for [0...depth]
    libPath += '../'
  libPath += 'lib/'
  unAMD(src, libPath).to file
