"use strict"

###
	Services
###

socketServer = document.domain
namespaces = ['chat', 'map']

angular.module("NetTalk.services", [])
.value("version", "0.2.2")
.factory("Socket", ($rootScope) ->

			socketService = {}
			sockets = {}
			opts =
				reconnect: false

			for namespace in namespaces
				sockets[namespace] = io.connect(socketServer + '/' +  namespace, opts)
				do (namespace) ->
					socketService[namespace] =
						emit: (event, data) ->
							sockets[namespace].json.emit event, data

						on: (event, callback) ->
							sockets[namespace].on event, (data) ->
								$rootScope.$apply ->
									callback data

			socketService
)
.factory("Animation", ($window) ->
	requestId = null
	paused = false
	animate = ->
		requestId = $window.requestAnimationFrame(animate) unless paused
		TWEEN.update()
	
	{
		start: ->
			$window.cancelAnimationFrame(requestId) if requestId?
			paused = false
			animate()

		stop: ->
			paused = true
			$window.cancelAnimationFrame(requestId) if requestId?
	}
)
