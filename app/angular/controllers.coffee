"use strict"

###
	Controllers
###

app = angular.module('NetTalk.controllers')

app.controller 'AppCtrl', (Animation) ->
	Animation.start()

app.controller 'UserControlsCtrl', ($scope, $timeout, $window, Socket) ->
	curX = 0
	curY = 0
	curAngle = 0
	arrow = angular.element document.getElementById('arrow')
	arrowX = arrow.offset().left
	arrowY = arrow.offset().top
	centerX = arrowX + (arrow.width() / 2)
	centerY = arrowY +  (arrow.height() / 2)
	
	$scope.onUserTouchMove = (e) ->
		e = e.touches?[0] ? e
		curX = e.originalEvent.pageX
		curY = e.originalEvent.pageY

	#animateArrow = ->
		#$window.requestAnimationFrame animateArrow
		#curAngle = Math.atan2(curY - centerY, curX - centerX)
		#arrow.css
			#transform: "rotate(#{curAngle}rad)"
	animateArrow = ->
		newAngle = Math.atan2(curY - centerY, curX - centerX)
		tween = new TWEEN.Tween({angle: curAngle}).to({angle: newAngle}, 100)
		tween.onUpdate ->
			arrow.css
				transform: "rotate(#{@angle}rad)"
		tween.onComplete ->
			curAngle = newAngle
			animateArrow()
		tween.start()

	animateArrow()

	broadcastUserState = ->
		ctrlData =
			angle: curAngle
		Socket.ctrl.emit 'user_ctrl', ctrlData
		console.log "broadcasting state", ctrlData
		$timeout broadcastUserState, 1000
	broadcastUserState()


app.controller 'SocketCtrl', ($scope, Socket) ->
	$scope.response = "waiting..."
	Socket.chat.on "pong", (data) ->
		console.log "got pong msg", data
		$scope.response = data.data

	$scope.ping = ->
		Socket.chat.emit("ping", {})

app.controller 'MapCtrl', ($scope, $timeout, $window, Socket) ->
	SPEED = 40
	currentHeading = 0 # Due North
	peerDisconnected = true

	onSyncUI = (ctrlData) ->
		angle = ctrlData.angle
		currentHeading = (angle * 180/Math.PI) + 90
		if peerDisconnected is true
			peerDisconnected = false
			updateMap()
	
	updateMap = ->
		curCenter = $scope.map.getCenter()
		return unless curCenter?
		$window.requestAnimationFrame updateMap unless peerDisconnected
		newCenter = google.maps.geometry.spherical.computeOffset curCenter, SPEED, currentHeading
		$scope.map.panTo newCenter

	onPeerDisconnected = (data) ->
		peerDisconnected = true

	Socket.ctrl.on 'sync_ui', onSyncUI
	Socket.ctrl.on 'peer_disconnected', onPeerDisconnected

