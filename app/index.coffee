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

# Views
app.get "/", routes.index
app.get "/partials/:name", routes.partials

###
	Server startup
###
server = app.listen 8080
io = require("socket.io").listen server
require("./socket").configure io

###
	Export app
###
module.exports = server
