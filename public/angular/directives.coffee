"use strict"

###
	Directives
###

app = angular.module("NetTalk.directives", ["ngResource"])

app.directive "appVersion", ["version", (version) ->
	(scope, elm, attrs) ->
		elm.text version
]

app.directive "googleMap", ->
	DEFAULT_ZOOM_LEVEL = 15
	GoogleMaps = google.maps
	GoogleMaps.visualRefresh = true

	{
		restrict: 'E',
		controller: ($scope, $element, $attrs, $q) ->
			mapLoad = $q.defer()

			@setMap = (map) ->
				@map = map
				mapLoad.resolve map

			@getMapPromise = ->
				mapLoad.promise

		compile: (elem, attrs, transclude) ->
			div = angular.element('<div id="mapView"/>')
			div.css({display: 'block'})
			#elem.replaceWith div
			elem.append div

			(scope, elem, attrs, controller) ->
				parts = attrs.center?.split ','
				if parts?
					lat = parseFloat(parts[0])
					lng = parseFloat(parts[1])
				else
					lat = 37.75549928195783
					lng = -122.45375823974608
				scope[attrs.name] = map = new GoogleMaps.Map(
					div[0]
				,
					center: new GoogleMaps.LatLng lat, lng
					zoom: (attrs.zoom? && parseInt attrs.zoom) || DEFAULT_ZOOM_LEVEL
					mapTypeId: GoogleMaps.MapTypeId.ROADMAP
					draggable: false
					disableDefaultUI: true
				)

				controller.setMap map
				scope.$eval attrs.onload

	}

app.directive "aircraft", ($log) ->
	{
		restrict: 'E',
		require: '^googleMap'
		scope:
			code: '@'
			lat: '@'
			lng: '@'
			heading: '@'
		compile: ->
			markers = {}

			(scope, elem, attrs, googleMapCtrl) ->
				attrs.$observe 'code', ->
					markers[scope.code] ?= new google.maps.Marker
						icon: 'images/F15-Strike-Eagle-48px.png'
					marker = markers[scope.code]
					mapPromise = googleMapCtrl.getMapPromise()
					mapPromise.then (map) ->
						marker.setMap map
				updatePosition = ->
					return unless scope.lat? and scope.lng? and scope.code?
					marker = markers[scope.code]
					marker?.setPosition new google.maps.LatLng scope.lat, scope.lng
				attrs.$observe 'lng', updatePosition
				attrs.$observe 'lat', updatePosition
				attrs.$observe 'heading', updatePosition
	}

app.directive "googleAnalytics", ->

	{
		restrict: "E",
		replace: true
		compile: (elem, attrs) ->
			script = angular.element """
				<script>
				(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
				(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
				m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
				})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

				ga('create', '#{attrs.id}', 'sentientagent.com');
				ga('send', 'pageview');

				</script>
			"""
			elem.replaceWith script
			script
	}

app.directive 'rotateControls', ($log, $document) ->
	{
		restrict: 'E',
		scope: {
			width: '@'
			height: '@',
			src: '@',
			value: '='
		},
		template: '<img ng-src="{{src}}" alt="" width="{{width}}" height="{{height}}"/>',
		link: (scope, elem, attrs) ->
			parentNode = elem.parent()
			curX = 0
			curY = 0
			centerX = 0
			centerY = 0
			newAngle = 0
			arrow = elem.find('img')

			do calculateCenter = ->
				arrowX = elem.offset().left
				arrowY = elem.offset().top
				centerX = arrowX + (elem.width() / 2)
				centerY = arrowY +  (elem.height() / 2)

			parentNode.on 'touchmove mousemove', (e) ->
				e.preventDefault()
				e = e.touches?[0] ? e
				curX = e.originalEvent.pageX
				curY = e.originalEvent.pageY
				scope.value = newAngle = Math.atan2(curY - centerY, curX - centerX) + Math.PI/2
				arrow.css
					transform: "rotate(#{newAngle}rad)"

			$document.on 'orientationchange', (e) ->
				$log.info "orientationchange event fired"
				calculateCenter()
	}