PEER_IDLE_TIMEOUT_MILLIS = 5000

planeManager = require('../modules/plane_manager')
util = require 'util'

exports.configure = (io) ->

	###
		Socket.IO config
	###
	hasNewDataToBroadcast = false

	ctrlSockets = io.of('/ctrl')
	ctrlSockets.on "connection", (socket) ->
		timer = null
		do startTimeoutTimer = ->
			socket.get "lastActivityTimestamp", (err, ts) ->
				return if err? or !ts?
				idleTime = Date.now() - ts
				if idleTime > PEER_IDLE_TIMEOUT_MILLIS
					timer = null
					socket.get "aircraftCode", (err, code) ->
						planeManager.releaseControl(code)
					socket.broadcast.emit("peer_inactive")
				else
					timer = setTimeout startTimeoutTimer, PEER_IDLE_TIMEOUT_MILLIS

		socket.on "user_ctrl", (data) ->
			socket.set "lastActivityTimestamp", Date.now()
			startTimeoutTimer() unless timer?
			aircraft = planeManager.findByCode data.code
			if aircraft? and util.isArray(data.position) and typeof data.position[0] is 'number'
				aircraft.position = data.position
				aircraft.heading = data.heading
				hasNewDataToBroadcast = true

		socket.on "disconnect", ->
			console.log "client disconnected", socket.id
			socket.broadcast.emit 'peer_disconnected',
				client_id: socket.id

		socket.on "peer_inactive", ->
			socket.broadcast.emit "peer_inactive",
				client_id: socket.id

		socket.on "acquire_control_challenge", (data) ->
			aircraft = planeManager.findByCode(data.code)
			success = planeManager.acquireControl data.code, socket.client_id
			if aircraft? && success
				socket.set "aircraftCode", planeManager.findByCode(data.code).code
				socket.emit "acquire_control_challenge_response",
					success: true
					code: data.code
					position: aircraft.position
					heading: aircraft.heading
					speed: aircraft.speed
			else
				socket.emit "acquire_control_challenge_response",
					success: false
					code: data.code


	mapSockets = io.of('/map')

	do broadcastAircraftPositions = ->
		return if hasNewDataToBroadcast is false
		mapSockets.emit "aircraftData", planeManager.getDataForBroadcast()
		hasNewDataToBroadcast = false
	setInterval broadcastAircraftPositions, 500

	mapSockets.on "connection", (socket) ->
		socket.json.emit "aircraftData", planeManager.getDataForBroadcast()


