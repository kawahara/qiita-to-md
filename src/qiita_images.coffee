through = require 'through2'
request = require 'request'
mkdirp = require 'mkdirp'
fs = require 'fs'
q = require 'q'
util = require 'gulp-util'

token = process.env['QIITA_ACCESS_TOKEN']
team = process.env['QIITA_TEAM']
prefix = process.env['IMAGE_PREFIX'] || '../../images'
dir = "./qiita-dest/images"
retrieveImage = (image) ->
  deferred = q.defer()
  headers = {}
  if image.match(/\.qiita\.com\/files/)
    headers.Authorization = "Bearer #{token}"
  request(image, {
    encoding: null
    headers: headers
  }, (err, response, body) ->
    return deferred.reject(err) if err
    deferred.resolve({response: response, body: body})
  )
  deferred.promise

module.exports = ->
  return through.obj((file, encoding, callback)->
    buffer = file.contents
    regexp = new RegExp("https?:\/\/(#{team}\.qiita\.com\/files\/([^\) \"]+)|qiita-image-store\.s3\.amazonaws.com\/([^\) \"]+))", 'g')
    matched = buffer.toString().match(regexp)
    return callback(null, file) unless matched

    promises = []
    for image in matched
      do (image)->
        fileName = image.match(/\/([^\/]+)$/)[1]
        promises.push (
          retrieveImage(image)
          .then((response)->
            deferred = q.defer()
            mkdirp(dir, {}, ->
              imageFileName = "#{dir}/#{fileName}"
              util.log "Save #{imageFileName}"
              fs.writeFile("#{imageFileName}", response.body, {
              }, ->
                deferred.resolve()
              )
            )

            deferred.promise
          )
        )
    
    q.all(promises).then(->
      content = buffer.toString()
      for image in matched
        fileName = image.match(/\/([^\/]+)$/)[1]
        content = content.split(image).join("#{prefix}/#{fileName}")

      file.contents = new Buffer(content)
      util.log "Replace #{file.relative}"
      callback(null, file)
    ).catch((e)->
      console.trace e
    )
  )