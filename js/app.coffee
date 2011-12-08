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
			$('#image-results .images').empty().append imageTemplate(imageSearch.results)

			# TODO put in the current image while the other is loading
			# TODO move out to a UI class
			$('.image-result a').draggable({
				helper: ->
					# creates an image that is the full image to be dragged so it's more representative
					img = new Image()
					img.src = $('img', this).data('src')
					img


				opacity: .6
				
			})

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
			# TODO move out to a UI object
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

		download: ->
			Canvas2Image.saveAsPNG $('#canvas').get(0)
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

	$('#download').click(-> APP.Canvas.download() )

	# seeing if this works...
	$.getImageData {
		url: "http://www.maths.nott.ac.uk/personal/sc/images/SteveC.jpg"
		success: (image) ->
			APP.Canvas.addImage image.src, 10, 10
		
		error: (xhr, text_status) ->
	}
)
