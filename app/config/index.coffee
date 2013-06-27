exports.setEnv = (environment) ->

	###
	  Common config
	###
	exports.HOSTNAME = "0.0.0.0"
	exports.PORT = 8080
	exports.PUBLIC_PATH = "public"
	exports.VIEWS_ENGINE = "jade"
	exports.VIEWS_PATH = "views"
	exports.IMAGES_PATH = "images"

	fs = require 'fs'

	cssFiles = [
		'/lib/bootstrap/css/bootstrap.css',
		'/lib/bootstrap/css/bootstrap-responsive.css',
		'/styles/style.css'
	]
	jsFiles = [
		'/lib/jquery/jquery.js',
		'/lib/angular/angular-resource.js',
		'/lib/socket.io/socket.io.js',
		'/lib/polyfills/requestAnimationFrame.js',
		'/lib/angular/angular.js',
		'/lib/tweenjs/src/Tween.js',
		'/angular/services.js',
		'/angular/controllers.js',
		'/angular/app.js',
		'/angular/filters.js',
		'/angular/directives.js'
	]

	exports.assets = assets = []

	for cssFile in cssFiles
		assets.push
			uri: cssFile
			headers:
				'Content-type': 'text/css'
			contents: fs.readFileSync __dirname + "/../../public/#{cssFile}"

	for jsFile in jsFiles
		assets.push
			uri: jsFile
			headers:
				'Content-type': 'application/javascript'
			contents: fs.readFileSync __dirname + "/../../public/#{jsFile}"

	###
	Environment specific config
	###
	switch environment
		when "development"
			null

		when "testing"
			null

		when "production"
			null

		else
			console.log "Unknown environment #{environment}!"
