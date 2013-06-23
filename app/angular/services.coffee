"use strict"

###
	Services
###

socketServer = document.domain
namespaces = ['ctrl', 'chat', 'map']

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

.factory  'idGenerator', ->
	stringLength = 4
	base = 26
	offset = Math.random() * Math.pow(base, stringLength)
	# >> 0 get rid of the fractional part
	counter = offset >> 0

	convertToBase26 = (number) ->
		str = []
		until number is 0
			str.unshift String.fromCharCode((number % base) + 97)
			number = (number / base) >> 0
		str.unshift 'a' until str.length >= stringLength
		str[0...stringLength].join ''

	{
		next: ->
			convertToBase26 counter++
	}

.factory 'planeManager', (idGenerator) ->
	PRESET_POSITIONS =
		goldenGatePark: [37.76847577247013, -122.49210834503174]
		crissyField: [37.80542699570327, -122.46883749961853]
		sfo: [37.61967039695652, -122.37112998962402]

	planes = {}
	for name, pos of PRESET_POSITIONS
		code = idGenerator.next()
		planes[code] =
			code: code
			currentPosition: pos

	{
		findByCode: (code) ->
			planes[code]
	}
