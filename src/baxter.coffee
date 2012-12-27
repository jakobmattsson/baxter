path = require 'path'
spawn = require('child_process').spawn

args = process.argv.slice 2
whenIndex = args.indexOf 'WHEN'
onIndex = args.indexOf 'ON'

if whenIndex == -1 || onIndex == -1
  console.log 'Invalid format! Use: baxter job WHEN bgjob ON trigger'
  process.exit 0

outer = args.slice(0, whenIndex)
inner = args.slice(whenIndex + 1, onIndex)
trigger = args.slice(onIndex + 1)[0]

runOnce = (f) ->
  hasRun = false
  () ->
    return if hasRun
    hasRun = true
    f.apply(this, arguments)

runMain = runOnce (callback) ->
  main = spawn outer[0], outer.slice(1)
  main.stdout.on 'data', process.stdout.write.bind(process.stdout)
  main.stderr.on 'data', process.stderr.write.bind(process.stderr)
  main.on 'exit', (code) ->
    callback()
    setTimeout ->
      process.exit(2)
    , 400

bgjob = spawn(inner[0], inner.slice(1))
bgjob.stderr.on 'data', process.stderr.write.bind(process.stderr)
bgjob.stdout.on 'data', (data) ->
  if data.toString().indexOf(trigger) != -1
    runMain bgjob.kill.bind(bgjob)
  process.stdout.write(data)
