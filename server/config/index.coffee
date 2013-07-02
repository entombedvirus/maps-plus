path = require 'path'
exports.setEnv = (environment) ->

	###
	  Common config
	###
	exports.HOSTNAME = "0.0.0.0"
	exports.PORT = 8080
	exports.PUBLIC_PATH = "public"
	exports.VIEWS_ENGINE = "jade"
	exports.VIEWS_PATH = "server/views"
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
		filename = __dirname + "/../../public/#{cssFile}"
		assets.push
			uri: cssFile
			headers:
				'Content-type': 'text/css'
			file: path.resolve filename

	for jsFile in jsFiles
		filename = __dirname + "/../../public/#{jsFile}"
		assets.push
			uri: jsFile
			headers:
				'Content-type': 'application/javascript'
			file: path.resolve filename

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
