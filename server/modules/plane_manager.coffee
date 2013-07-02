module.exports =  class PlaneManager
	DEFAULT_SPEED = 400
	PRESET_POSITIONS =
		goldenGatePark: [37.76847577247013, -122.49210834503174]
		crissyField: [37.80542699570327, -122.46883749961853]
		sfo: [37.61967039695652, -122.37112998962402]
	
	constructor: (idGenerator) ->
		@planes = {}
		for name, pos of PRESET_POSITIONS
			code = idGenerator.next()
			@planes[code] =
				code: code
				position: pos
				speed: DEFAULT_SPEED
				heading: 0 # due north

	findByCode: (code) ->
		@planes[code]

	getDataForBroadcast: ->
		@planes

	acquireControl: (code, client_id) ->
		return false unless @planes[code]
		if @planes[code].controllingClient?
			return false
		else
			@planes[code].controllingClient = client_id
			return true

	releaseControl: (code) ->
		plane = @planes[code]
		return unless plane?
		delete plane.controllingClient

	updatePosition: (code, position) ->
		plane = @planes[code]
		return unless plane?
		plane.position = position


idGenerator = require('../modules/id_generator')
module.exports = new PlaneManager(idGenerator)
