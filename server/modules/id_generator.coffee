class IdGenerator
	constructor: ->
		offset = Math.random() * Math.pow(BASE, STRING_LENGTH)
		# >> 0 get rid of the fractional part
		@counter = offset >> 0

	next: ->
		convertToBase @counter++


STRING_LENGTH = 4
BASE = 26

convertToBase = (number) ->
	str = []
	until number is 0
		str.unshift String.fromCharCode((number % BASE) + 97)
		# >> 0 get rid of the fractional part
		number = (number / BASE) >> 0
	str.unshift 'a' until str.length >= STRING_LENGTH
	str[0...STRING_LENGTH].join ''

module.exports = new IdGenerator()
