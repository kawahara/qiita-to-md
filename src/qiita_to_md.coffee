request = require 'request'
link_header = require 'parse-link-header'
q = require 'q'
moment = require 'moment'
fs = require 'fs'
mkdirp = require 'mkdirp'
_ = require 'underscore'

token = process.env['QIITA_ACCESS_TOKEN']
team = process.env['QIITA_TEAM']
endpoint = "https://#{team}.qiita.com/api/v2"
getItems = (url) ->
  defer = q.defer()
  request(url, {
    headers:
      Authorization: "Bearer #{token}"
  }, (err, response, body)->
    return defer.reject(err) if err
    defer.resolve({response: response, body: body})
  )

  defer.promise

getItemsAndSave = (url, options = {})->
  options = _.extend({}, {
    autoPager: true
  }, options)

  responseData = null
  getItems(url)
  .then((data)->
    responseData = data
    promises = []

    for item in JSON.parse(data.body)
      do (item) ->
        createdAt = moment(item.created_at)
        updatedAt = moment(item.updated_at)
        tags = _.pluck(item.tags, 'name')
        body = """
Title      : #{item.title}
Qiita URL  : #{item.url}
Author     : #{item.user.name}
Created At : #{createdAt.format('YYYY/MM/DD HH:mm:ss')}
Updated At : #{updatedAt.format('YYYY/MM/DD HH:mm:ss')}
Tags       : #{tags.join(', ')}

---

#{item.body}"""

        deferred = q.defer()
        dir = "./qiita/#{createdAt.format('YYYY/MM')}"
        mkdirp(dir, {}, ->
          fs.writeFile("#{dir}/#{createdAt.format('YYYYMMDDHHmmss')}_#{item.id}.md", body, {
          }, ->
            deferred.resolve()
          )
        )
        promises.push deferred.promise
    q.all(promises)
  ).then(->
    link = link_header(responseData.response.headers.link)
    return getItemsAndSave(link.next.url) if link.next && options.autoPager
    return true
  )

getItemsAndSave("#{endpoint}/items?per_page=100").catch((e)->
  console.log e
)
