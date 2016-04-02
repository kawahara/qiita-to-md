through = require 'through2'
request = require 'request'
fs = require 'fs'
util = require 'gulp-util'

team = process.env['ESA_TEAM_NAME']
token = process.env['ESA_ACCESS_TOKEN']
endpoint = 'https://api.esa.io/v1'

module.exports = (options = {}) ->
  progressFilePath = options.progressFile
  progress = []
  if progressFilePath
    try
      progressData = fs.readFileSync(progressFilePath)
      progress = progressData.toString().split("\n")
    catch e
      console.trace e

  pushData = (file, callback)->
    contents = file.contents.toString()
    title = contents.match(/Title\s+:\s(.*)$/m)[1]
    tagText = contents.match(/Tags\s+:\s(.*)$/m)[1]
    tags = []
    for tag in tagText.split(/, /)
      tags.push "##{tag}"
    if tags.length
      title = "#{title} #{tags.join(' ')}"
    title = title.replace(/\//g, '_')

    fileMatched = file.relative.match(/^((\d+)\/(\d+))\//)
    category = "Archived_Qiita/#{fileMatched[1]}"
    request.post({
      url: "#{endpoint}/teams/#{team}/posts"
      method: 'POST'
      headers:
        Authorization: "Bearer #{token}"
      json: true
      form:
        post:
          name: title
          body_md: contents
          category: category
          wip: false
          user: 'esa_bot'
    }, (err, response, body)->
      if err
        console.trace err
        callback(err, file)
        return
        
      if response.statusCode == 429
        util.log 'Waiting to recover rate-limit...'
        setTimeout(->
          pushData(file, callback)
        , 1000 * 905)
        return
      else if response.statusCode != 201
        return callback(err, file)

      unless body?.number
        util.log "Re-write #{file.relative}"
        setTimeout(->
          pushData(file, callback)
        , 1000 * 10)
        return

      util.log "Push post to esa.io: #{file.relative} to #{body.number}"
      callback(null, file) unless progressFilePath

      fs.appendFile(progressFilePath, "#{file.relative}\n", ->
        callback(null, file)
      )
    )

  return through.obj((file, encoding, callback)->
    if progress.indexOf(file.relative) != -1
      util.log "Skip #{file.relative}, because it's already posted."
      callback(null, file)
      return

    setTimeout(->
      pushData(file, callback)
    , 1000)
  )
