request = require 'request'
fs = require 'fs'
util = require 'gulp-util'
q = require 'q'
qlimit = require 'qlimit'
limit = qlimit(1)

team = process.env['ESA_TEAM_NAME']
token = process.env['ESA_ACCESS_TOKEN']
endpoint = 'https://api.esa.io/v1'

module.exports = () ->
  ids = []
  getIds = (page)->
    deferred = q.defer()
    request({
      uri: "#{endpoint}/teams/#{team}/posts?q=in:Archived&per_page=100&page=#{page}"
      headers:
        Authorization: "Bearer #{token}"
    }, (err, response, body)->
      return deferred.reject(err) if err
      
      unless response.statusCode == 200
        return deferred.reject(response)

      json = JSON.parse(body)
      for post in json.posts
        ids.push post.number
      deferred.resolve(json.next_page)
    )
    deferred.promise.then((nextPage)->
      return getIds(nextPage) if nextPage
      return ids
    )

  tryToDelete = (id, deferred = null)->
    deferred = deferred || q.defer()
    request(
      uri: "#{endpoint}/teams/#{team}/posts/#{id}"
      method: 'DELETE'
      headers:
        Authorization: "Bearer #{token}"
    , (err, response)->
      return deferred.reject(err) if err
      if response.statusCode == 429
        console.log 'Waiting...'
        setTimeout(->
          tryToDelete(id, deferred)
        , 1000 * 900)
        return
        
      if response.statusCode == 204
        util.log "Delete #{id}"
        return deferred.resolve()
        
      deferred.reject()
    )
    
    deferred.promise

  getIds(1).then((ids)->
    q.all(ids.map(limit((id)->
      tryToDelete(id)
    )))
  ).catch((e)->
    console.trace e
  )
