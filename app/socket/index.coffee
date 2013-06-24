PEER_IDLE_TIMEOUT_MILLIS = 5000

planeManager = require('../modules/plane_manager')

exports.configure = (io) ->

	###
		Socket.IO config
	###

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
			if aircraft?
				aircraft.position = data.position
				aircraft.heading = data.heading

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
		setTimeout broadcastAircraftPositions, 500
		mapSockets.emit "aircraftData", planeManager.getDataForBroadcast()

	mapSockets.on "connection", (socket) ->
		socket.on "map_position_changed", (data) ->
			socket.broadcast.emit "plane_position_changed", data

