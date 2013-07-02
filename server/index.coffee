###
	Module dependencies.
###

config = require "./config"
express = require "express"
path = require "path"
routes = require "./routes"
fs = require 'fs'

app = express()


###
	Configuration
###

app.configure "development", "testing", "production", ->
	config.setEnv app.settings.env

app.set "views", config.VIEWS_PATH
app.set "view engine", config.VIEWS_ENGINE
app.set "public_path", path.join __dirname, '..', config.PUBLIC_PATH
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.favicon("#{app.get('public_path')}/#{config.IMAGES_PATH}/favicon.ico")
app.use express["static"] app.get("public_path")

###
	Routes config
###

pushAsset = (asset, res) ->
	try
		res.push asset.uri, asset.headers, (err, stream) ->
			return if err?
			stream.on 'error', (error) ->
				console.error "SPDY stream error while pushing: #{asset.uri}", error
			fs.createReadStream(asset.file).pipe stream
				
	catch error
		console.error "Error while pushing asset: #{asset}. Error: ", error

pushTemplate = (templateName, res) ->
	try
		res.push '/partials/map'
		,
			'Content-type': 'text/html'
		,
		(err, stream) ->
			return if err?
			stream.on 'error', (error) ->
				console.error "SPDY stream error while pushing template: #{templateName}", error

			templateFile = templateName + '.jade'
			fs.readFile app.get('views') + templateFile, (err, data) ->
				if err?
					console.error "Error while pushing template: #{templateName}. Error: ", err
					return

				templateFunc = require('jade').compile(data)
				stream.end templateFunc(locals = {})
	catch error
		console.error "Error while pushing template: #{templateName}. Error: ", error

# Views
app.get "/", (req, res) ->
	if res.isSpdy and res.push?
		pushAsset asset, res for asset in config.assets
		pushTemplate '/partials/map', res
	routes.index(req, res)

app.get "/partials/:name", routes.partials

###
	Server startup
###

spdy = require 'spdy'
server = spdy.createServer(
	require('http').Server
	,
		plain: true
	,
	app
)
server.listen 8080
io = require("socket.io").listen server
require("./socket").configure io

###
	Export app
###
module.exports = server
