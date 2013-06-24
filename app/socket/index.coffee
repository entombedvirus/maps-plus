PEER_IDLE_TIMEOUT_MILLIS = 5000

planeManager = require('../modules/plane_manager')

exports.configure = (io) ->

	###
		Socket.IO config
	###

	ctrlSocket = io.of('/ctrl')
	ctrlSocket.on "connection", (socket) ->
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

		socket.on "user_ctrl", (ctrlData) ->
			socket.set "lastActivityTimestamp", Date.now()
			startTimeoutTimer() unless timer?
			pairedSocket = getPairedSocketFor(socket)
			pairedSocket.emit "sync_ui", ctrlData if pairedSocket?

		socket.on "disconnect", ->
			console.log "client disconnected", socket.id
			socket.broadcast.emit 'peer_disconnected',
				client_id: socket.id

		socket.on "peer_inactive", ->
			socket.broadcast.emit "peer_inactive",
				client_id: socket.id

		socket.on "acquire_control_challenge", (data) ->
			success = planeManager.acquireControl data.code, socket.client_id
			if success
				socket.set "aircraftCode", planeManager.findByCode(data.code).code
				socket.emit "acquire_control_challenge_response",
					success: true
					code: data.code
			else
				socket.emit "acquire_control_challenge_response",
					success: false
					code: data.code

	mapSocket = io.of('/map')
	mapSocket.on "connection", (socket) ->
		socket.emit "aircraftData", planeManager.getDataForBroadcast()

		socket.on "map_position_changed", (data) ->
			planeManager.updatePosition data.code, data.position
			socket.broadcast.emit "plane_position_changed", data

