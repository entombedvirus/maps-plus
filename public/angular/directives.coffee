"use strict"

###
  Directives
###

app = angular.module("NetTalk.directives", ["ngResource"])

app.directive "appVersion", ["version", (version) ->
  (scope, elm, attrs) ->
    elm.text version
]

app.directive "googleMaps", ->
	DEFAULT_ZOOM_LEVEL = 15
	GoogleMaps = google.maps
	GoogleMaps.visualRefresh = true

	{
		restrict: 'E',
		#replace: true,
		compile: (elem, attrs, transclude) ->
			div = angular.element('<div id="mapView"/>')
			div.css({display: 'block'})
			#elem.replaceWith div
			elem.append div

			(scope, elem, attrs) ->
				parts = attrs.center?.split ','
				if parts?
					lat = parseFloat(parts[0])
					lng = parseFloat(parts[1])
				else
					lat = 37.75549928195783
					lng = -122.45375823974608
				map = scope[attrs.name]  = new GoogleMaps.Map(
					div[0]
				,
					center: new GoogleMaps.LatLng lat, lng
					zoom: (attrs.zoom? && parseInt attrs.zoom) || DEFAULT_ZOOM_LEVEL
					mapTypeId: GoogleMaps.MapTypeId.ROADMAP
					draggable: false
					disableDefaultUI: true
				)

				scope.$eval attrs.onload
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

app.directive 'rotate', ($log, $document) ->
	{
		restrict: 'A',
		compile: ->
			$log.info 'rotate COMPILE TIME'
			(scope, elem, attrs) ->
				parentNode = elem.parent()
				curX = curY = 0
				arrowTween = null
				centerX = centerY = 0
				arrowRotation = 0

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
					animateArrow()

				$document.on 'orientationchange', (e) ->
					console.log "orientationchange event fired"
					calculateCenter()

				animateArrow = ->
					arrowTween?.stop()
					newAngle = Math.atan2(curY - centerY, curX - centerX) + Math.PI/2
					# ensure a smooth animation when the angles wrap around
					diff = Math.abs(newAngle - arrowRotation)
					if diff > Math.PI
						if newAngle > 0
							arrowRotation += 2 * Math.PI
						else
							arrowRotation += -2 * Math.PI
					arrowTween = new TWEEN.Tween({angle: arrowRotation}).to({angle: newAngle}, 25)
					arrowTween.onUpdate ->
						arrowRotation = @angle
						scope.$emit 'rotate_angle_changed', @angle
						elem.css
							transform: "rotate(#{@angle}rad)"
					arrowTween.start()


	}