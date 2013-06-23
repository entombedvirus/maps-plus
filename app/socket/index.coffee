PEER_IDLE_TIMEOUT_MILLIS = 5000

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
					socket.broadcast.emit("peer_inactive")
				else
					timer = setTimeout startTimeoutTimer, PEER_IDLE_TIMEOUT_MILLIS

		socket.on "user_ctrl", (ctrlData) ->
			socket.set "lastActivityTimestamp", Date.now()
			startTimeoutTimer() unless timer?
			socket.broadcast.emit "sync_ui", ctrlData

		socket.on "disconnect", ->
			console.log "client disconnected", socket.id
			socket.broadcast.emit 'peer_disconnected',
				client_id: socket.id

		socket.on "peer_inactive", ->
			socket.broadcast.emit "peer_inactive",
				client_id: socket.id

	mapSocket = io.of('/map')
	mapSocket.on "connection", (socket) ->
		socket.on "map_position_changed", (pos) ->
			socket.broadcast.emit "plane_position_changed",
				client_id: socket.id
				position: pos
