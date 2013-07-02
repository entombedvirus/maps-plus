"use strict"

###
  Filters
###

angular.module("NetTalk.filters", [])
.filter "title",
  ->
    (user) ->
      "#{user.id} - #{user.name}"