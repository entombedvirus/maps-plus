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

app.set "ipaddr", config.HOSTNAME
app.set "port", config.PORT
app.set "views", path.join __dirname, '..', config.VIEWS_PATH
app.set "view engine", config.VIEWS_ENGINE
app.set "public_path", path.join __dirname, '..', config.PUBLIC_PATH
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.favicon("#{app.get('public_path')}/#{config.IMAGES_PATH}/favicon.ico")
console.log "static path", app.get("public_path")
app.use express["static"] app.get("public_path")

###
	Routes config
###

# Views
app.get "/", routes.index
app.get "/partials/:name", routes.partials

# Services
users = require "./services/users"
app.get "/users", users.list
app.get "/users/:id", users.get

###
	Server startup
###

serverStarted = ->
	console.log "Server listening on http://#{app.get "ipaddr"}:#{app.get "port"}"

start = ->
	console.log "Process PID: ", process.pid
	server = app.listen app.get('port'), app.get('ipaddr'), serverStarted

	###
		Socket.IO registration and configuration
	###
	io = require("socket.io").listen server
	require("./socket").configure io
	server

if require.main is module
	start()



###
	Export app
###

module.exports =
	app: app
	start: start

