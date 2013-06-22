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

	chatSocket = io.of('/chat')
	chatSocket.on "connection", (socket) ->
		console.log "New socket connected!"
		socket.on "ping", ->
			time = new Date()
			socket.emit "pong", {data: "pong! Time is #{time.toString()}"}

	mapSocket = io.of('/map')
	mapSocket.on "connection", (socket) ->
		for client_id, client of mapSocket.sockets
			continue if client is socket

			do (client_id) ->
				client.get 'viewport', (err, peerViewport) ->
					console.log "checking peer", client_id, peerViewport
					return if err || !peerViewport?
					socket.emit('viewport_broadcast',
						viewport: peerViewport
						client_id: client_id
					)
					console.log "broadcasting #{client_id} to new connection"

		socket.on "viewport_changed", (viewport) ->
			console.log "got new position from client", socket.id, viewport
			socket.set 'viewport', viewport
			socket.broadcast.emit 'viewport_broadcast',
				viewport: viewport
				client_id: socket.id

		socket.on "disconnect", ->
			console.log "client disconnected", socket.id
			socket.broadcast.emit 'peer_disconnected',
				client_id: socket.id

