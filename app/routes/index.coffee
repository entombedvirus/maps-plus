
###
	GET home page
###

isMobileDevice = (req) ->
	/mobile/i.test req.header('user-agent')

exports.index = (request, response) ->
	if isMobileDevice request
		response.render "index_mobile"
	else
		response.render "index_pc"

###
	GET partial templates
###

exports.partials = (request, response) ->
	response.render "partials/" + request.params.name

