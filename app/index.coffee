###
	Module dependencies.
###

config = require "./config"
express = require "express"
path = require "path"
routes = require "./routes"

app = express()


###
	Configuration
###

app.configure "development", "testing", "production", ->
	config.setEnv app.settings.env

app.set "views", path.join __dirname, '..', config.VIEWS_PATH
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
			stream.end asset.contents
	catch error
		# do nothing

# Views
app.get "/", (req, res) ->
	if res.isSpdy and res.push?
		pushAsset asset, res for asset in config.assets
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
