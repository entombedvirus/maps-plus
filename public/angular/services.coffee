"use strict"

###
	Services
###

socketServer = document.domain
namespaces = ['ctrl', 'map']

app = angular.module("NetTalk.services", [])

app.value("version", "0.2.2")

for namespace in namespaces
	opts =
		reconnect: false
	do (namespace) ->
		app.factory(namespace + "Socket", ($rootScope) ->
			socket = io.connect(socketServer + '/' +  namespace, opts)

			{
				emit: (event, data) ->
					socket.json.emit event, data

				on: (event, callback) ->
					socket.on event, (data) ->
						$rootScope.$apply ->
							callback data
			}
		)

app.factory("Animation", ($window) ->
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

app.factory "aircraftControls", ->
	code: null
	position: null
	heading: 0 #due north
	speed: 0

