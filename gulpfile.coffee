gulp = require 'gulp'
del = require 'del'

gulp.task 'clean', ->
  del ['qiita', 'qiita-dest', '.progress']

gulp.task 'retrieve-qiita-items', ->
  require './src/qiita_to_md'

gulp.task 'retrieve-qiita-images', ->
  images = require './src/qiita_images'
  gulp.src('./qiita/**/*.md', {base: './qiita'})
  .pipe images()
  .pipe gulp.dest('./qiita-dest')


gulp.task 'push-items-to-esa', ->
  esa = require './src/esa'

  gulp.src './qiita-dest/**/*.md'
  .pipe esa({progressFile: './.progress'})

gulp.task 'delete-archived-in-esa', ->
  delArchived = require './src/delete-archived-in-esa'
  delArchived()
