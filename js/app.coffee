this.APP = APP = {}

APP.Search = (->
	imageSearch = null
	imageTemplate = null
	

	obj = {
		init: ->
			imageSearch = new google.search.ImageSearch()
			imageSearch.setSearchCompleteCallback this, this.handleResults, null
			imageTemplate = Handlebars.compile $('#image-template').html()

		handleResults: ->
			# todo: handle no results
#			for result in imageSearch.results
#				$('#image-results .images').append result.html.cloneNode(true)
			$('#image-results .images').empty().append imageTemplate(imageSearch.results)

			#console.log imageSearch.results
			# todo: only do this once
			google.search.Search.getBranding 'google-branding'

		search: (q) ->
			imageSearch.execute q
			
	}

	google.load 'search', '1'
	google.setOnLoadCallback -> obj.init()

	obj
)()

APP.Canvas = (->
	ctx = null

	obj = {
		init: ->
			ctx = $('#canvas').get(0).getContext('2d')
			this.addImage 'http://t2.gstatic.com/images?q=tbn:ANd9GcSSRIcB7epzREylpl1gQ6ZYo9Vw8iJA-DH9PrDYh5_8QrbwfNLDEZM-og', 10, 10
			

		addImage: (src, x, y) ->
			img = new Image()
			img.onload = ->
				ctx.drawImage img, x, y

			img.src = src
	}

	$(-> obj.init())
	obj
)()


$(->
	$('#search-form form').submit((event) -> false)
	$('#q').on('keydown', (event) ->
		if (event.keyCode == 13)
			APP.Search.search $(this).val()

		#
		# hide the help
	)
)
