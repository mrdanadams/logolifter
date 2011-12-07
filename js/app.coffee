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

			# TODO put in the current image while the other is loading
			$('.image-result a').draggable({
				helper: ->
					# creates an image that is the full image to be dragged so it's more representative
					img = new Image()
					img.src = $('img', this).data('src')
					img

				opacity: .6
				
			})

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
			canvas = $('#canvas')
			ctx = canvas.get(0).getContext('2d')

			# TODO pulse the canvas border opacity while you are dragging
			inst = this
			canvas.droppable({
				accept: '.image-result a'
				activeClass: 'drop-highlight'
				drop: (event, ui) ->
					imgPos = ui.position
					canvasPos = $('#canvas').position()
					x = imgPos.left - canvasPos.left
					y = imgPos.top - canvasPos.top
					src = $(event.target).attr('src')

					inst.addImage src, x, y
			})

		# TODO maintain a model that gets redrawn
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
			# TODO only search if it's different than the last search and not empty
			APP.Search.search $(this).val()

		#
		# hide the help
	)
)
